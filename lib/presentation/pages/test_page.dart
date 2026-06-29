import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/history_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/history_usecases.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/lesson/lesson_bloc.dart';

class TestPage extends StatefulWidget {
  final String lessonId;
  const TestPage({super.key, required this.lessonId});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  List<VocabItemEntity> _vocab = [];
  List<VocabItemEntity> _queue = [];
  int _currentIndex = 0;
  final _answerCtrl = TextEditingController();
  bool _submitted = false;
  bool? _isCorrect;
  int _correctCount = 0;
  List<_TestResult> _results = [];
  bool _showResult = false;
  late DateTime _startTime;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    context.read<LessonBloc>().add(LessonLoadRequested(widget.lessonId));
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initTest(List<VocabItemEntity> vocab) {
    if (_vocab.isNotEmpty) return;
    _vocab = vocab;
    _queue = List.from(vocab)..shuffle();
  }

  void _submit() {
    if (_submitted || _answerCtrl.text.trim().isEmpty) return;
    final current = _queue[_currentIndex];
    final userAnswer = _answerCtrl.text.trim().toLowerCase();
    final correct = current.word.toLowerCase();
    final isCorrect = userAnswer == correct;
    setState(() {
      _submitted = true;
      _isCorrect = isCorrect;
      if (isCorrect) _correctCount++;
      _results.add(_TestResult(
        word: current.word,
        definition: current.definition,
        userAnswer: _answerCtrl.text.trim(),
        isCorrect: isCorrect,
      ));
    });
  }

  void _next() {
    if (_currentIndex < _queue.length - 1) {
      setState(() {
        _currentIndex++;
        _submitted = false;
        _isCorrect = null;
        _answerCtrl.clear();
      });
      _focusNode.requestFocus();
    } else {
      _saveHistory();
      setState(() => _showResult = true);
    }
  }

  void _saveHistory() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    context.read<IncrementStudyStatsUseCase>().call(
          authState.user.uid,
          StudyMode.test,
          timeSpent,
        );
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _submitted = false;
      _isCorrect = null;
      _results = [];
      _showResult = false;
      _queue = List.from(_vocab)..shuffle();
      _answerCtrl.clear();
      _startTime = DateTime.now();
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LessonBloc, LessonState>(
      listener: (context, state) {
        if (state is LessonLoaded && state.lesson.vocabulary != null) {
          _initTest(state.lesson.vocabulary!);
        }
      },
      builder: (context, state) {
        if (_vocab.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kiểm tra')),
            body: const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
          );
        }

        if (_showResult) return _buildResult();

        final current = _queue[_currentIndex];
        final progress = _currentIndex / _queue.length;

        return Scaffold(
          appBar: AppBar(
            title: Text('Kiểm tra (${_currentIndex + 1}/${_queue.length})'),
            leading: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Padding(
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
                  const SizedBox(height: 24),

                  // Prompt
                  Text('Nghĩa tiếng Việt:', style: AppTheme.labelMd),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          current.definition,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Nhập từ tiếng Anh:', style: AppTheme.labelMd),
                  const SizedBox(height: 8),

                  // Input
                  TextField(
                    controller: _answerCtrl,
                    focusNode: _focusNode,
                    style: AppTheme.bodyLg,
                    enabled: !_submitted,
                    textCapitalization: TextCapitalization.none,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Nhập từ tiếng Anh...',
                      filled: true,
                      fillColor: _submitted
                          ? (_isCorrect! ? AppTheme.successColor.withValues(alpha: 0.08) : AppTheme.errorColor.withValues(alpha: 0.08))
                          : AppTheme.surface2Color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide(
                          color: _submitted
                              ? (_isCorrect! ? AppTheme.successColor : AppTheme.errorColor)
                              : AppTheme.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
                      ),
                      suffixIcon: _submitted
                          ? Icon(
                              _isCorrect! ? Icons.check_circle : Icons.cancel,
                              color: _isCorrect! ? AppTheme.successColor : AppTheme.errorColor,
                            )
                          : null,
                    ),
                  ),

                  // Feedback
                  if (_submitted) ...[
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_isCorrect!
                                ? AppTheme.successColor
                                : AppTheme.errorColor)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: (_isCorrect!
                              ? AppTheme.successColor
                              : AppTheme.errorColor).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isCorrect! ? Icons.check_circle_outline : Icons.info_outline,
                            color: _isCorrect! ? AppTheme.successColor : AppTheme.errorColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isCorrect! ? 'Chính xác!' : 'Đáp án đúng:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _isCorrect! ? AppTheme.successColor : AppTheme.errorColor,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      current.word,
                                      style: AppTheme.bodyLg.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textColor,
                                      ),
                                    ),
                                    if (current.ipa != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '/${current.ipa}/',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFD97706),
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Buttons
                  if (!_submitted)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Kiểm tra'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surface2Color,
                        ),
                        child: Text(
                          _currentIndex < _queue.length - 1 ? 'Từ tiếp theo →' : 'Xem kết quả',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult() {
    final pct = _vocab.isEmpty ? 0 : (_correctCount / _queue.length * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả kiểm tra')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                Text('$_correctCount / ${_queue.length} câu đúng', style: AppTheme.bodyMd),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _restart,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Làm lại'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Thoát'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Chi tiết', style: AppTheme.labelMd),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final r = _results[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: r.isCorrect
                        ? AppTheme.successColor.withValues(alpha: 0.06)
                        : AppTheme.errorColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: r.isCorrect
                          ? AppTheme.successColor.withValues(alpha: 0.2)
                          : AppTheme.errorColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        r.isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                        color: r.isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.definition,
                                style: AppTheme.titleMd.copyWith(fontSize: 14)),
                            Text('Đúng: ${r.word}', style: AppTheme.bodyMd),
                            if (!r.isCorrect)
                              Text('Bạn nhập: ${r.userAnswer}',
                                  style: AppTheme.bodyMd.copyWith(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TestResult {
  final String word, definition, userAnswer;
  final bool isCorrect;
  _TestResult({required this.word, required this.definition, required this.userAnswer, required this.isCorrect});
}
