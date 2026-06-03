import 'dart:async';
import 'dart:io';

/// Lớp tiện ích chuyển dịch các thông báo lỗi kỹ thuật thô của hệ thống (Exceptions)
/// thành các thông điệp tiếng Việt thân thiện, gần gũi và rõ nghĩa với người dùng cuối.
class ErrorTranslator {
  ErrorTranslator._();

  /// Phân tích đối tượng lỗi (error) và chuyển ngữ tương ứng.
  static String translate(dynamic error) {
    if (error == null) {
      return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
    }

    // 1. Phân loại theo Kiểu dữ liệu Exception cụ thể
    if (error is SocketException) {
      return 'Không có kết nối Internet. Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động trên thiết bị của bạn.';
    }
    
    if (error is TimeoutException) {
      return 'Kết nối mạng quá chậm hoặc bị quá hạn. Vui lòng tìm nơi có sóng tốt hơn và thử lại.';
    }

    if (error is FormatException) {
      return 'Lỗi đồng bộ hệ thống. Dữ liệu phản hồi từ OpenAlex bị lỗi định dạng.';
    }

    if (error is HttpException) {
      return 'Kết nối tới máy chủ OpenAlex bị gián đoạn. Vui lòng quay lại sau.';
    }

    // 2. Phân loại theo nội dung chuỗi (String Matching) nếu lỗi là Exception chung hoặc chuỗi thô
    final String errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socketexception') || 
        errorStr.contains('failed host lookup') || 
        errorStr.contains('network_error') ||
        errorStr.contains('host lookup failed') ||
        errorStr.contains('no address associated with hostname') ||
        errorStr.contains('clientexception')) {
      return 'Không có kết nối Internet. Vui lòng kiểm tra kết nối mạng Wifi hoặc 3G/4G trên thiết bị.';
    }
    
    if (errorStr.contains('timeout') || errorStr.contains('timed out') || errorStr.contains('time out')) {
      return 'Thời gian kết nối quá hạn do tín hiệu mạng yếu. Vui lòng thử lại.';
    }

    if (errorStr.contains('connection refused') || errorStr.contains('connection closed') || errorStr.contains('connection failed')) {
      return 'Kết nối tới máy chủ bị từ chối hoặc bị đóng đột ngột. Vui lòng thử lại sau.';
    }

    if (errorStr.contains('format_exception') || errorStr.contains('invalid json') || errorStr.contains('formatexception') || errorStr.contains('json decode')) {
      return 'Hệ thống đang xử lý lỗi định dạng dữ liệu từ máy chủ. Vui lòng thử lại sau.';
    }

    // Phân loại mã lỗi phản hồi HTTP
    if (errorStr.contains('404')) {
      return 'Không tìm thấy dữ liệu yêu cầu từ hệ thống (Lỗi 404).';
    }
    if (errorStr.contains('500') || errorStr.contains('502') || errorStr.contains('503') || errorStr.contains('504')) {
      return 'Máy chủ dữ liệu OpenAlex đang bận hoặc bảo trì. Vui lòng thử lại sau ít phút.';
    }
    if (errorStr.contains('403') || errorStr.contains('401')) {
      return 'Yêu cầu bị từ chối truy cập do thiếu quyền xác thực.';
    }
    
    // Các lỗi liên quan đến trạng thái đang xử lý/bận
    if (errorStr.contains('processing') || errorStr.contains('handling') || errorStr.contains('loading') || errorStr.contains('busy')) {
      return 'Hệ thống đang xử lý yêu cầu, vui lòng chờ trong giây lát.';
    }

    // Thông báo lỗi mặc định thân thiện
    final cleanMsg = error.toString().replaceAll('Exception:', '').replaceAll('Exception', '').trim();
    if (cleanMsg.isEmpty) {
      return 'Hệ thống đang xử lý yêu cầu hoặc gặp sự cố.';
    }
    return 'Hệ thống đang xử lý hoặc gặp sự cố: $cleanMsg';
  }
}
