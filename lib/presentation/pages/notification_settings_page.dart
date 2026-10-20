import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/core/services/notification_scheduler.dart';
import 'package:simple_quizlet_mobile_app/core/services/notification_service.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late final NotificationScheduler _scheduler;
  bool _permissionGranted = false;
  bool _isLoading = true;

  // Local state mirrors
  late bool _dailyEnabled;
  late TimeOfDay _dailyTime;
  late bool _inactivityEnabled;
  late bool _streakEnabled;
  late bool _srsEnabled;

  @override
  void initState() {
    super.initState();
    _scheduler = injector<NotificationScheduler>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final granted = await NotificationService.instance.requestPermission();
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _dailyEnabled = _scheduler.isDailyReminderEnabled;
      _dailyTime = _scheduler.dailyReminderTime;
      _inactivityEnabled = _scheduler.isInactivityEnabled;
      _streakEnabled = _scheduler.isStreakWarningEnabled;
      _srsEnabled = _scheduler.isSrsDueEnabled;
      _isLoading = false;
    });
  }

  Future<void> _pickTime() async {
    final accent = AppTheme.accent(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme(
            brightness: Theme.of(context).brightness,
            primary: accent,
            onPrimary: Colors.white,
            secondary: accent,
            onSecondary: Colors.white,
            error: AppTheme.errorColor,
            onError: Colors.white,
            surface: AppTheme.surface(context),
            onSurface: AppTheme.text(context),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppTheme.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dailyTime = picked);
      await _scheduler.setDailyReminder(enabled: _dailyEnabled, time: picked);
    }
  }

  Future<void> _showTestNotification() async {
    await NotificationService.instance.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thông báo kiểm tra đã được gửi!'),
          backgroundColor: AppTheme.accent(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bg(context);
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);
    final accent = AppTheme.accent(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Thông báo',
          style: AppTheme.titleSm(context).copyWith(
            fontWeight: FontWeight.w700,
            color: textCol,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surface2(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: textCol),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // ── Permission warning ─────────────────────────────
                if (!_permissionGranted) ...[
                  _buildWarningBanner(),
                  const SizedBox(height: 16),
                ],

                // ── Section: Daily Reminder ────────────────────────
                _buildSectionHeader('NHẮC HỌC HÀNG NGÀY'),
                const SizedBox(height: 8),
                _buildCard(
                  children: [
                    _buildToggleRow(
                      id: 'toggle_daily_reminder',
                      icon: Icons.alarm_rounded,
                      iconColor: accent,
                      title: 'Nhắc học mỗi ngày',
                      subtitle: 'Nhận nhắc nhở ôn luyện từ vựng hàng ngày',
                      value: _dailyEnabled,
                      onChanged: (v) async {
                        setState(() => _dailyEnabled = v);
                        await _scheduler.setDailyReminder(
                          enabled: v,
                          time: _dailyTime,
                        );
                      },
                    ),
                    if (_dailyEnabled) ...[
                      _buildDivider(),
                      _buildTimePickerRow(),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // ── Section: Smart Reminders ───────────────────────
                _buildSectionHeader('THÔNG BÁO THÔNG MINH'),
                const SizedBox(height: 8),
                _buildCard(
                  children: [
                    _buildToggleRow(
                      id: 'toggle_inactivity',
                      icon: Icons.history_rounded,
                      iconColor: AppTheme.infoColor,
                      title: 'Nhắc khi lâu không học',
                      subtitle: 'Nhận thông báo nếu bạn chưa mở app sau 3 ngày',
                      value: _inactivityEnabled,
                      onChanged: (v) async {
                        setState(() => _inactivityEnabled = v);
                        await _scheduler.setInactivityReminder(v);
                      },
                    ),
                    _buildDivider(),
                    _buildToggleRow(
                      id: 'toggle_streak',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppTheme.warningColor,
                      title: 'Cảnh báo mất streak',
                      subtitle: 'Nhắc lúc 23:30 nếu chưa hoàn thành bài học trong ngày',
                      value: _streakEnabled,
                      onChanged: (v) async {
                        setState(() => _streakEnabled = v);
                        await _scheduler.setStreakWarning(v);
                      },
                    ),
                    _buildDivider(),
                    _buildToggleRow(
                      id: 'toggle_srs',
                      icon: Icons.style_rounded,
                      iconColor: AppTheme.infoColor,
                      title: 'Nhắc ôn tập SRS',
                      subtitle: 'Thông báo khi có thẻ từ vựng đến hạn ôn tập',
                      value: _srsEnabled,
                      onChanged: (v) async {
                        setState(() => _srsEnabled = v);
                        await _scheduler.setSrsDueReminder(v);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Test notification ──────────────────────────────
                _buildSectionHeader('KIỂM TRA'),
                const SizedBox(height: 8),
                _buildCard(
                  children: [
                    PressableScale(
                      onTap: _showTestNotification,
                      scaleDown: 0.98,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Icon(
                                Icons.notifications_active_rounded,
                                color: accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gửi thông báo thử',
                                    style: AppTheme.titleSm(context).copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: textCol,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kiểm tra xem thông báo có hiển thị trên máy không',
                                    style: AppTheme.bodySm(context).copyWith(
                                      color: text2Col,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.text3(context),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // ── Build Helpers ─────────────────────────────────────────────────────

  Widget _buildWarningBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2413) : AppTheme.warningColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: !isDark
            ? Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.35),
              )
            : null,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Quyền thông báo chưa được cấp. Vào Cài đặt hệ thống để bật.',
              style: AppTheme.bodySm(context).copyWith(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.labelSm(context).copyWith(
        color: AppTheme.text3(context),
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: AppTheme.cardDecoration(
        context: context,
        hasShadow: true,
        hasBorder: true,
        radius: AppTheme.radiusMd,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 16,
      endIndent: 16,
      color: isDark ? const Color(0xFF242424) : AppTheme.border(context),
    );
  }

  Widget _buildToggleRow({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final accent = AppTheme.accent(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleSm(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.bodySm(context).copyWith(
                    color: AppTheme.text2(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: Key(id),
            value: value,
            onChanged: onChanged,
            activeThumbColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.35),
            inactiveThumbColor: AppTheme.text3(context),
            inactiveTrackColor: AppTheme.surface3(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerRow() {
    final accent = AppTheme.accent(context);

    return InkWell(
      onTap: _pickTime,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface2(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: AppTheme.text2(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giờ nhắc học',
                    style: AppTheme.titleSm(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thông báo sẽ đến lúc ${_formatTime(_dailyTime)} mỗi ngày',
                    style: AppTheme.bodySm(context).copyWith(
                      color: AppTheme.text2(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: AppTheme.pillDecoration(
                context: context,
                background: accent.withValues(alpha: 0.12),
                border: accent.withValues(alpha: 0.4),
              ),
              child: Text(
                _formatTime(_dailyTime),
                style: AppTheme.labelSm(context).copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
