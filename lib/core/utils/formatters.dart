/// Lớp tiện ích định dạng dữ liệu trong ứng dụng.
class Formatters {
  Formatters._();

  /// Định dạng số lượt trích dẫn bài viết thành các hậu tố K (nghìn) hoặc M (triệu) rút gọn.
  /// Ví dụ:
  /// - `452` -> `452`
  /// - `1250` -> `1.3K`
  /// - `982400` -> `982.4K`
  /// - `1540200` -> `1.5M`
  static String formatCitationCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      double value = count / 1000.0;
      return '${value.toStringAsFixed(value < 10 ? 1 : 0)}K';
    } else {
      double value = count / 1000000.0;
      return '${value.toStringAsFixed(value < 10 ? 1 : 0)}M';
    }
  }

  /// Định dạng danh sách tác giả để hiển thị gọn gàng.
  /// Hiển thị tối đa 3 tác giả. Nếu nhiều hơn, hiển thị "Tác giả 1, Tác giả 2, Tác giả 3 và cộng sự".
  static String formatAuthors(List<String> authors) {
    if (authors.isEmpty) {
      return 'Không rõ tác giả';
    }
    if (authors.length <= 3) {
      return authors.join(', ');
    }
    return '${authors.sublist(0, 3).join(', ')} và cộng sự';
  }
}
