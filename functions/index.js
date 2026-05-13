const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
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
    let skippedReporterTokens = 0;

    tokenDocs.forEach((doc) => {
      const tokenOwnerUserId = doc.ref.parent.parent?.id || "";
      if (reporterUserId && tokenOwnerUserId === reporterUserId) {
        skippedReporterTokens += 1;
        return;
      }

      const token = doc.get("token") || doc.id;
      if (typeof token === "string" && token.trim().length > 0) {
        tokenRefsByToken.set(token.trim(), doc.ref);
      }
    });

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

function chunk(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}
