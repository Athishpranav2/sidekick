import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();
const db = admin.firestore();

/**
 * Called when a user joins the queue for side table matching.
 */
export const onUserJoinQueue = onDocumentCreated(
  "matchingQueue/{docId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.error("❌ No document data found in event.");
      return;
    }

    const newUserData = snap.data();
    const userId = newUserData.userId;
    const timeSlot = newUserData.timeSlot;

    logger.info(`🍽️ Student ${userId} joined queue for ${timeSlot}`);

    try {
      await processSideTableMatching(timeSlot);
    } catch (error) {
      logger.error(`❌ Error in matching: ${error}`);
    }
  }
);

/**
 * Match users for the given time slot.
 */
async function processSideTableMatching(timeSlot: string) {
  if (isTooCloseToBreak(timeSlot)) {
    logger.info(`⏰ Too close to ${timeSlot}. Stopping new matches.`);
    return;
  }

  const waitingUsersSnapshot = await db
    .collection("matchingQueue")
    .where("timeSlot", "==", timeSlot)
    .where("status", "==", "waiting")
    .orderBy("createdAt", "asc")
    .get();

  const waitingUsers = waitingUsersSnapshot.docs;

  if (waitingUsers.length < 2) {
    logger.info(`⏳ Only ${waitingUsers.length} student waiting for ${timeSlot}`);
    return;
  }

  logger.info(`👥 Found ${waitingUsers.length} students for ${timeSlot}`);

  const shouldForceMatch =
    isUrgentMatching(timeSlot) || waitingUsers.length === 2;

  const bestPair = await findBestPair(waitingUsers, shouldForceMatch);

  if (bestPair.length === 2) {
    await createMatch(bestPair, timeSlot);
  } else {
    logger.info("🤔 No suitable match found");
  }
}

/**
 * Checks if the time slot is too close to the break.
 */
function isTooCloseToBreak(timeSlot: string): boolean {
  const now = new Date();
  const breakTime = parseTimeSlot(timeSlot);
  const timeDiff = (breakTime.getTime() - now.getTime()) / (1000 * 60);
  return timeDiff <= 5;
}

/**
 * Checks if it's urgent to match users before break.
 */
function isUrgentMatching(timeSlot: string): boolean {
  const now = new Date();
  const breakTime = parseTimeSlot(timeSlot);
  const timeDiff = (breakTime.getTime() - now.getTime()) / (1000 * 60);
  return timeDiff <= 15;
}

/**
 * Parses the timeSlot string and returns a Date object.
 */
function parseTimeSlot(timeSlot: string): Date {
  const now = new Date();
  const [time, period] = timeSlot.split(" ");
  const [hours, minutes] = time.split(":").map(Number);

  let hour24 = hours;
  if (period === "PM" && hours !== 12) hour24 += 12;
  if (period === "AM" && hours === 12) hour24 = 0;

  const breakTime = new Date(now);
  breakTime.setHours(hour24, minutes, 0, 0);

  if (breakTime <= now) {
    breakTime.setDate(breakTime.getDate() + 1);
  }

  return breakTime;
}

/**
 * Finds the best matching pair of students.
 */
async function findBestPair(
  waitingUsers: admin.firestore.QueryDocumentSnapshot[],
  forceMatch: boolean
): Promise<admin.firestore.QueryDocumentSnapshot[]> {
  if (waitingUsers.length < 2) return [];

  if (waitingUsers.length === 2) {
    logger.info("🚀 Only 2 students - matching them now!");
    return waitingUsers;
  }

  let bestPair: admin.firestore.QueryDocumentSnapshot[] = [];
  let bestScore = -1;

  for (let i = 0; i < waitingUsers.length - 1; i++) {
    for (let j = i + 1; j < waitingUsers.length; j++) {
      const user1 = waitingUsers[i];
      const user2 = waitingUsers[j];

      const userId1 = user1.data().userId;
      const userId2 = user2.data().userId;

      let score = 100;

      if (!forceMatch) {
        const matchedRecently = await checkRecentMatch(userId1, userId2);
        if (matchedRecently) {
          score -= 80;
          logger.info(`🚫 Recent match: ${userId1} & ${userId2}`);
        }
      }

      const joinTime1 = user1.data().createdAt?.seconds || 0;
      const joinTime2 = user2.data().createdAt?.seconds || 0;
      const avgWaitTime =
        (Date.now() / 1000 - (joinTime1 + joinTime2) / 2) / 60;
      score += Math.min(avgWaitTime * 2, 40);

      score += Math.random() * 10;

      if (score > bestScore) {
        bestScore = score;
        bestPair = [user1, user2];
      }
    }
  }

  if (bestPair.length === 2) {
    const userId1 = bestPair[0].data().userId;
    const userId2 = bestPair[1].data().userId;
    logger.info(
      `🎯 Best match: ${userId1} & ${userId2} (score: ${bestScore.toFixed(1)})`
    );
  }

  return bestPair;
}

/**
 * Checks if two users have recently been matched.
 */
async function checkRecentMatch(
  userId1: string,
  userId2: string
): Promise<boolean> {
  const oneDayAgo = new Date();
  oneDayAgo.setDate(oneDayAgo.getDate() - 1);

  const recentMatches = await db
    .collection("matches")
    .where("users", "array-contains", userId1)
    .where("matchedAt", ">=", admin.firestore.Timestamp.fromDate(oneDayAgo))
    .get();

  return recentMatches.docs.some((doc) => {
    const users = doc.data().users as string[];
    return users.includes(userId2);
  });
}

/**
 * Creates a match document and updates queue status for matched users.
 */
async function createMatch(
  matchedUsers: admin.firestore.QueryDocumentSnapshot[],
  timeSlot: string
): Promise<void> {
  const user1Data = matchedUsers[0].data();
  const user2Data = matchedUsers[1].data();
  const userId1 = user1Data.userId;
  const userId2 = user2Data.userId;

  const matchId = `match_${userId1}_${userId2}_${Date.now()}`;
  const today = new Date().toISOString().split("T")[0];

  logger.info(`🤝 Creating match: ${userId1} & ${userId2} for ${timeSlot}`);

  try {
    const updatePromises = [
      db.collection("matchingQueue").doc(matchedUsers[0].id).update({
        status: "matched",
        matchedWith: userId2,
        matchId,
        matchedAt: admin.firestore.FieldValue.serverTimestamp(),
      }),
      db.collection("matchingQueue").doc(matchedUsers[1].id).update({
        status: "matched",
        matchedWith: userId1,
        matchId,
        matchedAt: admin.firestore.FieldValue.serverTimestamp(),
      }),
    ];

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
    };

    await Promise.all([
      ...updatePromises,
      db.collection("matches").add(matchData),
    ]);

    logger.info(
      `✅ Match created! ${userId1} & ${userId2} will meet at ${timeSlot}`
    );
  } catch (error) {
    logger.error(`❌ Failed to create match: ${error}`);
    throw error;
  }
}
