import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/profile/profile_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/activity_heatmap.dart';
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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          backgroundColor: AppTheme.bgColor,
          title: const Text('Hồ sơ'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
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
                    color: AppTheme.surface2Color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Center(child: Icon(Icons.lock_outline_rounded, size: 36, color: AppTheme.text3Color)),
                ),
                const SizedBox(height: 20),
                Text('Vui lòng đăng nhập', style: AppTheme.titleLg),
                const SizedBox(height: 8),
                Text('để xem hồ sơ và thống kê học tập', style: AppTheme.bodyMd, textAlign: TextAlign.center),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: Text('ĐĂNG NHẬP', style: AppTheme.labelLg.copyWith(color: Colors.black)),
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
      backgroundColor: AppTheme.bgColor,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // ── Profile Header SliverAppBar ───────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.bgColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2Color.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppTheme.textColor),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  // Logout
                  GestureDetector(
                    onTap: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                      context.go('/login');
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: AppTheme.pillDecoration(
                        background: AppTheme.errorColor.withValues(alpha: 0.1),
                        border: AppTheme.errorColor.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        'ĐĂNG XUẤT',
                        style: AppTheme.labelSm.copyWith(color: AppTheme.errorColor, fontSize: 10),
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
                          AppTheme.accentColor.withValues(alpha: 0.12),
                          AppTheme.bgColor,
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
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [AppTheme.accentColor, AppTheme.accentDark],
                                    ),
                                    boxShadow: AppTheme.shadowGreen,
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                                      style: AppTheme.displayMd.copyWith(
                                        color: Colors.black,
                                        fontSize: 26,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.username, style: AppTheme.titleLg),
                                      const SizedBox(height: 4),
                                      Text(user.email, style: AppTheme.bodyMd),
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

              // ── Body ──────────────────────────────────────
              if (state is ProfileLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is ProfileError)
                SliverFillRemaining(
                  child: Center(child: Text('Lỗi: ${state.message}', style: AppTheme.bodyMd)),
                )
              else if (state is ProfileLoaded) ...[
                // Heatmap
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(hasShadow: true),
                      child: ActivityHeatmap(dailyActivity: state.dailyActivity),
                    ),
                  ),
                ),

                // Stats header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text('THỐNG KÊ HỌC TẬP', style: AppTheme.labelMd),
                  ),
                ),

                // Stats content
                if (state.stats == null || state.stats!.totalSessions == 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: AppTheme.cardDecoration(hasShadow: true),
                        child: Column(
                          children: [
                            const Icon(Icons.bar_chart_rounded, color: AppTheme.text3Color, size: 36),
                            const SizedBox(height: 12),
                            Text('Chưa có thống kê học tập', style: AppTheme.bodyMd),
                            const SizedBox(height: 4),
                            Text(
                              'Hãy hoàn thành bài học đầu tiên!',
                              style: AppTheme.bodySm,
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
                            color: AppTheme.accentColor,
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
                      child: Text('CHI TIẾT THEO CHẾ ĐỘ', style: AppTheme.labelMd),
                    ),
                  ),

                  // Mode stats rows
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildModeRow(
                            title: 'Flashcards',
                            sessions: state.stats!.flashcard.sessions,
                            time: state.stats!.flashcard.totalTime,
                            icon: Icons.layers_outlined,
                            color: AppTheme.infoColor,
                          ),
                          const SizedBox(height: 8),
                          _buildModeRow(
                            title: 'Ôn tập',
                            sessions: state.stats!.review.sessions,
                            time: state.stats!.review.totalTime,
                            icon: Icons.menu_book_outlined,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(height: 8),
                          _buildModeRow(
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
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeRow({
    required String title,
    required int sessions,
    required int time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(hasShadow: true),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleSm),
                const SizedBox(height: 2),
                Text(
                  '$sessions phiên  •  ${_formatTime(time)}',
                  style: AppTheme.bodySm,
                ),
              ],
            ),
          ),
          // Progress dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: sessions > 0 ? 1.0 : 0.2),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
