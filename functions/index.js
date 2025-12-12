/**
 * Cloud Functions for Firebase Admin operations
 */

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");
const functions = require("firebase-functions");
const admin = require("firebase-admin");

initializeApp();
const db = getFirestore();
const auth = getAuth();

// ✅ Detect environment (for logging only)
const projectId = process.env.GCLOUD_PROJECT || process.env.PROJECT_ID;
const isProd = projectId === "controlapp-production";
const isDev = projectId === "controlapp-23df2";

console.log(`🔥 Functions initialized`);
console.log(`🔥 Project ID: ${projectId}`);
console.log(`🔥 ENV: ${isProd ? "PROD" : isDev ? "DEV" : "UNKNOWN"}`);

if (!isProd && !isDev) {
  console.warn(`⚠️ WARNING: Unknown project ID: ${projectId}`);
}

/**
 * Parse an expiry value to a JavaScript Date.
 * Accepts Firestore Timestamp, ISO strings, or Date objects.
 * @param {*} expiry - expiry value from Firestore
 * @return {Date|null} Parsed Date or null when not parseable
 */
function parseExpiry(expiry) {
  if (!expiry) {
    return null;
  }

  // Firestore Timestamp
  if (typeof expiry.toDate === "function") {
    return expiry.toDate();
  }

  // Handle Date or ISO string
  const parsed = new Date(expiry);
  if (!Number.isNaN(parsed.getTime())) {
    return parsed;
  }

  return null;
}

/**
 * Scheduled function that removes expired stops from each route doc.
 * Runs daily at 8 AM Pakistan time.
 */
exports.cleanupExpiredStops = onSchedule(
    {
      schedule: "0 8 * * *",
      timeZone: "Asia/Karachi",
    },
    async (event) => {
      const now = new Date();
      console.log("🕐 cleanupExpiredStops started at:", now);

      try {
        const routesSnap = await db.collection("routes").get();
        console.log(`📦 Found ${routesSnap.size} route docs`);

        let totalStopsChecked = 0;
        let totalStopsRemoved = 0;
        const updates = [];

        for (const doc of routesSnap.docs) {
          const data = doc.data() || {};
          const stops = Array.isArray(data.stops) ? data.stops : [];

          const filteredStops = stops.filter((stop) => {
            const expiryDate = parseExpiry(stop.expiryDate);
            totalStopsChecked++;

            if (expiryDate === null) return true;
            const expired = expiryDate.getTime() <= now.getTime();

            if (expired) {
              totalStopsRemoved++;
              console.log(
                  `🧹 Removing expired stop from route ${doc.id} with expiry:`,
                  expiryDate.toISOString(),
              );
            }
            return !expired;
          });

          if (filteredStops.length !== stops.length) {
            updates.push({
              ref: doc.ref,
              data: {
                stops: filteredStops,
                updatedAt: FieldValue.serverTimestamp(),
              },
            });
          }
        }

        while (updates.length) {
          const batch = db.batch();
          const chunk = updates.splice(0, 500);
          chunk.forEach((u) => batch.update(u.ref, u.data));
          await batch.commit();
        }

        console.log(
            `Checked ${totalStopsChecked} stops, removed ${totalStopsRemoved}`,
        );
        return null;
      } catch (err) {
        console.error("❌ Error in cleanupExpiredStops:", err);
        throw err;
      }
    },
);


// Cloud Function to update inspector password and force logout
exports.updatePassword = functions.https.onCall(async (request) => {
  const insUid = request.data && request.data.uid;
  const newPassword = request.data && request.data.newPassword;
  const callerUid = request.auth && request.auth.uid;

  // Validate input
  if (!insUid) {
    throw new HttpsError("invalid-argument", "Inspector UID is required");
  }
  if (!newPassword || newPassword.length < 6) {
    throw new HttpsError(
        "invalid-argument",
        "New password must be at least 6 characters long",
    );
  }

  try {
    // Verify caller is admin
    const callerDoc = await db.collection("inspectors").doc(callerUid).get();
    if (!callerDoc.exists) {
      throw new HttpsError("permission-denied", "Caller user not found");
    }

    const callerData = callerDoc.data();
    const isAdmin =
      callerData.role === "admin" ||
      callerData.userType === "admin" ||
      callerData.type === "admin";

    if (!isAdmin) {
      throw new HttpsError(
          "permission-denied",
          "Only admins can update inspector passwords",
      );
    }

    // Update password
    await admin.auth().updateUser(insUid, {password: newPassword});
    await admin.auth().revokeRefreshTokens(insUid);

    return {
      success: true,
      message: "Password updated successfully. Inspector will be logged out.",
    };
  } catch (error) {
    console.error("Error updating password:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
        "internal",
        error.message || "Failed to update password",
    );
  }
});

