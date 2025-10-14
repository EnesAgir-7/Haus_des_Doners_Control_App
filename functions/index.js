/**
 * Cloud Function to remove expired stops from route documents.
 * Scans the "routes" collection and removes stops whose expiryDate
 * is in the past. Scheduled to run periodically.
 */

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

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
 * Runs at 8:00 AM Asia/Karachi time every day.
 */
exports.cleanupExpiredStops = onSchedule(
    {
      schedule: "0 8 * * *",
      timeZone: "Asia/Karachi",
      // timeZone: "Europe/Berlin"
      // schedule: "*/3 * * * *",
    },
    async (event) => {
      const now = new Date();

      try {
        const routesSnap = await db.collection("routes").get();

        // Collect updates to apply
        const updates = [];

        for (const doc of routesSnap.docs) {
          const data = doc.data() || {};
          const stops = Array.isArray(data.stops) ? data.stops : [];

          const filteredStops = stops.filter((stop) => {
            const expiryDate = parseExpiry(stop.expiryDate);
            // Keep the stop if no expiry or expiry is in the future
            return expiryDate === null || expiryDate.getTime() > now.getTime();
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

        // Commit updates in batches of up to 500
        while (updates.length) {
          const batch = db.batch();
          const chunk = updates.splice(0, 500);
          chunk.forEach((u) => batch.update(u.ref, u.data));
          await batch.commit();
        }

        console.log("cleanupExpiredStops completed.");
        return null;
      } catch (err) {
        console.error("Error in cleanupExpiredStops:", err);
        throw err;
      }
    },
);
