import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { setGlobalOptions } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Configure global options for V2 functions
setGlobalOptions({
  maxInstances: 10,
  region: "us-central1",
  memory: "256MiB",
  timeoutSeconds: 60,
});

admin.initializeApp();
const db = admin.firestore();

// Cache for time parsing to avoid repeated calculations
const timeCache = new Map<string, Date>();

// Constants for performance optimization
const CLOSE_TO_BREAK_MINUTES = 5;
const URGENT_MATCHING_MINUTES = 15;
const RECENT_MATCH_HOURS = 24;
const FIRESTORE_IN_LIMIT = 10; // Firestore 'in' query limit

/**
 * V2 Firebase Function: Called when a user joins the queue for side table matching.
 * Now supports gender-based matching preferences with proper 1-1 matching.
 */
export const onUserJoinQueue = onDocumentCreated(
  {
    document: "matchingQueue/{docId}",
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 30,
    maxInstances: 5,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.error("❌ No document data found in event.");
      return;
    }

    const newUserData = snap.data();
    const userId = newUserData.userId;
    const timeSlot = newUserData.timeSlot;
    const matchPreference = newUserData.matchPreference || 'any';

    if (!userId || !timeSlot) {
      logger.error("❌ Missing required fields: userId or timeSlot");
      return;
    }

    logger.info(`🍽️ Student ${userId} joined queue for ${timeSlot} with preference: ${matchPreference}`);

    try {
      // Add small random delay to reduce concurrent processing
      await new Promise(resolve => setTimeout(resolve, Math.random() * 1000));
      await processSideTableMatching(timeSlot);
    } catch (error) {
      logger.error(`❌ Error in matching for ${timeSlot}: ${error}`);
      // Don't throw to prevent function retries on temporary failures
    }
  }
);

/**
 * Optimized matching processor with proper 1-1 matching and race condition prevention.
 */
async function processSideTableMatching(timeSlot: string): Promise<void> {
  // Early exit for closed time slots
  if (isTooCloseToBreak(timeSlot)) {
    logger.info(`⏰ Too close to ${timeSlot}. Stopping new matches.`);
    return;
  }

  try {
    // Use transaction to ensure atomic matching process
    await db.runTransaction(async (transaction) => {
      // Get waiting users within transaction for consistency
      const waitingUsersSnapshot = await transaction.get(
        db.collection("matchingQueue")
          .where("timeSlot", "==", timeSlot)
          .where("status", "==", "waiting")
          .orderBy("createdAt", "asc")
          .limit(50)
      );

      const waitingUsers = waitingUsersSnapshot.docs;

      if (waitingUsers.length < 2) {
        logger.info(`⏳ Only ${waitingUsers.length} student(s) waiting for ${timeSlot}`);
        return;
      }

      logger.info(`👥 Found ${waitingUsers.length} students for ${timeSlot}`);

      // Get currently active matches to avoid conflicts
      const userIds = waitingUsers.map(doc => doc.data().userId);
      const activeMatchesSnapshot = await transaction.get(
        db.collection("matches")
          .where("users", "array-contains-any", userIds)
          .where("status", "==", "active")
      );

      // Build set of users who already have active matches
      const usersWithActiveMatches = new Set<string>();
      activeMatchesSnapshot.docs.forEach(doc => {
        const users = doc.data().users as string[];
        users.forEach(userId => {
          if (userIds.includes(userId)) {
            usersWithActiveMatches.add(userId);
          }
        });
      });

      // Filter out users who already have matches
      const availableUsers = waitingUsers.filter(user => {
        const userId = user.data().userId;
        return !usersWithActiveMatches.has(userId);
      });

      if (availableUsers.length < 2) {
        logger.info(`🚫 Only ${availableUsers.length} users available after filtering active matches`);
        return;
      }

      const shouldForceMatch = isUrgentMatching(timeSlot) || availableUsers.length === 2;

      // Find best pair with proper availability checking
      const bestPair = await findBestPairWithinTransaction(
        transaction, 
        availableUsers, 
        shouldForceMatch
      );

      if (bestPair.length === 2) {
        await createMatchWithinTransaction(transaction, bestPair, timeSlot);
      } else {
        logger.info("🤔 No suitable match found after filtering");
      }
    });

  } catch (error) {
    logger.error(`❌ Error in processSideTableMatching: ${error}`);
    throw error;
  }
}

/**
 * Find best pair within transaction context to ensure data consistency.
 */
