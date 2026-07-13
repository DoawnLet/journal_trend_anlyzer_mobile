import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();
const db = admin.firestore();

/**
 * Cloud Function chạy định kỳ mỗi 15 phút để quét cập nhật từ OpenAlex
 * và gửi thông báo qua Firebase Cloud Messaging (FCM).
 */
export const checkOpenAlexUpdates = onSchedule("every 15 minutes", async (event) => {
  try {
    console.log("Bắt đầu quét cập nhật OpenAlex...");

    // 1. Lấy tất cả từ khóa đăng ký từ Firestore (collection: 'subscribed_keywords')
    const keywordsSnapshot = await db.collection("subscribed_keywords").get();

    if (keywordsSnapshot.empty) {
      console.log("Không có từ khóa nào được đăng ký theo dõi.");
      return;
    }

    console.log(`Tìm thấy ${keywordsSnapshot.size} từ khóa cần quét.`);

    for (const doc of keywordsSnapshot.docs) {
      const data = doc.data();
      const keyword = data.keyword;
      const lastPubId = data.last_pub_id || "";

      if (!keyword) continue;

      console.log(`Đang quét từ khóa: "${keyword}". ID bài viết cũ nhất đã ghi nhận: "${lastPubId}"`);

      // 2. Gọi OpenAlex API để tìm bài báo mới nhất thuộc từ khóa này
      // Lọc theo tìm kiếm từ khóa, sắp xếp theo ngày xuất bản giảm dần để lấy bài viết mới nhất
      const apiKey = process.env.OPENALEX_API_KEY;
      let openAlexUrl = `https://api.openalex.org/works?filter=default.search:${encodeURIComponent(keyword)}&sort=publication_date:desc&per_page=1`;

      if (apiKey) {
        openAlexUrl += `&api_key=${apiKey}`;
      } else {
        console.warn("Cảnh báo: Không tìm thấy OPENALEX_API_KEY trong biến môi trường. API có thể bị giới hạn hoặc báo lỗi 503.");
      }

      try {
        const response = await axios.get(openAlexUrl, {
          headers: {
            "Accept": "application/json",
            "User-Agent": "JournalTrendAnalyzerBackend/1.0 (mailto:minhvtbd12345@fpt.edu.vn)"
          },
          timeout: 10000 // Giới hạn thời gian kết nối 10 giây
        });

        const works = response.data.results;
        if (works && works.length > 0) {
          const latestWork = works[0];
          const latestWorkId = latestWork.id; // Ví dụ: "https://openalex.org/W123456789"
          const title = latestWork.title || "No Title";
          const journal = latestWork.primary_location?.source?.display_name || "Unknown Journal";

          // 3. So sánh nếu thấy bài báo mới nhất khác bài báo cũ
          if (true) {

            console.log(`[!] Phát hiện bài báo mới cho từ khóa "${keyword}": "${title}"`);

            // Cập nhật lại Firestore
            await doc.ref.update({ last_pub_id: latestWorkId });

            // 4. Gửi thông báo đẩy qua FCM đến Topic tương ứng
            // Tên topic được chuẩn hóa viết thường, không dấu cách
            const topicName = "new_publications";

            const message = {
              notification: {
                title: `Subscribed topic: "${keyword}" has a new publication!`,
                body: `"${title}" has just been published in the journal ${journal}.`,
              },
              data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                keyword: keyword,
                publication_title: title,
              },
              topic: topicName,
            };

            await admin.messaging().send(message);
            console.log(`[FCM] Successfully sent push notification to topic: "${topicName}"`);
          } else {
            console.log(`Không có bài viết mới cho từ khóa "${keyword}"`);
          }
        }
      } catch (apiError) {
        console.error(`Lỗi khi gọi API OpenAlex cho từ khóa "${keyword}":`, apiError);
      }
    }
  } catch (error) {
    console.error("Lỗi hệ thống trong tiến trình checkOpenAlexUpdates:", error);
  }
});
