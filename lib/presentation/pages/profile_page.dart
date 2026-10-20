import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/profile/profile_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/activity_heatmap.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/stat_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileBloc>().add(ProfileLoadRequested(authState.user.uid));
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '$seconds giây';
    final mins = seconds ~/ 60;
    if (mins < 60) return '$mins phút';
    final hrs = mins ~/ 60;
    final remainingMins = mins % 60;
    if (remainingMins == 0) return '$hrs giờ';
    return '$hrs giờ $remainingMins phút';
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          title: Text(
            'Đăng xuất tài khoản?',
            style: AppTheme.titleSm(context).copyWith(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
            style: AppTheme.bodyMd(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'HỦY',
                style: AppTheme.labelMd(context).copyWith(color: AppTheme.text3(context)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
              child: const Text(
                'ĐĂNG XUẤT',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeCubit>();
    final authState = context.watch<AuthBloc>().state;
    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          title: Text('Hồ sơ', style: AppTheme.titleSm(context)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: textCol),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.isDark(context)
                        ? const Color(0xFF242424)
                        : AppTheme.surface2(context),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Icon(Icons.lock_outline_rounded, size: 36, color: AppTheme.text3(context))),
                ),
                const SizedBox(height: 20),
                Text('Vui lòng đăng nhập', style: AppTheme.titleLg(context)),
                const SizedBox(height: 8),
                Text('để xem hồ sơ và thống kê học tập', style: AppTheme.bodyMd(context), textAlign: TextAlign.center),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: Text('ĐĂNG NHẬP', style: AppTheme.labelLg(context).copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = authState.user;

    return Scaffold(
      backgroundColor: bg,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Profile Header SliverAppBar ───────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: bg,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2(context).withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_ios_new, size: 16, color: textCol),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  // Notification settings
                  IconButton(
                    tooltip: 'Thông báo',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2(context).withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 18,
                        color: text2Col,
                      ),
                    ),
                    onPressed: () => context.push('/notification-settings'),
                  ),
                  // Logout
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: PressableScale(
                      onTap: () => _showLogoutConfirmation(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.isDark(context)
                              ? const Color(0xFF2A1619)
                              : AppTheme.errorColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                        ),
                        child: Text(
                          'ĐĂNG XUẤT',
                          style: AppTheme.labelSm(context).copyWith(
                            color: AppTheme.errorColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.18),
                          bg,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [accent, AppTheme.accentDark],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                                      style: AppTheme.displayMd(context).copyWith(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.username,
                                        style: AppTheme.titleLg(context).copyWith(fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        user.email,
                                        style: AppTheme.bodyMd(context).copyWith(color: text2Col),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Theme Selector Card ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(
                      context: context,
                      hasShadow: true,
                      hasBorder: true,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.palette_outlined, size: 18, color: accent),
                            const SizedBox(width: 8),
                            Text(
                              'GIAO DIỆN & MÀU SẮC',
                              style: AppTheme.labelMd(context).copyWith(
                                color: text2Col,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<ThemeCubit, ThemeMode>(
                          builder: (context, currentMode) {
                            return Row(
                              children: [
                                _ThemeOptionItem(
                                  label: 'Tối',
                                  icon: Icons.dark_mode_rounded,
                                  isSelected: currentMode == ThemeMode.dark,
                                  onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.dark),
                                ),
                                const SizedBox(width: 8),
                                _ThemeOptionItem(
                                  label: 'Sáng',
                                  icon: Icons.light_mode_rounded,
                                  isSelected: currentMode == ThemeMode.light,
                                  onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.light),
                                ),
                                const SizedBox(width: 8),
                                _ThemeOptionItem(
                                  label: 'Hệ thống',
                                  icon: Icons.settings_brightness_rounded,
                                  isSelected: currentMode == ThemeMode.system,
                                  onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.system),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Body ──────────────────────────────────────
              if (state is ProfileLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is ProfileError)
                SliverFillRemaining(
                  child: Center(child: Text('Lỗi: ${state.message}', style: AppTheme.bodyMd(context))),
                )
              else if (state is ProfileLoaded) ...[
                // Heatmap
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(
                        context: context,
                        hasShadow: true,
                        hasBorder: true,
                      ),
                      child: ActivityHeatmap(dailyActivity: state.dailyActivity),
                    ),
                  ),
                ),

                // Stats header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      'THỐNG KÊ HỌC TẬP',
                      style: AppTheme.labelMd(context).copyWith(color: text2Col),
                    ),
                  ),
                ),

                // Stats content
                if (state.stats == null || state.stats!.totalSessions == 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: AppTheme.cardDecoration(
                          context: context,
                          hasShadow: true,
                          hasBorder: true,
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart_rounded, color: AppTheme.text3(context), size: 36),
                            const SizedBox(height: 12),
                            Text('Chưa có thống kê học tập', style: AppTheme.bodyMd(context)),
                            const SizedBox(height: 4),
                            Text(
                              'Hãy hoàn thành bài học đầu tiên!',
                              style: AppTheme.bodySm(context),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          StatCard(
                            title: 'Tổng số phiên',
                            value: '${state.stats!.totalSessions}',
                            icon: Icons.play_circle_outline_rounded,
                            color: accent,
                          ),
                          const SizedBox(width: 12),
                          StatCard(
                            title: 'Tổng thời gian',
                            value: _formatTime(state.stats!.totalTime),
                            icon: Icons.timer_outlined,
                            color: AppTheme.infoColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Mode detail header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Text(
                        'CHI TIẾT THEO CHẾ ĐỘ',
                        style: AppTheme.labelMd(context).copyWith(color: text2Col),
                      ),
                    ),
                  ),

                  // Mode stats rows
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildModeRow(
                            context: context,
                            title: 'Flashcards',
                            sessions: state.stats!.flashcard.sessions,
                            time: state.stats!.flashcard.totalTime,
                            icon: Icons.layers_outlined,
                            color: AppTheme.infoColor,
                          ),
                          const SizedBox(height: 10),
                          _buildModeRow(
                            context: context,
                            title: 'Ôn tập',
                            sessions: state.stats!.review.sessions,
                            time: state.stats!.review.totalTime,
                            icon: Icons.menu_book_outlined,
                            color: accent,
                          ),
                          const SizedBox(height: 10),
                          _buildModeRow(
                            context: context,
                            title: 'Kiểm tra',
                            sessions: state.stats!.test.sessions,
                            time: state.stats!.test.totalTime,
                            icon: Icons.edit_note_outlined,
                            color: AppTheme.warningColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 36)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeRow({
    required BuildContext context,
    required String title,
    required int sessions,
    required int time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(
        context: context,
        hasShadow: true,
        hasBorder: true,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleSm(context).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '$sessions phiên  •  ${_formatTime(time)}',
                  style: AppTheme.bodySm(context).copyWith(color: AppTheme.text2(context)),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: sessions > 0 ? 1.0 : 0.25),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);
    final surface2 = AppTheme.surface2(context);
    final textCol = AppTheme.text(context);

    final itemBg = isSelected
        ? accent
        : (isDark ? const Color(0xFF242424) : surface2);
    final itemFg = isSelected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? AppTheme.text2(context) : textCol);

    return Expanded(
      child: PressableScale(
        onTap: onTap,
        scaleDown: 0.94,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: itemBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: itemFg,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.bodySm(context).copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: itemFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
