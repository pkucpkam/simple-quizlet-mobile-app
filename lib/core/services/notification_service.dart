import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notification IDs — unique per type
class NotificationIds {
  static const int dailyReminder = 1;
  static const int inactivityReminder = 2;
  static const int streakWarning = 3;
  static const int srsDue = 4;
}

/// Channel IDs
class NotificationChannels {
  static const String studyReminder = 'study_reminder';
  static const String streakAlert = 'streak_alert';
  static const String srsReview = 'srs_review';
}

/// Central service for all local push notifications.
/// Singleton — call [init] once at app start.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Init ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    const studyChannel = AndroidNotificationChannel(
      NotificationChannels.studyReminder,
      'Nhac hoc',
      description: 'Nhac nho hoc tu vung hang ngay',
      importance: Importance.high,
    );
    const streakChannel = AndroidNotificationChannel(
      NotificationChannels.streakAlert,
      'Canh bao streak',
      description: 'Canh bao khi streak sap bi mat',
      importance: Importance.max,
    );
    const srsChannel = AndroidNotificationChannel(
      NotificationChannels.srsReview,
      'On tap SRS',
      description: 'Thong bao khi co the can on tap',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(studyChannel);
    await androidPlugin?.createNotificationChannel(streakChannel);
    await androidPlugin?.createNotificationChannel(srsChannel);
  }

  void _onNotificationTap(NotificationResponse response) {}

  // ── Permission ───────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final androidGranted =
        await androidPlugin?.requestNotificationsPermission() ?? true;
    final iosGranted =
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    return androidGranted && iosGranted;
  }

  // ── 1. Daily Reminder ────────────────────────────────────────────────

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _plugin.cancel(NotificationIds.dailyReminder);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      NotificationIds.dailyReminder,
      'Den gio hoc roi!',
      'Hom nay ban da hoc tu vung chua? Chi 5 phut thoi!',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.studyReminder,
          'Nhac hoc',
          channelDescription: 'Nhac nho hoc tu vung hang ngay',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(NotificationIds.dailyReminder);
  }

  // ── 2. Inactivity Reminder ───────────────────────────────────────────

  Future<void> scheduleInactivityReminder({int daysThreshold = 3}) async {
    await _plugin.cancel(NotificationIds.inactivityReminder);

    final triggerTime =
        tz.TZDateTime.now(tz.local).add(Duration(days: daysThreshold));

    await _plugin.zonedSchedule(
      NotificationIds.inactivityReminder,
      'Ban co on khong?',
      '$daysThreshold ngay roi ban chua hoc. Quay lai nao!',
      triggerTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.studyReminder,
          'Nhac hoc',
          channelDescription: 'Nhac nho hoc tu vung hang ngay',
          importance: Importance.high,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelInactivityReminder() async {
    await _plugin.cancel(NotificationIds.inactivityReminder);
  }

  // ── 3. Streak Warning ────────────────────────────────────────────────

  Future<void> scheduleStreakWarning() async {
    await _plugin.cancel(NotificationIds.streakWarning);

    final now = tz.TZDateTime.now(tz.local);
    var trigger =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 23, 30);

    if (trigger.isBefore(now)) {
      trigger = trigger.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      NotificationIds.streakWarning,
      'Streak sap mat!',
      'Con 30 phut nua la het ngay. Hoc ngay de giu streak!',
      trigger,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.streakAlert,
          'Canh bao streak',
          channelDescription: 'Canh bao khi streak sap bi mat',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFFA42B),
          enableLights: true,
          ledColor: const Color(0xFFFFA42B),
          ledOnMs: 500,
          ledOffMs: 500,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelStreakWarning() async {
    await _plugin.cancel(NotificationIds.streakWarning);
  }

  // ── 4. SRS Due Reminder ──────────────────────────────────────────────

  Future<void> scheduleSrsDueReminder({
    required int dueCount,
    int delayMinutes = 60,
  }) async {
    if (dueCount <= 0) return;
    await _plugin.cancel(NotificationIds.srsDue);

    final triggerTime =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: delayMinutes));

    await _plugin.zonedSchedule(
      NotificationIds.srsDue,
      'Co $dueCount the can on!',
      'Dung de kien thuc bi quen. On tap ngay trong 5 phut!',
      triggerTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.srsReview,
          'On tap SRS',
          channelDescription: 'Thong bao khi co the can on tap',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelSrsDueReminder() async {
    await _plugin.cancel(NotificationIds.srsDue);
  }

  // ── Utilities ────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> showTestNotification() async {
    await _plugin.show(
      99,
      'Thong bao hoat dong!',
      'SimpleQuizlet se nhac ban hoc moi ngay.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.studyReminder,
          'Nhac hoc',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }
}
