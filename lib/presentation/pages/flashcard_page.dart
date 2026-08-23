import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/history_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/history_usecases.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/lesson/lesson_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/flip_card_widget.dart';

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
  final Map<int, bool?> _results = {};
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
    setState(() => _results[_currentIndex] = know);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_currentIndex < _cards.length - 1) {
        setState(() {
          _currentIndex++;
          _isFlipped = false;
        });
      } else {
        _saveHistory();
        setState(() => _showCompletion = true);
      }
    });
  }

  void _saveHistory() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    context.read<IncrementStudyStatsUseCase>().call(
          authState.user.uid,
          StudyMode.flashcard,
          timeSpent,
        );
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
      _results.clear();
      _showCompletion = false;
      _cards.shuffle();
      _startTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LessonBloc, LessonState>(
      listener: (context, state) {
        if (state is LessonLoaded && state.lesson.vocabulary != null) {
          _onLessonLoaded(state.lesson.vocabulary!);
        }
      },
      builder: (context, state) {
        if (state is LessonLoading || _cards.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.bgColor,
            appBar: AppBar(
              backgroundColor: AppTheme.bgColor,
              title: const Text('Flashcard'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_showCompletion) return _buildCompletion();

        final card = _cards[_currentIndex];
        final progress = _currentIndex / _cards.length;
        final knowCount = _results.values.where((v) => v == true).length;
        final learnCount = _results.values.where((v) => v == false).length;

        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          appBar: AppBar(
            backgroundColor: AppTheme.bgColor,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              onPressed: () => context.pop(),
            ),
            title: Text(
              '${_currentIndex + 1} / ${_cards.length}',
              style: AppTheme.titleSm,
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                // ── Progress bar ──────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.surface3Color,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Stats row ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$knowCount đã thuộc',
                          style: AppTheme.bodySm.copyWith(color: AppTheme.accentColor),
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
                        Text('$learnCount cần ôn', style: AppTheme.bodySm),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Flip hint ─────────────────────────────────
                Text(
                  _isFlipped ? '← Nhấn để xem từ' : 'Nhấn để xem nghĩa →',
                  style: AppTheme.bodySm,
                ),
                const SizedBox(height: 12),

                // ── Flip card ─────────────────────────────────
                Expanded(
                  child: FlipCardWidget(
                    isFlipped: _isFlipped,
                    onFlip: _flip,
                    front: _buildCardContent(
                      card.word,
                      sub: card.ipa != null ? '/${card.ipa}/' : null,
                      label: card.wordType,
                      isBack: false,
                    ),
                    back: _buildCardContent(
                      card.definition,
                      sub: card.exampleEn,
                      isBack: true,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Action buttons ────────────────────────────
                Row(
                  children: [
                    // "Don't know" — outlined pill
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _answer(false),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.close_rounded, size: 18, color: AppTheme.errorColor),
                              const SizedBox(width: 6),
                              Text('CẦN ÔN', style: AppTheme.labelSm.copyWith(color: AppTheme.errorColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // "Know" — green pill
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _answer(true),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            boxShadow: AppTheme.shadowGreen,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, size: 18, color: Colors.black),
                              const SizedBox(width: 6),
                              Text(
                                'ĐÃ THUỘC',
                                style: AppTheme.labelSm.copyWith(color: Colors.black),
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
        );
      },
    );
  }

  Widget _buildCardContent(String main, {String? sub, String? label, bool isBack = false}) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: AppTheme.pillDecoration(
                background: AppTheme.warningColor.withValues(alpha: 0.1),
                border: AppTheme.warningColor.withValues(alpha: 0.35),
              ),
              child: Text(
                label,
                style: AppTheme.labelSm.copyWith(color: AppTheme.warningColor, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            main,
            style: TextStyle(
              fontSize: isBack ? 22 : 30,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (sub != null) ...[
            const SizedBox(height: 14),
            Text(
              sub,
              style: TextStyle(
                fontSize: 14,
                color: isBack ? AppTheme.text2Color : AppTheme.infoColor,
                fontStyle: isBack ? FontStyle.italic : FontStyle.normal,
                fontFamily: isBack ? null : 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletion() {
    final knowCount = _results.values.where((v) => v == true).length;
    final learningCount = _results.values.where((v) => v == false).length;
    final pct = (_cards.isEmpty ? 0 : (knowCount / _cards.length * 100)).round();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(backgroundColor: AppTheme.bgColor, title: const Text('Hoàn thành!')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentColor.withValues(alpha: 0.12),
                  border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.5), width: 2),
                  boxShadow: AppTheme.shadowGreen,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$pct%',
                      style: AppTheme.displayLg.copyWith(color: AppTheme.accentColor),
                    ),
                    Text('thuộc bài', style: AppTheme.bodySm),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Hoàn thành rồi! 🎉', style: AppTheme.displayMd),
              const SizedBox(height: 8),
              Text('Bạn đã học ${_cards.length} từ vựng', style: AppTheme.bodyMd),
              const SizedBox(height: 28),

              // Stats row
              Row(
                children: [
                  _StatBox(label: 'ĐÃ THUỘC', value: '$knowCount', color: AppTheme.accentColor),
                  const SizedBox(width: 12),
                  _StatBox(label: 'CẦN ÔN', value: '$learningCount', color: AppTheme.errorColor),
                ],
              ),
              const SizedBox(height: 32),

              // CTAs
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.black),
                  label: Text('HỌC LẠI', style: AppTheme.labelLg.copyWith(color: Colors.black)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => context.pushReplacement('/review/${widget.lessonId}'),
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  label: const Text('ÔN TẬP NGAY'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Quay lại bài học'),
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Column(
          children: [
            Text(value, style: AppTheme.displayLg.copyWith(color: color, fontSize: 32)),
            const SizedBox(height: 4),
            Text(label, style: AppTheme.labelSm.copyWith(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
