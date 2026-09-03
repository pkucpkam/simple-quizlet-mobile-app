import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
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
  final List<VocabItemEntity> _wrongVocab = [];
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
      final current = _queue[_currentIndex];
      if (!_wrongVocab.contains(current)) {
        _wrongVocab.add(current);
      }
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
    injector<IncrementStudyStatsUseCase>().call(
          authState.user.uid,
          StudyMode.review,
          timeSpent,
        );
  }

  void _restart({List<VocabItemEntity>? customQueue}) {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _answered = false;
      _showCompletion = false;
      _wrongVocab.clear();
      _queue = customQueue != null
          ? (List.from(customQueue)..shuffle(_random))
          : (List.from(_vocab)..shuffle(_random));
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
    final wrongCount = _queue.length - _correctCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả ôn tập')),
      body: Column(
        children: [
          // Banner summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                Text(pct >= 80 ? '🏆' : pct >= 50 ? '👍' : '📚',
                    style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text('$pct%',
                    style: AppTheme.displayLg.copyWith(
                        color: pct >= 80
                            ? AppTheme.successColor
                            : pct >= 50
                                ? AppTheme.accentColor
                                : AppTheme.errorColor,
                        fontSize: 40)),
                const SizedBox(height: 12),
                
                // Stat cards (Đúng / Sai)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 18),
                          const SizedBox(width: 6),
                          Text('Đúng: $_correctCount',
                              style: const TextStyle(
                                  color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel_rounded, color: AppTheme.errorColor, size: 18),
                          const SizedBox(width: 6),
                          Text('Sai: $wrongCount',
                              style: const TextStyle(
                                  color: AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Detail section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _wrongVocab.isNotEmpty ? 'Các từ làm sai (${_wrongVocab.length})' : 'Tất cả các từ trong bài',
                  style: AppTheme.labelMd.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_wrongVocab.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _restart(customQueue: List.from(_wrongVocab)),
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: const Text('Ôn lại từ sai', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.accentColor),
                  ),
              ],
            ),
          ),

          // List of wrong words or all words
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _wrongVocab.isNotEmpty ? _wrongVocab.length : _queue.length,
              itemBuilder: (context, index) {
                final item = _wrongVocab.isNotEmpty ? _wrongVocab[index] : _queue[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _wrongVocab.isNotEmpty
                        ? AppTheme.errorColor.withValues(alpha: 0.06)
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: _wrongVocab.isNotEmpty
                          ? AppTheme.errorColor.withValues(alpha: 0.2)
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _wrongVocab.isNotEmpty ? Icons.cancel_outlined : Icons.check_circle_outline,
                        color: _wrongVocab.isNotEmpty ? AppTheme.errorColor : AppTheme.successColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(item.word, style: AppTheme.titleMd.copyWith(fontSize: 16)),
                                if (item.ipa != null) ...[
                                  const SizedBox(width: 8),
                                  Text('/${item.ipa}/',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFFD97706), fontFamily: 'monospace')),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(item.definition, style: AppTheme.bodyMd),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _restart(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Ôn lại tất cả'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.pushReplacement('/test/${widget.lessonId}'),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Kiểm tra'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Quay lại bài học'),
                  ),
                ),
              ],
            ),
          ),
        ],
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

        // Letter slots container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Text('Gõ từ tiếng Anh:', style: AppTheme.labelMd),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _focus.requestFocus(),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 10,
                  children: wordChars.asMap().entries.map((e) {
                    final i = e.key;
                    final char = e.value;
                    final isSpace = char == ' ';
                    final isRevealed = _hints.contains(i);
                    final userChar = i < _ctrl.text.length ? _ctrl.text[i] : '';
                    final displayChar = userChar.isNotEmpty ? userChar : (isRevealed ? char : '');

                    Color borderColor = AppTheme.borderColor;
                    Color textColor = AppTheme.textColor;
                    Color bgColor = AppTheme.surface2Color;

                    if (isAnswered) {
                      if (_isCorrect == true) {
                        borderColor = AppTheme.successColor;
                        textColor = AppTheme.successColor;
                        bgColor = AppTheme.successColor.withValues(alpha: 0.12);
                      } else {
                        borderColor = AppTheme.errorColor;
                        textColor = AppTheme.errorColor;
                        bgColor = AppTheme.errorColor.withValues(alpha: 0.12);
                      }
                    } else if (i == _ctrl.text.length) {
                      borderColor = AppTheme.accentColor;
                      bgColor = AppTheme.accentColor.withValues(alpha: 0.08);
                    } else if (isRevealed && userChar.isEmpty) {
                      borderColor = const Color(0xFFF59E0B);
                      textColor = const Color(0xFFB45309);
                      bgColor = const Color(0xFFFEF3C7);
                    }

                    if (isSpace) {
                      return const SizedBox(width: 14);
                    }

                    final isCurrentActive = !isAnswered && i == _ctrl.text.length;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 38,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor,
                          width: isCurrentActive ? 2.5 : 1.5,
                        ),
                        boxShadow: isCurrentActive
                            ? [
                                BoxShadow(
                                  color: AppTheme.accentColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        displayChar,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
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
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: Text('Gợi ý (${max(0, widget.current.word.length - 1 - _hints.length)})'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.accentColor),
              ),
              ElevatedButton.icon(
                onPressed: _ctrl.text.trim().isEmpty ? null : _submit,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text(
                  'Kiểm tra',
                  maxLines: 1,
                  softWrap: false,
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(130, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
