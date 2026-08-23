import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/history_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/history_usecases.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/lesson/lesson_bloc.dart';

// ── Modes ──────────────────────────────────────────────────────────
enum ReviewMode { normal, reverse, practice }

// ── Page ───────────────────────────────────────────────────────────
class ReviewPage extends StatefulWidget {
  final String lessonId;
  const ReviewPage({super.key, required this.lessonId});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<VocabItemEntity> _vocab = [];
  List<VocabItemEntity> _queue = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _answered = false;
  ReviewMode _mode = ReviewMode.normal;
  bool _showCompletion = false;
  late DateTime _startTime;

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    context.read<LessonBloc>().add(LessonLoadRequested(widget.lessonId));
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initQuiz(List<VocabItemEntity> vocab) {
    if (_vocab.isNotEmpty) return;
    _vocab = vocab;
    _queue = List.from(vocab)..shuffle(_random);
    _pickMode();
  }

  void _pickMode() {
    final modes = ReviewMode.values;
    setState(() => _mode = modes[_random.nextInt(modes.length)]);
  }

  void _onCorrect() {
    setState(() {
      _answered = true;
      _correctCount++;
    });
    Future.delayed(const Duration(milliseconds: 800), _next);
  }

  void _onWrong() {
    setState(() {
      _answered = true;
    });
  }

