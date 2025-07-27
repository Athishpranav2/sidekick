import { onDocumentCreated } from "firebase-functions/v2/firestore";
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
 * Optimized with batching, caching, and efficient data structures.
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

    if (!userId || !timeSlot) {
      logger.error("❌ Missing required fields: userId or timeSlot");
      return;
    }

    logger.info(`🍽️ Student ${userId} joined queue for ${timeSlot}`);

    try {
      await processSideTableMatching(timeSlot);
    } catch (error) {
      logger.error(`❌ Error in matching for ${timeSlot}: ${error}`);
      // Don't throw to prevent function retries on temporary failures
    }
  }
);

/**
 * Optimized matching processor with efficient data structures and algorithms.
 */
async function processSideTableMatching(timeSlot: string): Promise<void> {
  // Early exit for closed time slots
  if (isTooCloseToBreak(timeSlot)) {
    logger.info(`⏰ Too close to ${timeSlot}. Stopping new matches.`);
    return;
  }

  try {
    // Single optimized query with composite index
    const waitingUsersSnapshot = await db
      .collection("matchingQueue")
      .where("timeSlot", "==", timeSlot)
      .where("status", "==", "waiting")
      .orderBy("createdAt", "asc")
      .limit(50) // Limit to prevent excessive processing
      .get();

    const waitingUsers = waitingUsersSnapshot.docs;

    if (waitingUsers.length < 2) {
      logger.info(`⏳ Only ${waitingUsers.length} student(s) waiting for ${timeSlot}`);
      return;
    }

    logger.info(`👥 Found ${waitingUsers.length} students for ${timeSlot}`);

    // Use Set for O(1) lookups instead of array operations
    const userIds = new Set(waitingUsers.map(doc => doc.data().userId));
    const shouldForceMatch = isUrgentMatching(timeSlot) || waitingUsers.length === 2;

    // Optimized matching with efficient algorithms
    const bestPair = await findBestPairOptimized(waitingUsers, userIds, shouldForceMatch);

    if (bestPair.length === 2) {
      await createMatchWithTransaction(bestPair, timeSlot);
    } else {
      logger.info("🤔 No suitable match found after filtering");
    }
  } catch (error) {
    logger.error(`❌ Error in processSideTableMatching: ${error}`);
    throw error;
  }
}

/**
 * Cached time parsing for performance optimization.
 */
function parseTimeSlot(timeSlot: string): Date {
  // Check cache first for O(1) lookup
  if (timeCache.has(timeSlot)) {
    const cached = timeCache.get(timeSlot)!;
    // Return a new date based on today but with cached time
    const now = new Date();
    const result = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 
                           cached.getHours(), cached.getMinutes(), 0, 0);
    if (result <= now) {
      result.setDate(result.getDate() + 1);
    }
    return result;
  }

  // Parse and cache for future use
  const [time, period] = timeSlot.split(" ");
  const [hours, minutes] = time.split(":").map(Number);

  let hour24 = hours;
  if (period === "PM" && hours !== 12) hour24 += 12;
  if (period === "AM" && hours === 12) hour24 = 0;

  const templateDate = new Date(2000, 0, 1, hour24, minutes, 0, 0);
  timeCache.set(timeSlot, templateDate);

  // Return actual date for today
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
 * Highly optimized pair finding algorithm using efficient data structures.
 */
async function findBestPairOptimized(
  waitingUsers: admin.firestore.QueryDocumentSnapshot[],
  userIds: Set<string>,
  forceMatch: boolean
): Promise<admin.firestore.QueryDocumentSnapshot[]> {
  
  if (waitingUsers.length < 2) return [];

  // Get all active matches in one optimized query using array-contains-any
  const userIdsArray = Array.from(userIds);
  const activeMatchesMap = await getActiveMatchesMap(userIdsArray);
  
  // Filter available users using Set operations for O(1) lookups
  const availableUsers = waitingUsers.filter(user => {
    const userId = user.data().userId;
    return !activeMatchesMap.has(userId);
  });

  if (availableUsers.length < 2) {
    logger.info(`🚫 Only ${availableUsers.length} users available after filtering`);
    return [];
  }

  // Fast path for exactly 2 users
  if (availableUsers.length === 2) {
    const [user1, user2] = availableUsers;
    const userId1 = user1.data().userId;
    const userId2 = user2.data().userId;
    
    // Quick check using our active matches map
    if (activeMatchesMap.get(userId1)?.has(userId2)) {
      logger.info(`🚫 Users ${userId1} & ${userId2} already matched - skipping`);
      return [];
    }
    
    logger.info("🚀 Only 2 available students - matching them now!");
    return availableUsers;
  }

  // Optimized scoring algorithm for multiple users
  return await findOptimalPair(availableUsers, activeMatchesMap, forceMatch);
}

/**
 * Efficient active matches retrieval using optimized queries and data structures.
 */
