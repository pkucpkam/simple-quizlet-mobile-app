import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/srs_card_entity.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/srs/srs_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/flip_card_widget.dart';

class SrsReviewPage extends StatelessWidget {
  final String? lessonId;
  const SrsReviewPage({super.key, this.lessonId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SrsBloc>(
      create: (context) {
        final bloc = injector<SrsBloc>();
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          bloc.add(SrsLoadRequested(
            userId: authState.user.uid,
            lessonId: lessonId,
          ));
        }
        return bloc;
      },
      child: const _SrsReviewView(),
    );
  }
}

class _SrsReviewView extends StatelessWidget {
  const _SrsReviewView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SrsBloc, SrsState>(
      listener: (context, state) {
        if (state is SrsCatchupRequired) {
          _showCatchupModal(context, state);
        }
      },
      builder: (context, state) {
        if (state is SrsLoading || state is SrsInitial) {
          return Scaffold(
            backgroundColor: AppTheme.bgColor,
            appBar: AppBar(
              backgroundColor: AppTheme.bgColor,
              title: const Text('Ôn tập SRS'),
            ),
            body: const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
          );
        }

        if (state is SrsError) {
          return Scaffold(
            backgroundColor: AppTheme.bgColor,
            appBar: AppBar(backgroundColor: AppTheme.bgColor, title: const Text('Ôn tập SRS')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 48),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${state.message}', style: AppTheme.bodyMd),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is AuthAuthenticated) {
                        context.read<SrsBloc>().add(SrsLoadRequested(userId: authState.user.uid));
                      }
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is SrsCompleted) {
          return _buildCompletion(context, state);
        }

        if (state is SrsReady) {
          return _buildStudyScreen(context, state);
        }

        return const Scaffold(backgroundColor: AppTheme.bgColor);
      },
    );
  }

  void _showCatchupModal(BuildContext context, SrsCatchupRequired state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.warningColor, size: 24),
                  const SizedBox(width: 8),
                  Text('Quá nhiều thẻ đến hạn!', style: AppTheme.titleLg),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn có ${state.dueCards.length} thẻ cần ôn hôm nay. Bạn muốn chia nhỏ ra học trước hay ôn tất cả?',
                style: AppTheme.bodyMd,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(modalCtx);
                    context.read<SrsBloc>().add(SrsLoadRequested(
                          userId: state.userId,
                          maxCards: 20,
                        ));
                  },
                  child: const Text('Học 20 thẻ trước (Khuyên dùng)'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(modalCtx);
                    context.read<SrsBloc>().add(SrsLoadRequested(
                          userId: state.userId,
                          maxCards: state.dueCards.length,
                        ));
                  },
                  child: Text('Học tất cả (${state.dueCards.length} thẻ)'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudyScreen(BuildContext context, SrsReady state) {
    final card = state.currentCard;
    final total = state.totalInitialCount;
    final progress = total > 0 ? state.correctCount / total : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Còn lại ${state.queue.length} thẻ',
          style: AppTheme.titleSm,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surface3Color,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 12),

            // Header Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 16),
                    const SizedBox(width: 4),
                    Text('${state.correctCount} đúng', style: AppTheme.bodySm.copyWith(color: AppTheme.successColor)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.highlight_off_rounded, color: AppTheme.errorColor, size: 16),
                    const SizedBox(width: 4),
                    Text('${state.incorrectCount} sai', style: AppTheme.bodySm.copyWith(color: AppTheme.errorColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Flip Card Widget
            Expanded(
              child: FlipCardWidget(
                isFlipped: state.isFlipped,
                onFlip: () => context.read<SrsBloc>().add(SrsFlipCard()),
                front: _buildFrontContent(card),
                back: _buildBackContent(card),
              ),
            ),
            const SizedBox(height: 20),

            // Controls / Ratings
            if (!state.isFlipped)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.read<SrsBloc>().add(SrsFlipCard()),
                  icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.black),
                  label: Text('HIỆN ĐÁP ÁN', style: AppTheme.labelLg.copyWith(color: Colors.black)),
                ),
              )
            else
              Row(
                children: [
                  _RatingButton(
                    label: 'AGAIN',
                    sub: '<1 phút',
                    color: AppTheme.errorColor,
                    onTap: () => context.read<SrsBloc>().add(SrsCardReviewed(ReviewRating.again)),
                  ),
                  const SizedBox(width: 8),
                  _RatingButton(
                    label: 'HARD',
                    sub: 'Khó',
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.read<SrsBloc>().add(SrsCardReviewed(ReviewRating.hard)),
                  ),
                  const SizedBox(width: 8),
                  _RatingButton(
                    label: 'GOOD',
                    sub: 'Tốt',
                    color: AppTheme.successColor,
                    onTap: () => context.read<SrsBloc>().add(SrsCardReviewed(ReviewRating.good)),
                  ),
                  const SizedBox(width: 8),
                  _RatingButton(
                    label: 'EASY',
                    sub: 'Dễ',
                    color: const Color(0xFF3B82F6),
                    onTap: () => context.read<SrsBloc>().add(SrsCardReviewed(ReviewRating.easy)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontContent(SrsCardEntity card) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.word,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Nhấn card để xem nghĩa',
            style: AppTheme.bodySm.copyWith(color: AppTheme.text3Color),
          ),
        ],
      ),
    );
  }

  Widget _buildBackContent(SrsCardEntity card) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.definition,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface2Color,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              'Streak: ${card.streak}🔥  •  Interval: ${card.interval} ngày',
              style: AppTheme.bodySm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletion(BuildContext context, SrsCompleted state) {
    final pct = state.totalCards > 0 ? (state.correctCount / state.totalCards * 100).round() : 100;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(backgroundColor: AppTheme.bgColor, title: const Text('Hoàn thành SRS')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pct >= 80 ? '🎉' : '👍',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text('Hoàn thành ôn tập!', style: AppTheme.displayMd),
              const SizedBox(height: 8),
              Text('Bạn đã ôn ${state.totalCards} thẻ SRS', style: AppTheme.bodyMd),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text('${state.correctCount}', style: AppTheme.displayMd.copyWith(color: AppTheme.successColor)),
                          const SizedBox(height: 4),
                          Text('ĐÚNG', style: AppTheme.labelSm.copyWith(color: AppTheme.successColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text('${state.incorrectCount}', style: AppTheme.displayMd.copyWith(color: AppTheme.errorColor)),
                          const SizedBox(height: 4),
                          Text('CẦN ÔN LẠI', style: AppTheme.labelSm.copyWith(color: AppTheme.errorColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Trở về'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