/**
 * Callable function to delete an inspector account.
 * Only admins can call this function.
 * Deletes user from Auth, Firestore users collection, and routes collection.
 */
exports.deleteInspector = onCall(async (request) => {
  // Check if user is authenticated
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be logged in to perform this action",
    );
  }

  const insUid = request.data.uid;
  const callerUid = request.auth.uid;

  // Validate input
  if (!insUid) {
    throw new HttpsError("invalid-argument", "Inspector UID is required");
  }

  try {
    // Verify caller is admin
    const callerDoc = await db.collection("inspectors").doc(callerUid).get();

    if (!callerDoc.exists) {
      throw new HttpsError("permission-denied", "Caller user not found");
    }

    const callerData = callerDoc.data();

    // Check if caller is admin
    const isAdmin =
      callerData.role === "admin" ||
      callerData.userType === "admin" ||
      callerData.type === "admin";

    if (!isAdmin) {
      throw new HttpsError(
          "permission-denied",
          "Only admins can delete inspectors",
      );
    }

    // Prevent admin from deleting themselves
    if (insUid === callerUid) {
      throw new HttpsError(
          "failed-precondition",
          "You cannot delete your own account",
      );
    }

    // Check if inspector exists
    const inspectorDoc = await db.collection("inspectors").doc(insUid).get();
    if (!inspectorDoc.exists) {
      throw new HttpsError("not-found", "Inspector not found");
    }

    // Check if inspector's route has stops
    const routeDoc = await db.collection("routes").doc(insUid).get();

    if (routeDoc.exists) {
      const routeData = routeDoc.data();
      const stops = routeData.stops || [];

      if (stops.length > 0) {
        throw new HttpsError(
            "failed-precondition",
            "There is an active branch visit in the route. " +
          "Please remove all stops first.",
        );
      }
    }

    // Use batch for atomic Firestore operations
    const batch = db.batch();

    // Delete user document
    const userRef = db.collection("inspectors").doc(insUid);
    batch.delete(userRef);

    // Delete route document if exists
    if (routeDoc.exists) {
      const routeRef = db.collection("routes").doc(insUid);
      batch.delete(routeRef);
    }

    // Commit batch
    await batch.commit();
    console.log(`✅ Deleted Firestore data for inspector: ${insUid}`);

    // Delete from Firebase Auth using Admin SDK
    await auth.deleteUser(insUid);
    console.log(`✅ Deleted Auth account for inspector: ${insUid}`);

    return {
      success: true,
      message: "Inspector deleted successfully",
    };
  } catch (error) {
    console.error("❌ Error deleting inspector:", error);

    // If it's already an HttpsError, throw it as is
    if (error instanceof HttpsError) {
      throw error;
    }

    // Otherwise, wrap it in an HttpsError
    throw new HttpsError(
        "internal",
        `Failed to delete inspector: ${error.message}`,
    );
  }
});

// ==========================================
// 📱 FCM NOTIFICATION FUNCTIONS
// ==========================================

// Import and export notification functions
const notificationFunctions = require("./notifications/fcm-notifications");

exports.sendNotificationToToken =
  notificationFunctions.sendNotificationToToken;
exports.sendNotificationToTopic =
  notificationFunctions.sendNotificationToTopic;
exports.sendNotificationToMultipleTokens =
  notificationFunctions.sendNotificationToMultipleTokens;
exports.sendCustomNotification =
  notificationFunctions.sendCustomNotification;
exports.subscribeToTopics =
  notificationFunctions.subscribeToTopics;
exports.unsubscribeFromTopics =
  notificationFunctions.unsubscribeFromTopics;