async function getActiveMatchesMap(userIds: string[]): Promise<Map<string, Set<string>>> {
  const activeMatchesMap = new Map<string, Set<string>>();
  
  if (userIds.length === 0) return activeMatchesMap;

  try {
    // Process in batches to handle Firestore's 'in' query limit
    const batches = [];
    for (let i = 0; i < userIds.length; i += FIRESTORE_IN_LIMIT) {
      const batch = userIds.slice(i, i + FIRESTORE_IN_LIMIT);
      batches.push(batch);
    }

    // Execute all batch queries in parallel
    const batchPromises = batches.map(batch =>
      db.collection("matches")
        .where("users", "array-contains-any", batch)
        .where("status", "==", "active")
        .get()
    );

    const batchResults = await Promise.all(batchPromises);

    // Process results efficiently
    for (const snapshot of batchResults) {
      for (const doc of snapshot.docs) {
        const users = doc.data().users as string[];
        
        // Only process if users are in our current set
        const relevantUsers = users.filter(uid => userIds.includes(uid));
        
        for (const userId of relevantUsers) {
          if (!activeMatchesMap.has(userId)) {
            activeMatchesMap.set(userId, new Set<string>());
          }
          
          // Add all other users in this match as matched partners
          for (const otherUser of users) {
            if (otherUser !== userId) {
              activeMatchesMap.get(userId)!.add(otherUser);
            }
          }
        }
      }
    }

    logger.info(`📊 Processed active matches for ${userIds.length} users, found ${activeMatchesMap.size} with active matches`);
    return activeMatchesMap;

  } catch (error) {
    logger.error(`❌ Error getting active matches: ${error}`);
    return activeMatchesMap; // Return empty map on error
  }
}

/**
 * Optimized pair finding algorithm with efficient scoring.
 */
async function findOptimalPair(
  availableUsers: admin.firestore.QueryDocumentSnapshot[],
  activeMatchesMap: Map<string, Set<string>>,
  forceMatch: boolean
): Promise<admin.firestore.QueryDocumentSnapshot[]> {
  
  let bestPair: admin.firestore.QueryDocumentSnapshot[] = [];
  let bestScore = -1;

  // Get recent matches data if needed (only if not forcing match)
  const recentMatchesMap = forceMatch ? new Map() : await getRecentMatchesMap(
    availableUsers.map(u => u.data().userId)
  );

  // Optimized nested loop with early termination
  for (let i = 0; i < availableUsers.length - 1; i++) {
    for (let j = i + 1; j < availableUsers.length; j++) {
      const user1 = availableUsers[i];
      const user2 = availableUsers[j];
      const userId1 = user1.data().userId;
      const userId2 = user2.data().userId;

      // Skip if already matched (redundant check but fast)
      if (activeMatchesMap.get(userId1)?.has(userId2)) {
        continue;
      }

      let score = 100;

      // Recent match penalty (only if not forcing)
      if (!forceMatch && recentMatchesMap.get(userId1)?.has(userId2)) {
        score -= 80;
      }

      // Wait time bonus (optimized calculation)
      const joinTime1 = user1.data().createdAt?.seconds || 0;
      const joinTime2 = user2.data().createdAt?.seconds || 0;
      const avgWaitTime = (Date.now() / 1000 - (joinTime1 + joinTime2) / 2) / 60;
      score += Math.min(avgWaitTime * 2, 40);

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
    logger.info(`🎯 Optimal match: ${userId1} & ${userId2} (score: ${bestScore.toFixed(1)})`);
  }

  return bestPair;
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

    // Process in batches for recent matches
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
 * Atomic match creation using optimized Firestore transaction.
 */
async function createMatchWithTransaction(
  matchedUsers: admin.firestore.QueryDocumentSnapshot[],
  timeSlot: string
): Promise<void> {
  
  const user1Data = matchedUsers[0].data();
  const user2Data = matchedUsers[1].data();
  const userId1 = user1Data.userId;
  const userId2 = user2Data.userId;

  const matchId = `match_${userId1}_${userId2}_${Date.now()}`;
  const today = new Date().toISOString().split("T")[0];

  logger.info(`🤝 Creating atomic match: ${userId1} & ${userId2} for ${timeSlot}`);

  try {
    await db.runTransaction(async (transaction) => {
      // Create references
      const matchRef = db.collection("matches").doc();
      
      // Optimized: Get queue entries for both users in parallel
      const [user1QueueQuery, user2QueueQuery, conflictCheck] = await Promise.all([
        transaction.get(
          db.collection("matchingQueue")
            .where("userId", "==", userId1)
            .where("status", "==", "waiting")
        ),
        transaction.get(
          db.collection("matchingQueue")
            .where("userId", "==", userId2)
            .where("status", "==", "waiting")
        ),
        // Race condition check
        transaction.get(
          db.collection("matches")
            .where("users", "array-contains", userId1)
            .where("status", "==", "active")
        )
      ]);

      // Check for race conditions
      const hasConflict = conflictCheck.docs.some(doc => {
        const users = doc.data().users as string[];
        return users.includes(userId2);
      });

      if (hasConflict) {
        logger.warn(`⚠️ Transaction aborted: ${userId1} & ${userId2} already matched`);
        return;
      }

      // Batch update all queue entries
      const allQueueDocs = [...user1QueueQuery.docs, ...user2QueueQuery.docs];
      
      for (const doc of allQueueDocs) {
        const docUserId = doc.data().userId;
        transaction.update(doc.ref, {
          status: "matched",
          matchedWith: docUserId === userId1 ? userId2 : userId1,
          matchId,
          matchedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Create match document
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
        // Add metadata for future optimizations
        _createdBy: "optimized_matcher_v2",
        _version: "2.0"
      };

      transaction.set(matchRef, matchData);

      logger.info(
        `✅ Atomic match created: ${userId1} & ${userId2} for ${timeSlot}. Updated ${allQueueDocs.length} queue entries.`
      );
    });

  } catch (error) {
    logger.error(`❌ Transaction failed for match creation: ${error}`);
    throw error;
  }
}