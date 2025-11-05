const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getMessaging} = require("firebase-admin/messaging");

/**
 * Send notification to a single FCM token
 */
exports.sendNotificationToToken = onCall(async (request) => {
  // Check if user is authenticated
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to send notifications",
    );
  }

  const {fcmToken, title, body, data} = request.data;

  // Validate input
  if (!fcmToken || !title || !body) {
    throw new HttpsError(
        "invalid-argument",
        "Missing required fields: fcmToken, title, body",
    );
  }

  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: data || {},
    android: {
      priority: "high",
      notification: {
        sound: "default",
        channelId: "high_importance_channel",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
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
 * Send notification to a topic
 */
exports.sendNotificationToTopic = onCall(async (request) => {
  // Check if user is authenticated
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to send notifications",
    );
  }

  const {topic, title, body, data} = request.data;

  // Validate input
  if (!topic || !title || !body) {
    throw new HttpsError(
        "invalid-argument",
        "Missing required fields: topic, title, body",
    );
  }

  const message = {
    topic: topic,
    notification: {
      title: title,
      body: body,
    },
    data: data || {},
    android: {
      priority: "high",
      notification: {
        sound: "default",
        channelId: "high_importance_channel",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
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

/**
 * Send notification to multiple tokens (batch)
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

  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: data || {},
    android: {
      priority: "high",
      notification: {
        sound: "default",
        channelId: "high_importance_channel",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens: fcmTokens,
      ...message,
    });

    console.log(
        `Batch: ${response.successCount} sent, ${response.failureCount} faild`,
    );

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses.map((resp, idx) => ({
        token: fcmTokens[idx],
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
 * Send notification with custom message payload
 */
exports.sendCustomNotification = onCall(async (request) => {
  // Check if user is authenticated
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to send notifications",
    );
  }

  const {fcmToken, topic, message} = request.data;

  // Validate input
  if ((!fcmToken && !topic) || !message) {
    throw new HttpsError(
        "invalid-argument",
        "Provide either fcmToken or topic, and a message object",
    );
  }

  // Add token or topic to message
  if (fcmToken) {
    message.token = fcmToken;
  } else {
    message.topic = topic;
  }

  try {
    const response = await getMessaging().send(message);
    console.log("✅ Custom notification sent successfully:", response);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error("❌ Error sending custom notification:", error);
    throw new HttpsError("internal", error.message);
  }
});

/**
 * Subscribe user to topics
 */
exports.subscribeToTopics = onCall(async (request) => {
  // Check if user is authenticated
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated",
    );
  }

  const {fcmToken, topics} = request.data;

  if (!fcmToken || !topics || !Array.isArray(topics)) {
    throw new HttpsError(
        "invalid-argument",
        "fcmToken and topics array required",
    );
  }

  try {
    await Promise.all(
        topics.map((topic) =>
          getMessaging().subscribeToTopic(fcmToken, topic),
        ),
    );

    console.log(`✅ Subscribed to topics:`, topics);

    return {
      success: true,
      topics: topics,
    };
  } catch (error) {
    console.error("❌ Error subscribing to topics:", error);
    throw new HttpsError("internal", error.message);
  }
});

/**
 * Unsubscribe user from topics
 */
exports.unsubscribeFromTopics = onCall(async (request) => {
  // Check if user is authenticated
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated",
    );
  }

  const {fcmToken, topics} = request.data;

  if (!fcmToken || !topics || !Array.isArray(topics)) {
    throw new HttpsError(
        "invalid-argument",
        "fcmToken and topics array required",
    );
  }

  try {
    await Promise.all(
        topics.map((topic) =>
          getMessaging().unsubscribeFromTopic(fcmToken, topic),
        ),
    );

    console.log(`✅ Unsubscribed from topics:`, topics);

    return {
      success: true,
      topics: topics,
    };
  } catch (error) {
    console.error("❌ Error unsubscribing from topics:", error);
    throw new HttpsError("internal", error.message);
  }
});
