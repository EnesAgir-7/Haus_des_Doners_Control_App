const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getMessaging} = require("firebase-admin/messaging");

/**
 * Send notification to multiple tokens (batch) - FIXED VERSION
 */
exports.sendNotificationToMultipleTokens = onCall(async (request) => {
  // Check if user is authenticated
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to send notifications",
    );
  }

  const {fcmTokens, title, body, data} = request.data;

  // Validate input
  if (!fcmTokens || !Array.isArray(fcmTokens) || fcmTokens.length === 0) {
    throw new HttpsError(
        "invalid-argument",
        "fcmTokens must be a non-empty array",
    );
  }

  if (!title || !body) {
    throw new HttpsError(
        "invalid-argument",
        "Missing required fields: title, body",
    );
  }

  // ✅ REMOVE DUPLICATE TOKENS
  const uniqueTokens = [...new Set(fcmTokens)];

  console.log(`Original tokens: ${fcmTokens.length},
     Unique: ${uniqueTokens.length}`);

  const message = {
    // ✅ ADD NOTIFICATION PAYLOAD (this prevents double notifications)
    notification: {
      title: title,
      body: body,
    },
    data: {
      title: title,
      body: body,
      ...(data || {}),
    },
    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel", // ✅ Match your Flutter channel
        sound: "default",
        priority: "high",
        defaultSound: true,
        defaultVibrateTimings: true,
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: title,
            body: body,
          },
          sound: "default",
          badge: 1,
        },
      },
      headers: {
        "apns-priority": "10",
      },
    },
  };

  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens: uniqueTokens, // ✅ Use unique tokens only
      ...message,
    });

    console.log(
        `Batch: ${response.successCount} sent, ${response.failureCount} faild`,
    );

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      originalTokenCount: fcmTokens.length,
      uniqueTokenCount: uniqueTokens.length,
      responses: response.responses.map((resp, idx) => ({
        token: uniqueTokens[idx],
        success: resp.success,
        error: resp.error ? resp.error.message : null,
      })),
    };
  } catch (error) {
    console.error("❌ Error sending batch notification:", error);
    throw new HttpsError("internal", error.message);
  }
});

/**
 * Send notification to a single FCM token - FIXED VERSION
 */
exports.sendNotificationToToken = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to send notifications",
    );
  }

  const {fcmToken, title, body, data} = request.data;

  if (!fcmToken || !title || !body) {
    throw new HttpsError(
        "invalid-argument",
        "Missing required fields: fcmToken, title, body",
    );
  }

  const message = {
    token: fcmToken,
    // ✅ ADD NOTIFICATION PAYLOAD
    notification: {
      title: title,
      body: body,
    },
    data: {
      title: title,
      body: body,
      ...(data || {}),
    },
    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        sound: "default",
        priority: "high",
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: title,
            body: body,
          },
          sound: "default",
        },
      },
      headers: {
        "apns-priority": "10",
      },
    },
  };

  try {
    const response = await getMessaging().send(message);
    console.log("✅ Notification sent successfully:", response);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error("❌ Error sending notification:", error);
    throw new HttpsError("internal", error.message);
  }
});

/**
 * Send notification to a topic - FIXED VERSION
 */
exports.sendNotificationToTopic = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to send notifications",
    );
  }

  const {topic, title, body, data} = request.data;

  if (!topic || !title || !body) {
    throw new HttpsError(
        "invalid-argument",
        "Missing required fields: topic, title, body",
    );
  }

  const message = {
    topic: topic,
    // ✅ ADD NOTIFICATION PAYLOAD
    notification: {
      title: title,
      body: body,
    },
    data: {
      title: title,
      body: body,
      ...(data || {}),
    },
    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        sound: "default",
        priority: "high",
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: title,
            body: body,
          },
          sound: "default",
        },
      },
      headers: {
        "apns-priority": "10",
      },
    },
  };

  try {
    const response = await getMessaging().send(message);
    console.log("✅ Topic notification sent successfully:", response);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error("❌ Error sending topic notification:", error);
    throw new HttpsError("internal", error.message);
  }
});