async function findBestPairWithinTransaction(
  transaction: admin.firestore.Transaction,
  availableUsers: admin.firestore.QueryDocumentSnapshot[],
  forceMatch: boolean
): Promise<admin.firestore.QueryDocumentSnapshot[]> {
  
  if (availableUsers.length < 2) return [];

  // Get user profiles for gender compatibility checking
  const userIds = availableUsers.map(user => user.data().userId);
  const userProfilesMap = await getUserProfiles(userIds);

  // For exactly 2 users, check compatibility and return if compatible
  if (availableUsers.length === 2) {
    const [user1, user2] = availableUsers;
    const userId1 = user1.data().userId;
    const userId2 = user2.data().userId;
    
    // Check gender compatibility
    const user1Profile = userProfilesMap.get(userId1);
    const user2Profile = userProfilesMap.get(userId2);
    
    if (!areUsersCompatible(user1.data(), user2.data(), user1Profile, user2Profile)) {
      logger.info(`🚫 Users ${userId1} & ${userId2} not compatible based on gender preferences`);
      return [];
    }
    
    logger.info("🚀 Only 2 available students and they're compatible - matching them now!");
    return availableUsers;
  }

  // For more than 2 users, find optimal pair
  return await findOptimalPairFromAvailable(availableUsers, userProfilesMap, forceMatch);
}

/**
 * Find optimal pair from available users with proper scoring.
 */
async function findOptimalPairFromAvailable(
  availableUsers: admin.firestore.QueryDocumentSnapshot[],
  userProfilesMap: Map<string, any>,
  forceMatch: boolean
): Promise<admin.firestore.QueryDocumentSnapshot[]> {
  
  let bestPair: admin.firestore.QueryDocumentSnapshot[] = [];
  let bestScore = -1;

  // Get recent matches data if needed (only if not forcing match)
  const recentMatchesMap = forceMatch ? new Map() : await getRecentMatchesMap(
    availableUsers.map(u => u.data().userId)
  );

  // Find best pair with gender compatibility
  for (let i = 0; i < availableUsers.length - 1; i++) {
    for (let j = i + 1; j < availableUsers.length; j++) {
      const user1 = availableUsers[i];
      const user2 = availableUsers[j];
      const userId1 = user1.data().userId;
      const userId2 = user2.data().userId;

      // Check gender compatibility
      const user1Profile = userProfilesMap.get(userId1);
      const user2Profile = userProfilesMap.get(userId2);
      
      if (!areUsersCompatible(user1.data(), user2.data(), user1Profile, user2Profile)) {
        continue; // Skip incompatible pairs
      }

      let score = 100;

      // Recent match penalty (only if not forcing)
      if (!forceMatch && recentMatchesMap.get(userId1)?.has(userId2)) {
        score -= 80;
      }

      // Wait time bonus
      const joinTime1 = user1.data().createdAt?.seconds || 0;
      const joinTime2 = user2.data().createdAt?.seconds || 0;
      const avgWaitTime = (Date.now() / 1000 - (joinTime1 + joinTime2) / 2) / 60;
      score += Math.min(avgWaitTime * 2, 40);

      // Gender preference bonus
      const user1Preference = user1.data().matchPreference || 'any';
      const user2Preference = user2.data().matchPreference || 'any';
      const user1Gender = user1Profile?.gender;
      const user2Gender = user2Profile?.gender;
      
      if (user1Preference === 'same_gender' && user2Preference === 'same_gender' && 
          user1Gender === user2Gender) {
        score += 20;
      }

      // Small randomization for tie-breaking
      score += Math.random() * 5;

      if (score > bestScore) {
        bestScore = score;
        bestPair = [user1, user2];
      }
    }
  }

  if (bestPair.length === 2) {
    const userId1 = bestPair[0].data().userId;
    const userId2 = bestPair[1].data().userId;
    const user1Preference = bestPair[0].data().matchPreference || 'any';
    const user2Preference = bestPair[1].data().matchPreference || 'any';
    logger.info(`🎯 Optimal match: ${userId1} & ${userId2} (score: ${bestScore.toFixed(1)}, prefs: ${user1Preference}/${user2Preference})`);
  }

  return bestPair;
}

/**
 * Create match within existing transaction to ensure atomicity.
 */
