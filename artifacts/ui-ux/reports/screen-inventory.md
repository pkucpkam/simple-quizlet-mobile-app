# Screen Inventory Report

**Date:** 2026-10-20  
**Target Platform:** Android (MuMu Emulator - SM A156E • Android 12 • 900x1600)  
**Framework:** Flutter 3.41.7 • Dart 3.11.5  
**Auditor:** Mobile UI/UX Engineering Specialist Agent (`mobile-developer`)

---

## 1. Discovered Screen Inventory

| # | Screen Name | Route | Source File | Reachable State | Baseline Screenshot |
|---|-------------|-------|-------------|-----------------|---------------------|
| 1 | **Home Screen** | `/` | `lib/presentation/pages/home_page.dart` | Authenticated | `artifacts/ui-ux/baseline/01_home_screen.png` |
| 2 | **Profile Screen** | `/profile` | `lib/presentation/pages/profile_page.dart` | Authenticated | `artifacts/ui-ux/baseline/02_profile_screen.png` |
| 3 | **Notification Settings** | `/notification-settings` | `lib/presentation/pages/notification_settings_page.dart` | Authenticated (Blocked by P0 loop initially) | `artifacts/ui-ux/baseline/03_notification_settings.png` |
| 4 | **Login Screen** | `/login` | `lib/presentation/pages/login_page.dart` | Unauthenticated | `artifacts/ui-ux/baseline/04_login_screen.png` |
| 5 | **Register Screen** | `/register` | `lib/presentation/pages/register_page.dart` | Unauthenticated | `artifacts/ui-ux/baseline/05_register_screen.png` |
| 6 | **My Lessons Screen** | `/my-lessons` | `lib/presentation/pages/my_lessons_page.dart` | Authenticated | `artifacts/ui-ux/baseline/09_my_lessons.png` |
| 7 | **SRS Review Screen** | `/srs-review` | `lib/presentation/pages/srs_review_page.dart` | Authenticated | `artifacts/ui-ux/baseline/10_srs_review.png`, `10b_srs_review_answered.png` |
| 8 | **Folder Detail Screen** | `/folder/:id` | `lib/presentation/pages/folder_page.dart` | Authenticated | `artifacts/ui-ux/baseline/11_folder_detail.png` |
| 9 | **Lesson Detail Screen** | `/lesson/:id` | `lib/presentation/pages/lesson_page.dart` | Authenticated | `artifacts/ui-ux/baseline/12_lesson_detail.png` |
| 10 | **Flashcard Study (Front)** | `/study/:id` | `lib/presentation/pages/flashcard_page.dart` | Authenticated | `artifacts/ui-ux/baseline/13_flashcard_page.png` |
| 11 | **Flashcard Study (Back/Flip)** | `/study/:id` | `lib/presentation/pages/flashcard_page.dart` | Authenticated | `artifacts/ui-ux/baseline/14_flashcard_flipped.png` |
| 12 | **Review Screen (Spelling/Type)** | `/review/:id` | `lib/presentation/pages/review_page.dart` | Authenticated | `artifacts/ui-ux/baseline/15_review_page.png` |
| 13 | **Test Screen** | `/test/:id` | `lib/presentation/pages/test_page.dart` | Authenticated | `artifacts/ui-ux/baseline/16_test_page.png` |

---

## 2. Key User Flows Verified

1. **Authentication Flow:** Login -> Home -> Profile -> Logout -> Login.
2. **Vocabulary Exploration Flow:** Home -> Folder ("1000 Basic English Words") -> Lesson Detail ("1000 BEW - Part 4").
3. **Study & Review Flow:** Lesson Detail -> Flashcard (3D flip front/back) -> Review (interactive letter-spelling) -> Test (assessment).
4. **Spaced Repetition Flow:** Home -> Quick Action "Ôn tập SRS" -> Review flashcards with SM-2 algorithm.
5. **Personal Growth Flow:** Home -> Profile -> Streak tracking -> Activity heatmap -> Theme selection (Dark / Light / System).
