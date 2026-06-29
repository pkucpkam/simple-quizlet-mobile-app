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
  final Map<int, bool?> _results = {}; // null=unanswered, true=know, false=learning
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
    setState(() {
      _results[_currentIndex] = know;
    });
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
            appBar: AppBar(title: const Text('Flashcard')),
            body: const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
          );
        }

        if (_showCompletion) return _buildCompletion();

        final card = _cards[_currentIndex];
        final progress = (_currentIndex) / _cards.length;

        return Scaffold(
          appBar: AppBar(
            title: Text('Flashcard (${_currentIndex + 1}/${_cards.length})'),
            leading: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.surface2Color,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_results.values.where((v) => v == true).length} đã thuộc',
                      style: const TextStyle(fontSize: 12, color: AppTheme.successColor, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${_results.values.where((v) => v == false).length} cần ôn',
                      style: AppTheme.bodySm,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Flip hint
                Text(
                  _isFlipped ? 'Nhấn để xem từ' : 'Nhấn để xem nghĩa',
                  style: AppTheme.bodySm,
                ),
                const SizedBox(height: 12),

                // Flip card
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

                // Know / Don't know buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _answer(false),
                        icon: const Icon(Icons.close, size: 18, color: AppTheme.errorColor),
                        label: const Text('Cần ôn', style: TextStyle(color: AppTheme.errorColor)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _answer(true),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Đã thuộc'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
            ),
          if (label != null) const SizedBox(height: 12),
          Text(
            main,
            style: TextStyle(
              fontSize: isBack ? 20 : 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (sub != null) ...[
            const SizedBox(height: 12),
            Text(
              sub,
              style: TextStyle(
                fontSize: 13,
                color: isBack ? AppTheme.text2Color : const Color(0xFF60A5FA),
                fontStyle: isBack ? FontStyle.italic : FontStyle.normal,
                fontFamily: isBack ? null : 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            isBack ? '← Nhấn để xem từ' : 'Nhấn để xem nghĩa →',
            style: AppTheme.bodySm.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletion() {
    final knowCount = _results.values.where((v) => v == true).length;
    final learningCount = _results.values.where((v) => v == false).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Hoàn thành!')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('Tuyệt vời!', style: AppTheme.displayMd),
              const SizedBox(height: 8),
              Text('Bạn đã học xong ${_cards.length} từ vựng', style: AppTheme.bodyMd),
              const SizedBox(height: 28),
              Row(
                children: [
                  _StatBox(label: 'Đã thuộc', value: '$knowCount', color: AppTheme.successColor),
                  const SizedBox(width: 12),
                  _StatBox(label: 'Cần ôn', value: '$learningCount', color: AppTheme.text2Color),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.refresh),
                label: const Text('Học lại'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.pushReplacement('/review/${widget.lessonId}'),
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Ôn tập ngay'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.bodySm),
          ],
        ),
      ),
    );
  }
}