  void _next() {
    if (!mounted) return;
    if (_currentIndex < _queue.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
      });
      _pickMode();
    } else {
      _saveHistory();
      setState(() => _showCompletion = true);
    }
  }

  void _saveHistory() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    context.read<IncrementStudyStatsUseCase>().call(
          authState.user.uid,
          StudyMode.review,
          timeSpent,
        );
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _answered = false;
      _showCompletion = false;
      _queue = List.from(_vocab)..shuffle(_random);
      _startTime = DateTime.now();
    });
    _pickMode();
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LessonBloc, LessonState>(
      listener: (context, state) {
        if (state is LessonLoaded && state.lesson.vocabulary != null) {
          _initQuiz(state.lesson.vocabulary!);
        }
      },
      builder: (context, state) {
        if (_vocab.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ôn tập')),
            body: const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
          );
        }

        if (_showCompletion) return _buildCompletion();

        final current = _queue[_currentIndex];
        final progress = _currentIndex / _queue.length;

        return Scaffold(
          appBar: AppBar(
            title: Text('Ôn tập (${_currentIndex + 1}/${_queue.length})'),
            leading: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.surface2Color,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_correctCount đúng',
                        style: const TextStyle(fontSize: 12, color: AppTheme.successColor, fontWeight: FontWeight.w500)),
                    _ModeBadge(mode: _mode),
                  ],
                ),
                const SizedBox(height: 20),

                // Question card based on mode
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey('$_currentIndex-$_mode'),
                    child: _buildModeWidget(current),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeWidget(VocabItemEntity current) {
    switch (_mode) {
      case ReviewMode.normal:
        return _NormalMode(
          current: current,
          allVocab: _vocab,
          answered: _answered,
          onCorrect: _onCorrect,
          onWrong: _onWrong,
          onNext: _next,
        );
      case ReviewMode.reverse:
        return _ReverseMode(
          current: current,
          allVocab: _vocab,
          answered: _answered,
          onCorrect: _onCorrect,
          onWrong: _onWrong,
          onNext: _next,
        );
      case ReviewMode.practice:
        return _PracticeMode(
          current: current,
          answered: _answered,
          onCorrect: _onCorrect,
          onWrong: _onWrong,
          onNext: _next,
        );
    }
  }

  Widget _buildCompletion() {
    final pct = _vocab.isEmpty ? 0 : (_correctCount / _queue.length * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(pct >= 80 ? '🏆' : pct >= 50 ? '👍' : '📚',
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('$pct%', style: AppTheme.displayLg.copyWith(color: AppTheme.accentColor, fontSize: 48)),
              const SizedBox(height: 8),
              Text('$_correctCount / ${_queue.length} câu đúng', style: AppTheme.bodyMd),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.refresh),
                label: const Text('Ôn tập lại'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.pushReplacement('/test/${widget.lessonId}'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Làm bài kiểm tra'),
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

// ── Mode Badge ─────────────────────────────────────────────────────
class _ModeBadge extends StatelessWidget {
  final ReviewMode mode;
  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (mode) {
      ReviewMode.normal => ('Chọn nghĩa', Icons.menu_book_outlined, AppTheme.infoColor),
      ReviewMode.reverse => ('Chọn từ', Icons.swap_horiz, AppTheme.successColor),
      ReviewMode.practice => ('Gõ từ', Icons.edit_outlined, AppTheme.accentColor),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────

class _QuestionBox extends StatelessWidget {
  final String label;
  final String content;
  final Color accentColor;
  final Widget? extra;
  const _QuestionBox({required this.label, required this.content, this.accentColor = AppTheme.accentColor, this.extra});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTheme.labelMd.copyWith(color: accentColor)),
          const SizedBox(height: 12),
          Text(content,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.textColor),
              textAlign: TextAlign.center),
          if (extra != null) ...[const SizedBox(height: 8), extra!],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isCorrect;
  final bool isSelected;
  final bool showResult;
  const _OptionButton({
    required this.text,
    required this.onTap,
    required this.isCorrect,
    required this.isSelected,
    required this.showResult,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (showResult) {
      if (isCorrect) {
        bgColor = AppTheme.successColor.withValues(alpha: 0.1);
        borderColor = AppTheme.successColor;
        textColor = AppTheme.successColor;
      } else if (isSelected) {
        bgColor = AppTheme.errorColor.withValues(alpha: 0.1);
        borderColor = AppTheme.errorColor;
        textColor = AppTheme.errorColor;
      } else {
        bgColor = AppTheme.surface2Color;
        borderColor = AppTheme.borderColor;
        textColor = AppTheme.text3Color;
      }
    } else {
      bgColor = AppTheme.surfaceColor;
      borderColor = AppTheme.borderColor;
      textColor = AppTheme.textColor;
    }

    return GestureDetector(
      onTap: showResult ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: borderColor, width: showResult && (isCorrect || isSelected) ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
            ),
            if (showResult && isCorrect)
              const Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
            if (showResult && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: AppTheme.errorColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onNext;
  const _NextButton({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface2Color),
        child: const Text('Từ tiếp theo →',
            style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Mode 1: Normal (EN → choose VI) ────────────────────────────────
class _NormalMode extends StatefulWidget {
  final VocabItemEntity current;
  final List<VocabItemEntity> allVocab;
  final bool answered;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;
  final VoidCallback onNext;

  const _NormalMode({
    required this.current,
    required this.allVocab,
    required this.answered,
    required this.onCorrect,
    required this.onWrong,
    required this.onNext,
  });

  @override
  State<_NormalMode> createState() => _NormalModeState();
}

class _NormalModeState extends State<_NormalMode> {
  late List<String> _options;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  void _generateOptions() {
    final others = widget.allVocab
        .where((v) => v.word != widget.current.word)
        .toList()
      ..shuffle();
    final wrong = others.take(3).map((v) => v.definition).toList();
    _options = [widget.current.definition, ...wrong]..shuffle();
  }

  void _select(String opt) {
    if (widget.answered) return;
    setState(() => _selected = opt);
    if (opt == widget.current.definition) {
      widget.onCorrect();
    } else {
      widget.onWrong();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuestionBox(
          label: 'Từ tiếng Anh này có nghĩa là gì?',
          content: widget.current.word,
          accentColor: AppTheme.infoColor,
          extra: widget.current.ipa != null
              ? Text('/${widget.current.ipa}/',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF60A5FA), fontFamily: 'monospace'))
              : null,
        ),
        const SizedBox(height: 20),
        ...(_options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionButton(
                text: opt,
                onTap: () => _select(opt),
                isCorrect: opt == widget.current.definition,
                isSelected: opt == _selected,
                showResult: widget.answered,
              ),
            ))),
        if (widget.answered && _selected != widget.current.definition) ...[
          const SizedBox(height: 12),
          _NextButton(onNext: widget.onNext),
        ],
      ],
    );
  }
}

// ── Mode 2: Reverse (VI → choose EN) ──────────────────────────────
class _ReverseMode extends StatefulWidget {
  final VocabItemEntity current;
  final List<VocabItemEntity> allVocab;
  final bool answered;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;
  final VoidCallback onNext;

  const _ReverseMode({
    required this.current,
    required this.allVocab,
    required this.answered,
    required this.onCorrect,
    required this.onWrong,
    required this.onNext,
  });

  @override
  State<_ReverseMode> createState() => _ReverseModeState();
}

class _ReverseModeState extends State<_ReverseMode> {
  late List<String> _options;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  void _generateOptions() {
    final others = widget.allVocab
        .where((v) => v.word != widget.current.word)
        .toList()
      ..shuffle();
    final wrong = others.take(3).map((v) => v.word).toList();
    _options = [widget.current.word, ...wrong]..shuffle();
  }

  void _select(String opt) {
    if (widget.answered) return;
    setState(() => _selected = opt);
    if (opt == widget.current.word) {
      widget.onCorrect();
    } else {
      widget.onWrong();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuestionBox(
          label: 'Từ tiếng Anh nào có nghĩa là:',
          content: widget.current.definition,
          accentColor: AppTheme.successColor,
        ),
        const SizedBox(height: 20),
        ...(_options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionButton(
                text: opt,
                onTap: () => _select(opt),
                isCorrect: opt == widget.current.word,
                isSelected: opt == _selected,
                showResult: widget.answered,
              ),
            ))),
        if (widget.answered && _selected != widget.current.word) ...[
          const SizedBox(height: 12),
          _NextButton(onNext: widget.onNext),
        ],
      ],
    );
  }
}

// ── Mode 3: Practice (VI definition → type EN word with hints) ─────
class _PracticeMode extends StatefulWidget {
  final VocabItemEntity current;
  final bool answered;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;
  final VoidCallback onNext;

  const _PracticeMode({
    required this.current,
    required this.answered,
    required this.onCorrect,
    required this.onWrong,
    required this.onNext,
  });

  @override
  State<_PracticeMode> createState() => _PracticeModeState();
}

class _PracticeModeState extends State<_PracticeMode> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool? _isCorrect;
  final Set<int> _hints = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.answered || _ctrl.text.trim().isEmpty) return;
    final isCorrect = _ctrl.text.trim().toLowerCase() == widget.current.word.toLowerCase();
    setState(() => _isCorrect = isCorrect);
    if (isCorrect) {
      widget.onCorrect();
    } else {
      widget.onWrong();
    }
  }

  void _addHint() {
    final wordLen = widget.current.word.length;
    if (_hints.length >= wordLen - 1) return;
    final unrevealed = List.generate(wordLen, (i) => i).where((i) => !_hints.contains(i)).toList()..shuffle();
    if (unrevealed.isNotEmpty) {
      setState(() => _hints.add(unrevealed.first));
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordChars = widget.current.word.split('');
    final isAnswered = widget.answered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuestionBox(
          label: 'Nghĩa tiếng Việt',
          content: widget.current.definition,
          accentColor: AppTheme.accentColor,
        ),
        const SizedBox(height: 20),

        // Letter slots
        Text('Gõ từ tiếng Anh:', style: AppTheme.labelMd),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Wrap(
            spacing: 6,
            runSpacing: 8,
            children: wordChars.asMap().entries.map((e) {
              final i = e.key;
              final char = e.value;
              final isSpace = char == ' ';
              final isRevealed = _hints.contains(i);
              final userChar = i < _ctrl.text.length ? _ctrl.text[i] : '';
              final displayChar = userChar.isNotEmpty ? userChar : (isRevealed ? char : '');

              Color borderColor = AppTheme.borderColor;
              Color textColor = AppTheme.textColor;
              Color bgColor = AppTheme.surfaceColor;

              if (isAnswered) {
                if (_isCorrect == true) {
                  borderColor = AppTheme.successColor;
                  textColor = AppTheme.successColor;
                  bgColor = AppTheme.successColor.withValues(alpha: 0.08);
                } else {
                  borderColor = AppTheme.errorColor;
                  textColor = AppTheme.errorColor;
                  bgColor = AppTheme.errorColor.withValues(alpha: 0.08);
                }
              } else if (i == _ctrl.text.length) {
                borderColor = AppTheme.accentColor;
              } else if (isRevealed && userChar.isEmpty) {
                borderColor = const Color(0xFFF59E0B);
                textColor = const Color(0xFFB45309);
                bgColor = const Color(0xFFFEF3C7);
              }

              if (isSpace) {
                return const SizedBox(width: 12);
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  border: Border(bottom: BorderSide(color: borderColor, width: 3)),
                ),
                alignment: Alignment.center,
                child: Text(displayChar,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
              );
            }).toList(),
          ),
        ),

        // Hidden input
        SizedBox(
          height: 0,
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            enabled: !isAnswered,
            maxLength: widget.current.word.length,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(counterText: ''),
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
            cursorColor: Colors.transparent,
          ),
        ),
        const SizedBox(height: 20),

        // Feedback
        if (isAnswered) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_isCorrect! ? AppTheme.successColor : AppTheme.errorColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                  color: (_isCorrect! ? AppTheme.successColor : AppTheme.errorColor).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(_isCorrect! ? Icons.check_circle_outline : Icons.info_outline,
                    color: _isCorrect! ? AppTheme.successColor : AppTheme.errorColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isCorrect! ? 'Chính xác!' : 'Đáp án đúng:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isCorrect! ? AppTheme.successColor : AppTheme.errorColor,
                              fontSize: 13)),
                      if (!_isCorrect!)
                        Text(widget.current.word,
                            style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _NextButton(onNext: widget.onNext),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _hints.length < widget.current.word.length - 1 ? _addHint : null,
                icon: const Icon(Icons.lightbulb_outline, size: 16),
                label: Text('Gợi ý (${max(0, widget.current.word.length - 1 - _hints.length)})'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.accentColor),
              ),
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: _ctrl.text.trim().isEmpty ? null : _submit,
                  child: const Text('Kiểm tra'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
