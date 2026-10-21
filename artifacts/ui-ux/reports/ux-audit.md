# Professional Mobile UI/UX & Quality Audit

**Date:** 2026-10-20  
**Application:** Simple Quizlet Mobile App  
**Device:** MuMu Android Emulator (SM A156E, Android 12, 900x1600 Physical, ~400dpi)  
**Agent:** Senior Flutter Engineer & Mobile Product Designer (`mobile-developer`)

---

## 1. Executive Summary

A comprehensive, real-device audit was conducted on the MuMu Emulator. The application features a strong baseline aesthetic inspired by modern Spotify dark interfaces (OLED black, emerald green `#1ED760`, clean typography, 3D card flips, and streak heatmaps). 

However, live user interaction on the emulator revealed several critical and high-priority UX, architectural, and visual defects that significantly hurt usability:
1. **Critical P0 Route Loop:** Tapping "ĐĂNG XUẤT" or navigating to notification settings triggers an unhandled `GoException: redirect loop detected /login => / => / => /login` due to async race conditions between GoRouter's route redirect and Firebase Auth state changes.
2. **Critical P0 Accidental Logout UX:** The "ĐĂNG XUẤT" button on `ProfilePage` is positioned in the top toolbar with no confirmation dialog. Any misclick immediately signs out the user into the crash loop.
3. **High P1 Awkward Letter Slot Wrapping:** On `ReviewPage` (Practice / Typing mode), fixed 38dp width slots with 8dp spacing break words longer than 8 letters awkwardly across lines (e.g. 8 boxes on row 1, 1 lonely box on row 2 for "scrubbing").
4. **High P1 Dark/Light Theme Inconsistencies:** `NotificationSettingsPage`, `LoginPage`, and `RegisterPage` rely on hardcoded static colors (`AppTheme.bgColor`, `AppTheme.textColor`) rather than dynamic theme helpers (`AppTheme.bg(context)`). In Light Mode, these pages remain black or present illegible contrast.
5. **Medium P2 Localization & Copy:** `NotificationSettingsPage` contains unaccented Vietnamese ("Thong bao", "Thong bao kiem tra da duoc gui!") inconsistent with the rest of the application.
6. **Medium P2 Interaction Feedback & Haptics:** Flashcards lack smooth swipe gestures (swipe left for "Cần ôn", swipe right for "Đã thuộc") and subtle tactile haptics on card flip and answer selection.

---

## 2. Detailed Findings & Severity Matrix

### P0 — Critical Functional / Navigation Failure

#### Defect 1: GoRouter Redirect Loop on Auth State Change
- **Location:** `lib/presentation/router/app_router.dart`, `lib/presentation/pages/profile_page.dart`
- **Symptom:** App shows a black error screen:  
  `Page Not Found`  
  `GoException: redirect loop detected /login => / => / => /login`
- **Root Cause:**
  - `appRouter`'s `redirect` callback executes an async Firestore fetch (`await authRepo.getCurrentUser()`) on every navigation transition.
  - When `ProfilePage` triggers `context.read<AuthBloc>().add(AuthLogoutRequested())` and immediately calls `context.go('/login')`, `_auth.currentUser` is still temporarily valid in memory. GoRouter aborts the login transition and pushes back to `/`. As soon as `/` evaluates, the async signOut completes and GoRouter bounces back to `/login`, creating an infinite ping-pong loop.
  - Additionally, `appRouter` lacks `refreshListenable` bound to `authRepo.authStateChanges`.
- **Impact:** Complete UX blocker. The user gets stuck on an unrecoverable error screen until they manually kill and restart the app.
- **Remediation:**
  1. Add a synchronous `isAuthenticated` getter to `AuthRepository` & `AuthRemoteDataSource` (`_auth.currentUser != null`).
  2. Implement `GoRouterRefreshStream` listening to `authStateChanges` as `refreshListenable` in `GoRouter`.
  3. Change `redirect` to synchronous evaluation, preventing race conditions and route bouncing.
  4. Replace immediate `context.go('/login')` with automated reactive redirection.

