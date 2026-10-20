# MuMu Emulator UI/UX & Dynamic Theme Optimization

## Goal
Khởi chạy ứng dụng trên MuMu Emulator (`127.0.0.1:16416`), tự động kiểm tra giao diện qua adb screencap, hiện đại hóa toàn diện UI/UX với Dynamic Theme (Dark & Light), hiệu ứng mượt mà (3D Flip, Staggered animation, Bouncing tap, Page transitions) và tối ưu công thái học (thumb-zone, 48dp target).

## Tasks
- [x] Task 1: Khởi chạy app trên MuMu emulator qua `flutter run -d 127.0.0.1:16416` và kiểm tra kết nối adb → Verify: App hiển thị thành công trên thiết bị không có crash.
- [x] Task 2: Chụp ảnh màn hình (screenshot) baseline qua `adb exec-out screencap` để kiểm tra trực quan các màn hình hiện tại → Verify: File screenshot được lưu và phân tích.
- [x] Task 3: Xây dựng Dynamic Theme hoàn chỉnh trong `AppTheme` (Hỗ trợ Dark OLED & Light thanh lịch, ColorScheme chuẩn Material 3, loại bỏ màu tím/purple ban, đồng bộ typography và semantic colors) → Verify: `app_theme.dart` có đủ `darkTheme` và `lightTheme`, `app.dart` hỗ trợ `ThemeMode.system` hoặc toggle.
- [x] Task 4: Xây dựng bộ công cụ Animation & Micro-interaction tái sử dụng:
  - `PressableScale`: Co giãn nhẹ (scale micro-interaction) kết hợp HapticFeedback khi bấm.
  - `StaggeredAnimation`: Hiệu ứng trượt và mờ dần (slide & fade) mượt mà cho danh sách.
  - Tối ưu `PageTransitionsTheme` cho toàn app chuyển cảnh 60fps mượt như iOS/Pixel.
  → Verify: Các widget animation độc lập, không gây giật lag (jank-free).
- [x] Task 5: Nâng cấp và tối ưu UX/UI Màn hình chính (`home_page.dart`): Hero header, greeting cá nhân hóa, streak badge nổi bật, card bài học bo cong đẹp mắt, floating nav bar xúc giác. → Verify: Giao diện trực quan, spacing chuẩn 8dp, thumb-friendly.
- [x] Task 6: Nâng cấp Flashcard Page & Review Page: 3D Flip có góc nhìn phối cảnh (perspective transform), bộ nút điều hướng vùng ngón cái (thumb-zone), hiệu ứng lật thẻ mượt mà, thanh tiến độ sinh động. → Verify: Lật thẻ 60fps không giật, nút bấm rõ ràng >= 48dp.
- [x] Task 7: Nâng cấp SRS Review & Test Page: Hiệu ứng chọn đáp án phản hồi lập tức, kết quả tổng kết trực quan, hỗ trợ vuốt thẻ trực quan. → Verify: Trải nghiệm làm bài kiểm tra và ôn tập nhạy, rõ ràng cả trên nền tối lẫn sáng.
- [x] Task 8: Nâng cấp Profile Page & Folder Page: Layout phân cấp khoa học, bổ sung chuyển đổi Theme trực tiếp nếu cần, danh sách thư mục trực quan. → Verify: Hiển thị đồng nhất và hài hòa với hệ màu mới.
- [x] Task 9: Chạy kiểm tra tĩnh (`flutter analyze`), chụp screenshot kiểm chứng kết quả trên MuMu Emulator, và kiểm thử toàn bộ luồng. → Verify: `flutter analyze` 0 lỗi, app chạy êm ru trên MuMu.

## Done When
- [x] App chạy mượt mà trên MuMu Emulator không crash hoặc jank.
- [x] Giao diện hỗ trợ đầy đủ Dark Mode sâu và Light Mode thanh lịch với độ tương phản cao.
- [x] Các hiệu ứng lật thẻ 3D, chuyển trang và chạm phản hồi xúc giác mượt mà 60fps.
- [x] Các nút bấm và tương tác đạt chuẩn công thái học di động (>= 48dp, vùng ngón cái).
- [x] Toàn bộ mã nguồn sạch, tuân thủ `clean-code` và `mobile-design`.
