import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/core/services/notification_scheduler.dart';
import 'package:simple_quizlet_mobile_app/core/services/notification_service.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';

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
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accentColor,
            onPrimary: Colors.black,
            surface: AppTheme.surface2Color,
            onSurface: AppTheme.textColor,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppTheme.surfaceColor,
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
        const SnackBar(
          content: Text('Thong bao kiem tra da duoc gui!'),
          duration: Duration(seconds: 2),
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
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor,
        title: const Text('Thong bao'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Permission warning ─────────────────────────────
                if (!_permissionGranted) ...[
                  _buildWarningBanner(),
                  const SizedBox(height: 16),
                ],

                // ── Section: Daily Reminder ────────────────────────
                _buildSectionHeader('NHAC HOC HANG NGAY'),
                const SizedBox(height: 8),
                _buildCard(
                  children: [
                    _buildToggleRow(
                      id: 'toggle_daily_reminder',
                      icon: Icons.alarm_rounded,
                      iconColor: AppTheme.accentColor,
                      title: 'Nhac hoc moi ngay',
                      subtitle: 'Nhan nhac nho hoc tu vung hang ngay',
                      value: _dailyEnabled,
                      onChanged: (v) async {
                        setState(() => _dailyEnabled = v);
                        await _scheduler.setDailyReminder(
                            enabled: v, time: _dailyTime);
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
                _buildSectionHeader('THONG BAO THONG MINH'),
                const SizedBox(height: 8),
                _buildCard(
                  children: [
                    _buildToggleRow(
                      id: 'toggle_inactivity',
                      icon: Icons.history_rounded,
                      iconColor: AppTheme.infoColor,
                      title: 'Nhac khi lau khong hoc',
                      subtitle: 'Nhan thong bao neu ban khong mo app sau 3 ngay',
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
                      title: 'Canh bao streak',
                      subtitle: 'Nhac luc 23:30 neu chua hoc trong ngay',
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
                      title: 'Nhac on tap SRS',
                      subtitle: 'Thong bao khi co the tu vung can on tap',
                      value: _srsEnabled,
                      onChanged: (v) async {
                        setState(() => _srsEnabled = v);
                        await _scheduler.setSrsDueReminder(v);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Test notification ──────────────────────────────
                _buildSectionHeader('KIEM TRA'),
                const SizedBox(height: 8),
                _buildCard(
                  children: [
                    InkWell(
                      onTap: _showTestNotification,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: AppTheme.accentColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Gui thong bao thu', style: AppTheme.titleSm),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kiem tra xem thong bao co hien thi khong',
                                    style: AppTheme.bodySm,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.text3Color,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Quyen thong bao chua duoc cap. Vao Cai dat he thong de bat.',
              style: AppTheme.bodySm.copyWith(color: AppTheme.warningColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTheme.labelMd);
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: AppTheme.cardDecoration(hasShadow: true, hasBorder: true),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleSm),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.bodySm),
              ],
            ),
          ),
          Switch(
            key: Key(id),
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.accentColor,
            activeTrackColor: AppTheme.accentColor.withValues(alpha: 0.3),
            inactiveThumbColor: AppTheme.text3Color,
            inactiveTrackColor: AppTheme.surface3Color,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerRow() {
    return InkWell(
      onTap: _pickTime,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface3Color,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: AppTheme.text2Color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gio nhac hoc', style: AppTheme.titleSm),
                  const SizedBox(height: 2),
                  Text(
                    'Thong bao se den luc ${_formatTime(_dailyTime)} moi ngay',
                    style: AppTheme.bodySm,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: AppTheme.pillDecoration(
                background: AppTheme.accentColor.withValues(alpha: 0.1),
                border: AppTheme.accentColor.withValues(alpha: 0.4),
              ),
              child: Text(
                _formatTime(_dailyTime),
                style: AppTheme.labelSm.copyWith(color: AppTheme.accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
