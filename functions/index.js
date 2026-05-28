const { initializeApp } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

exports.notifyUsersOnReportCreated = onDocumentCreated(
  "reports/{reportId}",
  async (event) => {
    const report = event.data?.data();
    const reportId = event.params.reportId;

    if (!report) {
      logger.warn("Report created without data", { reportId });
      return;
    }

    const reporterUserId =
      typeof report.user_id === "string" ? report.user_id.trim() : "";
    const tokenDocs = await db.collectionGroup("fcm_tokens").get();
    const tokenRefsByToken = new Map();
    const userSettingsById = new Map();
    let skippedReporterTokens = 0;
    let skippedPreferenceTokens = 0;

    for (const doc of tokenDocs.docs) {
      const tokenOwnerUserId = doc.ref.parent.parent?.id || "";
      if (reporterUserId && tokenOwnerUserId === reporterUserId) {
        skippedReporterTokens += 1;
        continue;
      }

      const userSettings = await getUserNotificationSettings(
        tokenOwnerUserId,
        userSettingsById,
      );
      if (!shouldNotifyUser(report, userSettings)) {
        skippedPreferenceTokens += 1;
        continue;
      }

      const token = doc.get("token") || doc.id;
      if (typeof token === "string" && token.trim().length > 0) {
        tokenRefsByToken.set(token.trim(), doc.ref);
      }
    }

    const tokens = [...tokenRefsByToken.keys()];
    if (tokens.length === 0) {
      logger.info("No notification tokens found for new report", { reportId });
      return;
    }

    if (skippedReporterTokens > 0) {
      logger.info("Skipped reporter notification tokens", {
        reportId,
        reporterUserId,
        count: skippedReporterTokens,
      });
    }
    if (skippedPreferenceTokens > 0) {
      logger.info("Skipped notification tokens by user preference", {
        reportId,
        count: skippedPreferenceTokens,
      });
    }

    const reportType = report.report_type === "flood" ? "Flood" : "Rain";
    const location = "Calamba";
    const description =
      typeof report.description === "string" && report.description.trim()
        ? report.description.trim()
        : `${reportType} conditions were reported nearby.`;
    const title = `RainGuard: ${reportType} report`;
    const body = `${location} - ${description}`;

    const invalidTokens = [];
    const chunks = chunk(tokens, 500);

    for (const tokenChunk of chunks) {
      const response = await messaging.sendEachForMulticast({
        tokens: tokenChunk,
        notification: {
          title,
          body,
        },
        data: {
          type: "community_report",
          report_id: reportId,
          report_type: report.report_type || "",
          title,
          body,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "community_reports",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            color: "#0B6BD3",
            icon: "ic_stat_rainguard",
            tag: `report-${reportId}`,
          },
        },
      });

      response.responses.forEach((sendResult, index) => {
        if (sendResult.success) return;

        const code = sendResult.error?.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(tokenChunk[index]);
        } else {
          logger.warn("Failed to send report notification", {
            reportId,
            code,
            message: sendResult.error?.message,
          });
        }
      });

      logger.info("Report notification batch sent", {
        reportId,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
    }

    await Promise.all(
      invalidTokens.map((token) => tokenRefsByToken.get(token)?.delete()),
    );

    if (invalidTokens.length > 0) {
      logger.info("Removed invalid notification tokens", {
        count: invalidTokens.length,
      });
    }
  },
);

