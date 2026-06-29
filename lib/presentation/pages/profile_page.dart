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
        appBar: AppBar(
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
                const Text('🔒', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text('Vui lòng đăng nhập để xem hồ sơ', style: AppTheme.titleLg),
                const SizedBox(height: 8),
                Text('Lịch sử học tập và thống kê sẽ được đồng bộ hóa', style: AppTheme.bodyMd),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Đăng nhập ngay'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
          }
          if (state is ProfileError) {
            return Center(
              child: Text('Lỗi: ${state.message}', style: AppTheme.bodyMd),
            );
          }
          if (state is ProfileLoaded) {
            final stats = state.stats;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.accentColor.withValues(alpha: 0.15),
                          child: Text(
                            user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.username, style: AppTheme.titleLg),
                              const SizedBox(height: 2),
                              Text(user.email, style: AppTheme.bodyMd),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Heatmap Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: ActivityHeatmap(dailyActivity: state.dailyActivity),
                  ),
                  const SizedBox(height: 20),

                  // Summary stats header
                  Text('THỐNG KÊ HỌC TẬP', style: AppTheme.labelMd),
                  const SizedBox(height: 8),

                  if (stats == null || stats.totalSessions == 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: [
                          const Text('📈', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 12),
                          Text('Chưa có thống kê học tập', style: AppTheme.bodyMd),
                          Text('Hãy hoàn thành bài học đầu tiên để lưu lịch sử!',
                              style: AppTheme.bodySm, textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        StatCard(
                          title: 'Tổng số phiên',
                          value: '${stats.totalSessions}',
                          icon: Icons.play_circle_outline,
                          color: AppTheme.accentColor,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          title: 'Tổng thời gian',
                          value: _formatTime(stats.totalTime),
                          icon: Icons.timer_outlined,
                          color: const Color(0xFF60A5FA),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('CHI TIẾT THEO CHẾ ĐỘ', style: AppTheme.labelMd),
                    const SizedBox(height: 8),
                    _buildModeStatsRow(
                      title: 'Flashcards',
                      sessions: stats.flashcard.sessions,
                      time: stats.flashcard.totalTime,
                      icon: Icons.layers_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 8),
                    _buildModeStatsRow(
                      title: 'Ôn tập (Review)',
                      sessions: stats.review.sessions,
                      time: stats.review.totalTime,
                      icon: Icons.menu_book_outlined,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(height: 8),
                    _buildModeStatsRow(
                      title: 'Kiểm tra (Test)',
                      sessions: stats.test.sessions,
                      time: stats.test.totalTime,
                      icon: Icons.edit_note_outlined,
                      color: AppTheme.accentColor,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildModeStatsRow({
    required String title,
    required int sessions,
    required int time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleMd.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '$sessions phiên học  •  ${_formatTime(time)}',
                  style: AppTheme.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