async function createMatchWithinTransaction(
  transaction: admin.firestore.Transaction,
  matchedUsers: admin.firestore.QueryDocumentSnapshot[],
  timeSlot: string
): Promise<void> {
  
  const user1Data = matchedUsers[0].data();
  const user2Data = matchedUsers[1].data();
  const userId1 = user1Data.userId;
  const userId2 = user2Data.userId;

  const matchId = `match_${userId1}_${userId2}_${Date.now()}`;
  const today = new Date().toISOString().split("T")[0];

  logger.info(`🤝 Creating match within transaction: ${userId1} & ${userId2} for ${timeSlot}`);

  // Double-check that neither user has an active match (final safety check)
  const finalConflictCheck = await transaction.get(
    db.collection("matches")
      .where("users", "array-contains-any", [userId1, userId2])
      .where("status", "==", "active")
  );

  if (!finalConflictCheck.empty) {
    logger.warn(`⚠️ Final conflict check failed: one of ${userId1} or ${userId2} already has active match`);
    return;
  }

  // Create match document
  const matchRef = db.collection("matches").doc();
  const matchData = {
    users: [userId1, userId2],
    timeSlot,
    matchId,
    status: "active",
    matchType: "side_table",  
    matchDate: today,
    matchedAt: admin.firestore.FieldValue.serverTimestamp(),
    breakTime: timeSlot,
    meetupLocation: "Main Canteen",
    matchPreferences: {
      [userId1]: user1Data.matchPreference || 'any',
      [userId2]: user2Data.matchPreference || 'any'
    },
    _createdBy: "optimized_matcher_v2_fixed",
    _version: "2.2"
  };

  transaction.set(matchRef, matchData);

  // Update ONLY the matched users' queue entries
  const user1QueueDoc = matchedUsers[0];
  const user2QueueDoc = matchedUsers[1];

  transaction.update(user1QueueDoc.ref, {
    status: "matched",
    matchedWith: userId2,
    matchId,
    matchedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  transaction.update(user2QueueDoc.ref, {
    status: "matched", 
    matchedWith: userId1,
    matchId,
    matchedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(
    `✅ Match created in transaction: ${userId1} & ${userId2} for ${timeSlot}. Preferences: ${user1Data.matchPreference || 'any'}/${user2Data.matchPreference || 'any'}`
  );
}

/**
 * Get user profile data including gender information.
 */
async function getUserProfiles(userIds: string[]): Promise<Map<string, any>> {
  const profilesMap = new Map<string, any>();
  
  if (userIds.length === 0) return profilesMap;

  try {
    // Process in batches to handle Firestore's 'in' query limit
    const batches = [];
    for (let i = 0; i < userIds.length; i += FIRESTORE_IN_LIMIT) {
      batches.push(userIds.slice(i, i + FIRESTORE_IN_LIMIT));
    }

    // Execute all batch queries in parallel
    const batchPromises = batches.map(batch =>
      db.collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", batch)
        .get()
    );

    const batchResults = await Promise.all(batchPromises);

    // Process results efficiently
    for (const snapshot of batchResults) {
      for (const doc of snapshot.docs) {
        profilesMap.set(doc.id, doc.data());
      }
    }

    logger.info(`👤 Retrieved profiles for ${profilesMap.size}/${userIds.length} users`);
    return profilesMap;

  } catch (error) {
    logger.error(`❌ Error getting user profiles: ${error}`);
    return profilesMap;
  }
}

/**
 * Check if two users are compatible based on gender preferences.
 */
function areUsersCompatible(
  user1Data: any, 
  user2Data: any, 
  user1Profile: any, 
  user2Profile: any
): boolean {
  const user1Preference = user1Data.matchPreference || 'any';
  const user2Preference = user2Data.matchPreference || 'any';
  
  const user1Gender = user1Profile?.gender;
  const user2Gender = user2Profile?.gender;

  // If either user doesn't have gender info, skip gender-based filtering
  if (!user1Gender || !user2Gender) {
    logger.warn(`⚠️ Missing gender info for users ${user1Data.userId} or ${user2Data.userId}`);
    return true;
  }

  // Check user1's preference
  if (user1Preference === 'same_gender' && user1Gender !== user2Gender) {
    return false;
  }

  // Check user2's preference  
  if (user2Preference === 'same_gender' && user1Gender !== user2Gender) {
    return false;
  }

  return true;
}

/**
 * Cached time parsing for performance optimization.
 */
function parseTimeSlot(timeSlot: string): Date {
  if (timeCache.has(timeSlot)) {
    const cached = timeCache.get(timeSlot)!;
    const now = new Date();
    const result = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 
                           cached.getHours(), cached.getMinutes(), 0, 0);
    if (result <= now) {
      result.setDate(result.getDate() + 1);
    }
    return result;
  }

  const [time, period] = timeSlot.split(" ");
  const [hours, minutes] = time.split(":").map(Number);

  let hour24 = hours;
  if (period === "PM" && hours !== 12) hour24 += 12;
  if (period === "AM" && hours === 12) hour24 = 0;

  const templateDate = new Date(2000, 0, 1, hour24, minutes, 0, 0);
  timeCache.set(timeSlot, templateDate);

  const now = new Date();
  const result = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hour24, minutes, 0, 0);
  if (result <= now) {
    result.setDate(result.getDate() + 1);
  }
  return result;
}

/**
 * Optimized time checking with cached calculations.
 */
function isTooCloseToBreak(timeSlot: string): boolean {
  const now = new Date();
  const breakTime = parseTimeSlot(timeSlot);
  const timeDiffMinutes = (breakTime.getTime() - now.getTime()) / (1000 * 60);
  return timeDiffMinutes <= CLOSE_TO_BREAK_MINUTES;
}

/**
 * Optimized urgent matching check.
 */
function isUrgentMatching(timeSlot: string): boolean {
  const now = new Date();
  const breakTime = parseTimeSlot(timeSlot);
  const timeDiffMinutes = (breakTime.getTime() - now.getTime()) / (1000 * 60);
  return timeDiffMinutes <= URGENT_MATCHING_MINUTES;
}

/**
 * Optimized recent matches retrieval.
 */
async function getRecentMatchesMap(userIds: string[]): Promise<Map<string, Set<string>>> {
  const recentMatchesMap = new Map<string, Set<string>>();
  
  if (userIds.length === 0) return recentMatchesMap;

  try {
    const cutoffTime = new Date();
    cutoffTime.setHours(cutoffTime.getHours() - RECENT_MATCH_HOURS);

    const batches = [];
    for (let i = 0; i < userIds.length; i += FIRESTORE_IN_LIMIT) {
      batches.push(userIds.slice(i, i + FIRESTORE_IN_LIMIT));
    }

    const batchPromises = batches.map(batch =>
      db.collection("matches")
        .where("users", "array-contains-any", batch)
        .where("matchedAt", ">=", admin.firestore.Timestamp.fromDate(cutoffTime))
        .where("status", "in", ["completed", "cancelled"])
        .get()
    );

    const batchResults = await Promise.all(batchPromises);

    for (const snapshot of batchResults) {
      for (const doc of snapshot.docs) {
        const users = doc.data().users as string[];
        const relevantUsers = users.filter(uid => userIds.includes(uid));
        
        for (const userId of relevantUsers) {
          if (!recentMatchesMap.has(userId)) {
            recentMatchesMap.set(userId, new Set<string>());
          }
          
          for (const otherUser of users) {
            if (otherUser !== userId) {
              recentMatchesMap.get(userId)!.add(otherUser);
            }
          }
        }
      }
    }

    return recentMatchesMap;
  } catch (error) {
    logger.error(`❌ Error getting recent matches: ${error}`);
    return recentMatchesMap;
  }
}

/**
 * V2 Firebase Function: Automatically close matches 30 minutes after their scheduled meeting time
 * Runs every minute to check for matches that should be closed
 */
export const autoCloseMatches = onSchedule(
  {
    schedule: "every 1 minutes",
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
    maxInstances: 5,
  },
  async (event) => {
    try {
      const now = new Date();
      logger.info(`🔍 Checking for matches that should be auto-closed...`);

      // Get all active matches
      const matchesSnapshot = await db.collection("matches")
        .where("status", "==", "active")
        .get();

      if (matchesSnapshot.empty) {
        logger.info(`✅ No active matches to check`);
        return;
      }

      const batch = db.batch();
      const closedMatches: Array<{matchId: string, users: string[], timeSlot: string}> = [];

      matchesSnapshot.forEach((doc) => {
        const matchData = doc.data();
        const timeSlot = matchData.timeSlot;
        
        if (!timeSlot) {
          logger.warn(`⚠️ Match ${doc.id} has no timeSlot, skipping`);
          return;
        }

        // Calculate the scheduled meeting time for today
        const meetingTime = parseTimeSlot(timeSlot);
        
        // Calculate closure time (30 minutes after meeting time)
        const closureTime = new Date(meetingTime.getTime() + (30 * 60 * 1000));
        
        // Check if it's time to close this match
        if (now >= closureTime) {
          logger.info(`⏰ Closing match ${doc.id} for timeSlot ${timeSlot} (meeting was at ${meetingTime.toLocaleTimeString()}, closing 30 mins later)`);
          
          // Update match status to 'completed'
          batch.update(doc.ref, {
            status: "completed",
            completedAt: admin.firestore.Timestamp.now(),
            autoClosedReason: "timeout_30_minutes_after_meeting",
            meetingTime: admin.firestore.Timestamp.fromDate(meetingTime),
            closureTime: admin.firestore.Timestamp.fromDate(closureTime)
          });

          closedMatches.push({
            matchId: doc.id,
            users: matchData.users || [],
            timeSlot: timeSlot
          });
        }
      });

      // Commit all updates
      if (closedMatches.length > 0) {
        await batch.commit();
        logger.info(`✅ Closed ${closedMatches.length} matches automatically`);
        
        // Log details for debugging
        closedMatches.forEach((match) => {
          logger.info(`📝 Closed match ${match.matchId} for users: ${match.users.join(", ")} at ${match.timeSlot}`);
        });
      } else {
        logger.info(`✅ No matches need to be closed at this time`);
      }

    } catch (error) {
      logger.error(`❌ Error in autoCloseMatches: ${error}`);
      throw error;
    }
  }
);

// Export feed algorithm functions
export * from './feedAlgorithm';

// Export analytics functions  
export * from './analytics';