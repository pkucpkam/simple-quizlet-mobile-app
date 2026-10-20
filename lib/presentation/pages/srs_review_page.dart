import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/srs_card_entity.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/srs/srs_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/flip_card_widget.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';

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
    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);

    return BlocConsumer<SrsBloc, SrsState>(
      listener: (context, state) {
        if (state is SrsCatchupRequired) {
          _showCatchupModal(context, state);
        }
      },
      builder: (context, state) {
        if (state is SrsLoading || state is SrsInitial) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              title: Text('Ôn tập SRS', style: AppTheme.titleSm(context)),
            ),
            body: Center(child: CircularProgressIndicator(color: accent)),
          );
        }

        if (state is SrsError) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              title: Text('Ôn tập SRS', style: AppTheme.titleSm(context)),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 52),
                  const SizedBox(height: 14),
                  Text('Lỗi: ${state.message}', style: AppTheme.bodyMd(context)),
                  const SizedBox(height: 18),
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

        return Scaffold(backgroundColor: bg);
      },
    );
  }

  void _showCatchupModal(BuildContext context, SrsCatchupRequired state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
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
                  Text('Quá nhiều thẻ đến hạn!', style: AppTheme.titleLg(context)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn có ${state.dueCards.length} thẻ cần ôn hôm nay. Bạn muốn chia nhỏ ra học trước hay ôn tất cả?',
                style: AppTheme.bodyMd(context),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
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
                height: 50,
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
    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);
    final textCol = AppTheme.text(context);
    final surface3 = AppTheme.surface3(context);

    final card = state.currentCard;
    final total = state.totalInitialCount;
    final progress = total > 0 ? state.correctCount / total : 0.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, size: 24, color: textCol),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Còn lại ${state.queue.length} thẻ',
          style: AppTheme.titleSm(context).copyWith(color: textCol, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: surface3,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
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
                      Icon(Icons.check_circle_outline, color: accent, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        '${state.correctCount} đúng',
                        style: AppTheme.bodySm(context).copyWith(color: accent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.highlight_off_rounded, color: AppTheme.errorColor, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        '${state.incorrectCount} sai',
                        style: AppTheme.bodySm(context).copyWith(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Flip Card Widget
              Expanded(
                child: FlipCardWidget(
                  isFlipped: state.isFlipped,
                  onFlip: () => context.read<SrsBloc>().add(SrsFlipCard()),
                  front: _buildFrontContent(context, card),
                  back: _buildBackContent(context, card),
                ),
              ),
              const SizedBox(height: 20),

              // Controls / Ratings
              if (!state.isFlipped)
                PressableScale(
                  onTap: () => context.read<SrsBloc>().add(SrsFlipCard()),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.visibility_outlined, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'HIỆN ĐÁP ÁN',
                            style: AppTheme.labelLg(context).copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
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
                      color: AppTheme.warningColor,
                      onTap: () => context.read<SrsBloc>().add(SrsCardReviewed(ReviewRating.hard)),
                    ),
                    const SizedBox(width: 8),
                    _RatingButton(
                      label: 'GOOD',
                      sub: 'Tốt',
                      color: accent,
                      onTap: () => context.read<SrsBloc>().add(SrsCardReviewed(ReviewRating.good)),
                    ),
                    const SizedBox(width: 8),
                    _RatingButton(
                      label: 'EASY',
                      sub: 'Dễ',
                      color: AppTheme.infoColor,
                      onTap: () => context.read<SrsBloc>().add(SrsCardReviewed(ReviewRating.easy)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontContent(BuildContext context, SrsCardEntity card) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.word,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.text(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Nhấn card để xem nghĩa',
            style: AppTheme.bodySm(context).copyWith(color: AppTheme.text3(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildBackContent(BuildContext context, SrsCardEntity card) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.definition,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.text(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.isDark(context) ? const Color(0xFF242424) : AppTheme.surface2(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              'Streak: ${card.streak}🔥  •  Interval: ${card.interval} ngày',
              style: AppTheme.bodySm(context).copyWith(color: AppTheme.text2(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletion(BuildContext context, SrsCompleted state) {
    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);
    final pct = state.totalCards > 0 ? (state.correctCount / state.totalCards * 100).round() : 100;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Hoàn thành SRS', style: AppTheme.titleSm(context)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$pct%',
                      style: AppTheme.displayLg(context).copyWith(color: accent),
                    ),
                    Text('chính xác', style: AppTheme.bodySm(context)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Đã ôn tập xong! 🎉', style: AppTheme.displayMd(context)),
              const SizedBox(height: 8),
              Text('Đã ôn ${state.totalCards} thẻ hôm nay.', style: AppTheme.bodyMd(context)),
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
      child: PressableScale(
        onTap: onTap,
        scaleDown: 0.94,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.isDark(context) ? const Color(0xFF242424) : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
