import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_quizlet_mobile_app/core/services/notification_service.dart';

/// Keys for shared_preferences
class _PrefKeys {
  static const String dailyReminderEnabled = 'notif_daily_enabled';
  static const String dailyReminderHour = 'notif_daily_hour';
  static const String dailyReminderMinute = 'notif_daily_minute';
  static const String inactivityEnabled = 'notif_inactivity_enabled';
  static const String streakWarningEnabled = 'notif_streak_enabled';
  static const String srsDueEnabled = 'notif_srs_enabled';
  static const String lastActiveDate = 'notif_last_active';
}

/// Orchestrates when each notification type fires.
/// Reads/writes settings via [SharedPreferences].
class NotificationScheduler {
  final SharedPreferences _prefs;
  final NotificationService _notifService;

  NotificationScheduler({
    required SharedPreferences prefs,
    required NotificationService notifService,
  })  : _prefs = prefs,
        _notifService = notifService;

  // ── Getters ──────────────────────────────────────────────────────────

  bool get isDailyReminderEnabled =>
      _prefs.getBool(_PrefKeys.dailyReminderEnabled) ?? true;

  TimeOfDay get dailyReminderTime => TimeOfDay(
        hour: _prefs.getInt(_PrefKeys.dailyReminderHour) ?? 20,
        minute: _prefs.getInt(_PrefKeys.dailyReminderMinute) ?? 0,
      );

  bool get isInactivityEnabled =>
      _prefs.getBool(_PrefKeys.inactivityEnabled) ?? true;

  bool get isStreakWarningEnabled =>
      _prefs.getBool(_PrefKeys.streakWarningEnabled) ?? true;

  bool get isSrsDueEnabled =>
      _prefs.getBool(_PrefKeys.srsDueEnabled) ?? true;

  // ── Setters & Schedule ───────────────────────────────────────────────

  Future<void> setDailyReminder({
    required bool enabled,
    TimeOfDay? time,
  }) async {
    await _prefs.setBool(_PrefKeys.dailyReminderEnabled, enabled);
    if (time != null) {
      await _prefs.setInt(_PrefKeys.dailyReminderHour, time.hour);
      await _prefs.setInt(_PrefKeys.dailyReminderMinute, time.minute);
    }

    if (enabled) {
      await _notifService.scheduleDailyReminder(time ?? dailyReminderTime);
    } else {
      await _notifService.cancelDailyReminder();
    }
  }

  Future<void> setInactivityReminder(bool enabled) async {
    await _prefs.setBool(_PrefKeys.inactivityEnabled, enabled);
    if (enabled) {
      await _notifService.scheduleInactivityReminder();
    } else {
      await _notifService.cancelInactivityReminder();
    }
  }

  Future<void> setStreakWarning(bool enabled) async {
    await _prefs.setBool(_PrefKeys.streakWarningEnabled, enabled);
    if (enabled) {
      await _notifService.scheduleStreakWarning();
    } else {
      await _notifService.cancelStreakWarning();
    }
  }

  Future<void> setSrsDueReminder(bool enabled) async {
    await _prefs.setBool(_PrefKeys.srsDueEnabled, enabled);
    if (!enabled) {
      await _notifService.cancelSrsDueReminder();
    }
  }

  // ── App lifecycle hooks ──────────────────────────────────────────────

  /// Call when app starts / comes to foreground.
  /// Resets inactivity timer and reschedules all active notifications.
  Future<void> onAppResume() async {
    final now = DateTime.now().toIso8601String();
    await _prefs.setString(_PrefKeys.lastActiveDate, now);

    // Cancel inactivity (user is active now)
    await _notifService.cancelInactivityReminder();

    // Re-schedule inactivity for the future
    if (isInactivityEnabled) {
      await _notifService.scheduleInactivityReminder();
    }
  }

  /// Call after user completes a study session.
  Future<void> onStudySessionCompleted({int srsDueCount = 0}) async {
    // Schedule streak warning (fires at 23:30 if user hasn't studied yet today)
    // We cancel first because user DID study, so streak is safe for today.
    // But tomorrow, reschedule.
    if (isStreakWarningEnabled) {
      await _notifService.scheduleStreakWarning();
    }

    // SRS due reminder
    if (isSrsDueEnabled && srsDueCount > 0) {
      await _notifService.scheduleSrsDueReminder(dueCount: srsDueCount);
    }
  }

  /// Call on first app launch or after re-granting permission.
  /// Applies all currently-saved settings.
  Future<void> applyAllSettings() async {
    if (isDailyReminderEnabled) {
      await _notifService.scheduleDailyReminder(dailyReminderTime);
    }
    if (isInactivityEnabled) {
      await _notifService.scheduleInactivityReminder();
    }
    if (isStreakWarningEnabled) {
      await _notifService.scheduleStreakWarning();
    }
  }
}