#### Defect 2: Immediate Irreversible Logout Without Confirmation
- **Location:** `lib/presentation/pages/profile_page.dart` (Line 140)
- **Symptom:** Tapping the red "ĐĂNG XUẤT" pill button at the top-right instantly terminates user session without any warning or confirmation.
- **Impact:** High error frequency. Users tapping near the top right (close to the notification bell) lose session and must re-enter credentials.
- **Remediation:**
  - Add a modern modal bottom sheet / alert dialog: "Đăng xuất khỏi tài khoản?" with clear "Hủy" and "Đăng xuất" actions.

---

### P1 — Major Usability & Visual Defects

#### Defect 3: Review Page Practice Mode Slot Layout Fragmentation
- **Location:** `lib/presentation/pages/review_page.dart` (`_PracticeMode`)
- **Symptom:** Letter input boxes have a hardcoded size of `38dp` with `Wrap(spacing: 8)`. Words with 9+ letters (e.g., "scrubbing", "department", "institutions") break into 8 boxes on row 1 and 1 box on row 2, destroying readability and touch ergonomics.
- **Impact:** Cluttered layout, looks unpolished and buggy.
- **Remediation:**
  - Introduce `LayoutBuilder` with adaptive slot sizing:
    `slotWidth = ((availableWidth - (charsCount - 1) * spacing) / charsCount).clamp(24.0, 42.0)`.
  - For multi-word phrases (e.g. "financial institutions"), split and group boxes word-by-word into coherent rows.

#### Defect 4: Theme Inconsistency on Form and Settings Pages
- **Location:** `lib/presentation/pages/notification_settings_page.dart`, `login_page.dart`, `register_page.dart`
- **Symptom:** Hardcoded static colors (`AppTheme.bgColor`, `AppTheme.textColor`, `AppTheme.surfaceColor`) bypass `ThemeCubit`. Light mode users see dark backgrounds or mismatched styling.
- **Impact:** Broken dark/light theme experience across 3 screens.
- **Remediation:**
  - Replace static color references with context-aware helpers (`AppTheme.bg(context)`, `AppTheme.surface(context)`, `AppTheme.text(context)`).

---

### P2 — Polish & Interaction Refinements

#### Defect 5: Unaccented Vietnamese Strings in Notification Settings
- **Location:** `lib/presentation/pages/notification_settings_page.dart`
- **Symptom:** Texts like `Thong bao`, `Thong bao kiem tra da duoc gui!` are missing Vietnamese accents.
- **Remediation:** Update strings to proper Vietnamese diacritics: `Thông báo`, `Thông báo kiểm tra đã được gửi!`.

#### Defect 6: Touch Gestures & Haptic Feedback on Study Cards
- **Location:** `lib/presentation/pages/flashcard_page.dart`, `srs_review_page.dart`
- **Symptom:** Cards only support tap to flip. Swiping left/right does not trigger "Cần ôn" or "Đã thuộc".
- **Remediation:**
  - Enhance card interaction with horizontal drag / swipe gestures and subtle haptic feedback (`HapticFeedback.lightImpact()` / `selectionClick()`).

---

## 3. Prioritized Implementation Plan

1. **Phase 4 & 5 (Core Routing & Architecture):**
   - Fix `AuthRepository` & `AuthRemoteDataSource` synchronous `isAuthenticated`.
   - Upgrade `app_router.dart` with `refreshListenable` & synchronous zero-latency redirect.
   - Add modern logout confirmation dialog in `profile_page.dart`.
2. **Phase 5 & 6 (Review & Learning Experience):**
   - Redesign `_PracticeMode` letter slots with adaptive sizing and phrase-aware word wrapping.
   - Refactor `NotificationSettingsPage` to full dynamic theme + correct Vietnamese copy.
   - Refactor `LoginPage` and `RegisterPage` with dynamic theme and smoother input animations.
3. **Phase 7 (Automated User Journey Tests):**
   - Configure `integration_test` and create full user journey tests.
4. **Phase 8 & 9 (Verification & Performance):**
   - Hot reload & rebuild on MuMu Emulator (`127.0.0.1:7555`).
   - Capture "After" screenshots of every modified screen into `artifacts/ui-ux/after/`.
   - Produce comparison reports and log metrics.