exports.notifyUsersOnAlertPublished = onDocumentWritten(
  "alerts/{alertId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const alertId = event.params.alertId;

    if (!after) {
      logger.info("Alert document deleted; no notification needed", {
        alertId,
      });
      return;
    }

    const wasPublished = before?.status === "published";
    const isPublished = after.status === "published";

    if (!isPublished || wasPublished) {
      return;
    }

    const tokenDocs = await db.collectionGroup("fcm_tokens").get();
    const tokenRefsByToken = new Map();

    for (const doc of tokenDocs.docs) {
      const token = doc.get("token") || doc.id;
      if (typeof token === "string" && token.trim().length > 0) {
        tokenRefsByToken.set(token.trim(), doc.ref);
      }
    }

    const tokens = [...tokenRefsByToken.keys()];
    if (tokens.length === 0) {
      logger.info("No notification tokens found for published alert", {
        alertId,
      });
      await event.data.after.ref.set(
        {
          push_failure_count: 0,
          push_sent_at: FieldValue.serverTimestamp(),
          push_token_count: 0,
        },
        { merge: true },
      );
      return;
    }

    const alertTitle =
      typeof after.title === "string" && after.title.trim()
        ? after.title.trim()
        : "Safety alert";
    const area =
      typeof after.area === "string" && after.area.trim()
        ? after.area.trim()
        : "All residents";
    const body =
      typeof after.message === "string" && after.message.trim()
        ? after.message.trim()
        : `Safety advisory for ${area}.`;
    const title = `RainGuard: ${alertTitle}`;
    const riskLevel =
      typeof after.risk_level === "string" ? after.risk_level : "";

    const invalidTokens = [];
    let failureCount = 0;
    const chunks = chunk(tokens, 500);

    for (const tokenChunk of chunks) {
      const response = await messaging.sendEachForMulticast({
        tokens: tokenChunk,
        notification: {
          title,
          body,
        },
        data: {
          type: "safety_alert",
          alert_id: alertId,
          area,
          body,
          risk_level: riskLevel,
          title,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "community_reports",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            color: "#0B6BD3",
            icon: "ic_stat_rainguard",
            tag: `alert-${alertId}`,
          },
        },
      });

      failureCount += response.failureCount;

      response.responses.forEach((sendResult, index) => {
        if (sendResult.success) return;

        const code = sendResult.error?.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(tokenChunk[index]);
        } else {
          logger.warn("Failed to send safety alert notification", {
            alertId,
            code,
            message: sendResult.error?.message,
          });
        }
      });

      logger.info("Safety alert notification batch sent", {
        alertId,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
    }

    await Promise.all(
      invalidTokens.map((token) => tokenRefsByToken.get(token)?.delete()),
    );

    await event.data.after.ref.set(
      {
        push_failure_count: failureCount,
        push_sent_at: FieldValue.serverTimestamp(),
        push_token_count: tokens.length,
      },
      { merge: true },
    );

    if (invalidTokens.length > 0) {
      logger.info("Removed invalid notification tokens after alert push", {
        alertId,
        count: invalidTokens.length,
      });
    }
  },
);

function chunk(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

async function getUserNotificationSettings(userId, cache) {
  if (!userId) return {};
  if (cache.has(userId)) return cache.get(userId);

  const snapshot = await db.collection("users").doc(userId).get();
  const settings = snapshot.exists ? snapshot.data() || {} : {};
  cache.set(userId, settings);
  return settings;
}

function shouldNotifyUser(report, userSettings) {
  const preference = userSettings.notification_preference || "all_reports";

  switch (preference) {
    case "flood_only":
      return report.report_type === "flood";
    case "nearby_only":
      return isNearbyReport(report, userSettings);
    case "high_risk_only":
      return isHighRiskReport(report);
    case "all_reports":
    default:
      return true;
  }
}

function isHighRiskReport(report) {
  const reportType =
    typeof report.report_type === "string" ? report.report_type : "";
  const riskLevel =
    typeof report.risk_level === "string" ? report.risk_level : "";

  return (
    reportType === "flood" ||
    riskLevel === "flood" ||
    riskLevel === "high" ||
    riskLevel === "high_risk"
  );
}

function isNearbyReport(report, userSettings) {
  const reportLat = Number(report.latitude);
  const reportLng = Number(report.longitude);
  const userLat = Number(userSettings.notification_latitude);
  const userLng = Number(userSettings.notification_longitude);
  const radiusKm = Number(userSettings.notification_radius_km) || 5;

  if (
    !Number.isFinite(reportLat) ||
    !Number.isFinite(reportLng) ||
    !Number.isFinite(userLat) ||
    !Number.isFinite(userLng)
  ) {
    return false;
  }

  return distanceKm(reportLat, reportLng, userLat, userLng) <= radiusKm;
}

function distanceKm(lat1, lng1, lat2, lng2) {
  const earthRadiusKm = 6371;
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}
