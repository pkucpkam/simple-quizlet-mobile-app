import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/history_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/history_usecases.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/srs_usecases.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/lesson/lesson_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/flip_card_widget.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';

class FlashcardPage extends StatefulWidget {
  final String lessonId;
  const FlashcardPage({super.key, required this.lessonId});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  List<VocabItemEntity> _cards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  final Map<int, String> _statuses = {}; // 'know' | 'still_learning'
  bool _showCompletion = false;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    context.read<LessonBloc>().add(LessonLoadRequested(widget.lessonId));
  }

  void _onLessonLoaded(List<VocabItemEntity> vocab) {
    if (_cards.isEmpty) {
      setState(() => _cards = List.from(vocab)..shuffle());
    }
  }

  void _flip() => setState(() => _isFlipped = !_isFlipped);

  void _answer(bool know) {
    setState(() => _statuses[_currentIndex] = know ? 'know' : 'still_learning');
    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final hasRemaining = _cards.asMap().entries.any(
            (e) => _statuses[e.key] != 'know',
          );
      if (!hasRemaining) {
        _saveHistory();
        setState(() => _showCompletion = true);
      } else {
        _moveToNext();
      }
    });
  }

  void _moveToNext() {
    int next = (_currentIndex + 1) % _cards.length;
    while (_statuses[next] == 'know' && next != _currentIndex) {
      next = (next + 1) % _cards.length;
    }
    setState(() {
      _currentIndex = next;
      _isFlipped = false;
    });
  }

  void _saveHistory() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    injector<IncrementStudyStatsUseCase>().call(
          authState.user.uid,
          StudyMode.flashcard,
          timeSpent,
        );

    // Initialize SRS cards if not already created
    try {
      injector<InitializeCardsUseCase>().call(
        widget.lessonId,
        authState.user.uid,
        _cards,
      );
    } catch (_) {}
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
      _statuses.clear();
      _showCompletion = false;
      _cards.shuffle();
      _startTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);
    final textCol = AppTheme.text(context);
    final text3Col = AppTheme.text3(context);
    final surface3 = AppTheme.surface3(context);

    return BlocConsumer<LessonBloc, LessonState>(
      listener: (context, state) {
        if (state is LessonLoaded && state.lesson.vocabulary != null) {
          _onLessonLoaded(state.lesson.vocabulary!);
        }
      },
      builder: (context, state) {
        if (state is LessonLoading || _cards.isEmpty) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              title: Text('Flashcard', style: AppTheme.titleSm(context)),
            ),
            body: Center(child: CircularProgressIndicator(color: accent)),
          );
        }

        if (_showCompletion) return _buildCompletion(context);

        final card = _cards[_currentIndex];
        final knowCount = _statuses.values.where((v) => v == 'know').length;
        final learnCount = _cards.length - knowCount;
        final progress = knowCount / _cards.length;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            leading: IconButton(
              icon: Icon(Icons.close_rounded, size: 24, color: textCol),
              onPressed: () => context.pop(),
            ),
            title: Text(
              '${_currentIndex + 1} / ${_cards.length}',
              style: AppTheme.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: textCol,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  // ── Progress bar ──────────────────────────────
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

                  // ── Stats row ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$knowCount đã thuộc',
                            style: AppTheme.bodySm(context).copyWith(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$learnCount cần ôn',
                            style: AppTheme.bodySm(context).copyWith(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Flip hint ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 14, color: text3Col),
                      const SizedBox(width: 5),
                      Text(
                        _isFlipped ? 'Chạm để lật mặt trước' : 'Chạm để xem định nghĩa (hoặc vuốt)',
                        style: AppTheme.bodySm(context).copyWith(color: text3Col),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── 3D Flip Card ──────────────────────────────
                  Expanded(
                    child: FlipCardWidget(
                      isFlipped: _isFlipped,
                      onFlip: _flip,
                      onSwipeComplete: (isKnown) => _answer(isKnown),
                      front: _buildCardContent(
                        context,
                        card.word,
                        sub: card.ipa != null ? '/${card.ipa}/' : null,
                        label: card.wordType,
                        isBack: false,
                      ),
                      back: _buildCardContent(
                        context,
                        card.definition,
                        sub: card.exampleEn,
                        isBack: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Action buttons in thumb zone ───────────────
                  Row(
                    children: [
                      // "CẦN ÔN" — tactile pill
                      Expanded(
                        child: PressableScale(
                          onTap: () => _answer(false),
                          scaleDown: 0.95,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppTheme.isDark(context)
                                  ? const Color(0xFF2A1619)
                                  : AppTheme.errorColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.close_rounded, size: 20, color: AppTheme.errorColor),
                                const SizedBox(width: 8),
                                Text(
                                  'CẦN ÔN',
                                  style: AppTheme.labelSm(context).copyWith(
                                    color: AppTheme.errorColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // "ĐÃ THUỘC" — tactile accent pill
                      Expanded(
                        child: PressableScale(
                          onTap: () => _answer(true),
                          scaleDown: 0.95,
                          child: Container(
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'ĐÃ THUỘC',
                                  style: AppTheme.labelSm(context).copyWith(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    String main, {
    String? sub,
    String? label,
    bool isBack = false,
  }) {
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: AppTheme.pillDecoration(
                context: context,
                background: AppTheme.warningColor.withValues(alpha: 0.12),
                border: AppTheme.warningColor.withValues(alpha: 0.4),
              ),
              child: Text(
                label.toUpperCase(),
                style: AppTheme.labelSm(context).copyWith(
                  color: AppTheme.warningColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            main,
            style: TextStyle(
              fontSize: isBack ? 22 : 32,
              fontWeight: FontWeight.w800,
              color: textCol,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (sub != null) ...[
            const SizedBox(height: 16),
            Text(
              sub,
              style: TextStyle(
                fontSize: 15,
                color: isBack ? text2Col : AppTheme.infoColor,
                fontStyle: isBack ? FontStyle.italic : FontStyle.normal,
                fontFamily: isBack ? null : 'monospace',
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletion(BuildContext context) {
    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);
    final knowCount = _statuses.values.where((v) => v == 'know').length;
    final learningCount = _cards.length - knowCount;
    final pct = (_cards.isEmpty ? 0 : (knowCount / _cards.length * 100)).round();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Hoàn thành bài học', style: AppTheme.titleSm(context)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score circle
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$pct%',
                      style: AppTheme.displayLg(context).copyWith(
                        color: accent,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('ghi nhớ', style: AppTheme.bodySm(context)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Xuất sắc! 🎉', style: AppTheme.displayMd(context)),
              const SizedBox(height: 8),
              Text(
                'Bạn đã hoàn thành ${_cards.length} thẻ từ vựng',
                style: AppTheme.bodyMd(context),
              ),
              const SizedBox(height: 28),

              // Stats row
              Row(
                children: [
                  _StatBox(
                    label: 'ĐÃ THUỘC',
                    value: '$knowCount',
                    color: accent,
                  ),
                  const SizedBox(width: 14),
                  _StatBox(
                    label: 'CẦN ÔN',
                    value: '$learningCount',
                    color: AppTheme.errorColor,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // CTAs
              PressableScale(
                onTap: _restart,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'HỌC LẠI TỪ ĐẦU',
                          style: AppTheme.labelLg(context).copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PressableScale(
                onTap: () => context.pushReplacement('/review/${widget.lessonId}'),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.isDark(context) ? const Color(0xFF242424) : AppTheme.surface2(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz_outlined, size: 20, color: AppTheme.text(context)),
                        const SizedBox(width: 8),
                        Text(
                          'LUYỆN ÔN TẬP NGAY',
                          style: AppTheme.labelLg(context).copyWith(color: AppTheme.text(context)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Quay lại danh sách bài học', style: AppTheme.bodyMd(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.isDark(context) ? const Color(0xFF242424) : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTheme.labelSm(context).copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
