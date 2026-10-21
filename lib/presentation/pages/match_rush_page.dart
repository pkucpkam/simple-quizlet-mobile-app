import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/lesson_repository.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';

enum MatchGameState { loading, ready, playing, waveCleared, gameOver }

class MatchCardModel {
  final String id;
  final String pairId;
  final String text;
  final bool isEnglish;
  bool isMatched;
  bool isSelected;
  bool isError;

  MatchCardModel({
    required this.id,
    required this.pairId,
    required this.text,
    required this.isEnglish,
    this.isMatched = false,
    this.isSelected = false,
    this.isError = false,
  });
}

class MatchRushPage extends StatefulWidget {
  final String? lessonId;
  const MatchRushPage({super.key, this.lessonId});

  @override
  State<MatchRushPage> createState() => _MatchRushPageState();
}

class _MatchRushPageState extends State<MatchRushPage> with TickerProviderStateMixin {
  MatchGameState _gameState = MatchGameState.loading;
  String _pageTitle = 'Match Rush';
  List<VocabItemEntity> _allVocab = [];
  List<VocabItemEntity> _vocabPool = [];

  // Wave cards (12 cards)
  List<MatchCardModel> _currentCards = [];
  MatchCardModel? _firstSelected;
  MatchCardModel? _secondSelected;
  bool _isProcessing = false;

  // Game Stats
  int _score = 0;
  int _highScore = 0;
  bool _isNewRecord = false;
  int _combo = 0;
  int _maxCombo = 0;
  int _wave = 1;
  int _matchedPairsCount = 0;
  int _timeLeft = 60;
  Timer? _gameTimer;

  // Visual cues
  bool _showTimePenalty = false;
  bool _showTimeBonus = false;

  late AnimationController _comboScaleCtrl;
  late Animation<double> _comboScaleAnim;

  @override
  void initState() {
    super.initState();
    _comboScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _comboScaleAnim = Tween<double>(begin: 1.0, end: 1.25)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_comboScaleCtrl);

    _loadHighScore();
    _loadVocabulary();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _comboScaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    try {
      final prefs = injector<SharedPreferences>();
      final hs = prefs.getInt('match_rush_high_score') ?? 0;
      if (mounted) setState(() => _highScore = hs);
    } catch (_) {}
  }

  Future<void> _saveHighScore(int score) async {
    try {
      final prefs = injector<SharedPreferences>();
      await prefs.setInt('match_rush_high_score', score);
    } catch (_) {}
  }

  Future<void> _loadVocabulary() async {
    try {
      final repo = injector<LessonRepository>();
      List<VocabItemEntity> loaded = [];

      if (widget.lessonId != null && widget.lessonId!.isNotEmpty) {
        final lesson = await repo.getLessonDetail(widget.lessonId!);
        _pageTitle = lesson.title;
        loaded = lesson.vocabulary ?? [];
      } else {
        _pageTitle = 'Match Rush 60s';
        final publicLessons = await repo.getPublicLessons();
        for (final l in publicLessons.take(3)) {
          final detail = await repo.getLessonDetail(l.id);
          if (detail.vocabulary != null) {
            loaded.addAll(detail.vocabulary!);
          }
          if (loaded.length >= 24) break;
        }
      }

      // Filter out empty items
      loaded = loaded.where((v) => v.word.isNotEmpty && v.definition.isNotEmpty).toList();

      if (loaded.length < 4) {
        // Fallback default dictionary words if lesson lacks vocab
        loaded = const [
          VocabItemEntity(word: 'Apple', definition: 'Quả táo'),
          VocabItemEntity(word: 'Adventure', definition: 'Cuộc phiêu lưu'),
          VocabItemEntity(word: 'Brilliant', definition: 'Tuyệt vời, thông minh'),
          VocabItemEntity(word: 'Courage', definition: 'Lòng dũng cảm'),
          VocabItemEntity(word: 'Determine', definition: 'Quyết định, xác định'),
          VocabItemEntity(word: 'Energy', definition: 'Năng lượng'),
          VocabItemEntity(word: 'Freedom', definition: 'Sự tự do'),
          VocabItemEntity(word: 'Growth', definition: 'Sự phát triển'),
          VocabItemEntity(word: 'Inspire', definition: 'Truyền cảm hứng'),
          VocabItemEntity(word: 'Journey', definition: 'Chuyến hành trình'),
          VocabItemEntity(word: 'Knowledge', definition: 'Kiến thức'),
          VocabItemEntity(word: 'Legacy', definition: 'Di sản'),
        ];
      }

      if (mounted) {
        setState(() {
          _allVocab = loaded;
          _vocabPool = List.from(loaded)..shuffle();
          _gameState = MatchGameState.ready;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gameState = MatchGameState.ready);
      }
    }
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _combo = 0;
      _maxCombo = 0;
      _wave = 1;
      _matchedPairsCount = 0;
      _timeLeft = 60;
      _isNewRecord = false;
      _firstSelected = null;
      _secondSelected = null;
      _isProcessing = false;
      _vocabPool = List.from(_allVocab)..shuffle();
      _gameState = MatchGameState.playing;
    });

    _generateWave();
    _startTimer();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        _endGame();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _generateWave() {
    if (_vocabPool.length < 6) {
      _vocabPool.addAll(List.from(_allVocab)..shuffle());
    }

    final waveVocab = _vocabPool.take(6).toList();
    _vocabPool.removeRange(0, min(6, _vocabPool.length));

    final List<MatchCardModel> cards = [];
    for (int i = 0; i < waveVocab.length; i++) {
      final v = waveVocab[i];
      final pairId = 'pair_${v.word}_$i';
      cards.add(MatchCardModel(
        id: 'en_$pairId',
        pairId: pairId,
        text: v.word,
        isEnglish: true,
      ));
      cards.add(MatchCardModel(
        id: 'vi_$pairId',
        pairId: pairId,
        text: v.definition,
        isEnglish: false,
      ));
    }

    cards.shuffle(Random());

    setState(() {
      _currentCards = cards;
      _firstSelected = null;
      _secondSelected = null;
      _isProcessing = false;
    });
  }

  void _onCardTap(MatchCardModel card) {
    if (card.isMatched || _isProcessing || _gameState != MatchGameState.playing) return;

    HapticFeedback.selectionClick();

    // First card selected
    if (_firstSelected == null) {
      setState(() {
        _firstSelected = card;
        card.isSelected = true;
      });
      return;
    }

    // Tap on same card -> Deselect
    if (_firstSelected == card) {
      setState(() {
        card.isSelected = false;
        _firstSelected = null;
      });
      return;
    }

    // Tap on card with the same language -> Switch selection
    if (_firstSelected!.isEnglish == card.isEnglish) {
      setState(() {
        _firstSelected!.isSelected = false;
        _firstSelected = card;
        card.isSelected = true;
      });
      return;
    }

    // Second card of opposite language selected -> Evaluate match!
    setState(() {
      _secondSelected = card;
      card.isSelected = true;
      _isProcessing = true;
    });

    if (_firstSelected!.pairId == _secondSelected!.pairId) {
      _handleMatchSuccess();
    } else {
      _handleMatchError();
    }
  }

  void _handleMatchSuccess() {
    HapticFeedback.mediumImpact();

    final c1 = _firstSelected!;
    final c2 = _secondSelected!;

    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;

    // Spotify combo scale animation
    _comboScaleCtrl.forward(from: 0.0);

    // Score formula: Base 100 * Combo multiplier
    final earned = 100 * _combo;
    _score += earned;
    _matchedPairsCount++;

    Future.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      setState(() {
        c1.isMatched = true;
        c2.isMatched = true;
        c1.isSelected = false;
        c2.isSelected = false;
        _firstSelected = null;
        _secondSelected = null;
        _isProcessing = false;
      });

      // Check if wave is completed
      final allMatched = _currentCards.every((c) => c.isMatched);
      if (allMatched) {
        _handleWaveCompleted();
      }
    });
  }

  void _handleMatchError() {
    HapticFeedback.heavyImpact();

    final c1 = _firstSelected!;
    final c2 = _secondSelected!;

    setState(() {
      c1.isError = true;
      c2.isError = true;
      _combo = 0; // Reset combo
      // Penalty: deduct 2 seconds
      _timeLeft = max(0, _timeLeft - 2);
      _showTimePenalty = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        c1.isSelected = false;
        c2.isSelected = false;
        c1.isError = false;
        c2.isError = false;
        _firstSelected = null;
        _secondSelected = null;
        _isProcessing = false;
        _showTimePenalty = false;
      });

      if (_timeLeft <= 0) {
        _endGame();
      }
    });
  }

  void _handleWaveCompleted() {
    HapticFeedback.lightImpact();

    setState(() {
      _gameState = MatchGameState.waveCleared;
      _timeLeft += 3; // +3s bonus time
      _score += 500; // +500 wave clear bonus
      _showTimeBonus = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _wave++;
        _showTimeBonus = false;
        _gameState = MatchGameState.playing;
      });
      _generateWave();
    });
  }

  void _endGame() {
    _gameTimer?.cancel();

    if (_score > _highScore) {
      _isNewRecord = true;
      _highScore = _score;
      _saveHighScore(_score);
    }

    setState(() {
      _timeLeft = 0;
      _gameState = MatchGameState.gameOver;
    });

    HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppTheme.text(context), size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _pageTitle,
          style: AppTheme.titleSm(context).copyWith(fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242424) : AppTheme.surface2Color,
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, size: 14, color: AppTheme.warningColor),
                const SizedBox(width: 4),
                Text(
                  '$_highScore',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentStateView(context, isDark, accent),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView(BuildContext context, bool isDark, Color accent) {
    switch (_gameState) {
      case MatchGameState.loading:
        return Center(
          child: CircularProgressIndicator(color: accent),
        );
      case MatchGameState.ready:
        return _buildReadyScreen(context, isDark, accent);
      case MatchGameState.playing:
      case MatchGameState.waveCleared:
        return _buildPlayingScreen(context, isDark, accent);
      case MatchGameState.gameOver:
        return _buildGameOverScreen(context, isDark, accent);
    }
  }

  // ── Ready Screen ──────────────────────────────────────────────────
  Widget _buildReadyScreen(BuildContext context, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing Neon Badge
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A26) : accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt_rounded, size: 54, color: accent),
          ),
          const SizedBox(height: 24),

          Text(
            'MATCH RUSH 60S',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppTheme.text(context),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Ghép 6 cặp từ tiếng Anh và nghĩa tiếng Việt thật nhanh.\nCombo liên tục để nhân điểm số gấp bội!',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMd(context).copyWith(
                color: AppTheme.text2(context),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 36),

          // High score card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181818) : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.military_tech_rounded, color: AppTheme.warningColor, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KỶ LỤC CỦA BẠN', style: AppTheme.labelSm(context).copyWith(color: AppTheme.text3(context), fontSize: 10)),
                    Text(
                      '$_highScore ĐIỂM',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Start CTA
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                ),
              ),
              onPressed: _startGame,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 24, color: Colors.black),
                  const SizedBox(width: 6),
                  Text(
                    'BẮT ĐẦU NGAY',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Playing Screen ────────────────────────────────────────────────
  Widget _buildPlayingScreen(BuildContext context, bool isDark, Color accent) {
    final isLowTime = _timeLeft <= 10;
    final timeColor = isLowTime ? AppTheme.errorColor : accent;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            children: [
              // ── Header HUD: Wave, Timer, Score, Combo ──────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF181818) : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                ),
                child: Row(
                  children: [
                    // Wave badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF242424) : AppTheme.surface2Color,
                        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      ),
                      child: Text(
                        'WAVE $_wave',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.text(context),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Timer Display with -2s / +3s anim
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 18, color: timeColor),
                            const SizedBox(width: 5),
                            Text(
                              '${_timeLeft}s',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: timeColor,
                              ),
                            ),
                          ],
                        ),
                        if (_showTimePenalty)
                          Positioned(
                            top: -16,
                            child: Text(
                              '-2s',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                        if (_showTimeBonus)
                          Positioned(
                            top: -16,
                            child: Text(
                              '+3s',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),

                    // Score
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_score',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.text(context),
                          ),
                        ),
                        if (_combo > 1)
                          ScaleTransition(
                            scale: _comboScaleAnim,
                            child: Text(
                              '⚡ x$_combo',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── 12-Card Grid (3 cols x 4 rows) ────────────────────
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: _currentCards.length,
                  itemBuilder: (context, index) {
                    final card = _currentCards[index];
                    return _buildCardItem(context, card, isDark, accent);
                  },
                ),
              ),
            ],
          ),
        ),

        // Wave Cleared Flash Banner Overlay
        if (_gameState == MatchGameState.waveCleared)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A26) : accent.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'WAVE $_wave HOÀN THÀNH!',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+3s THỜI GIAN  •  +500 ĐIỂM',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardItem(
    BuildContext context,
    MatchCardModel card,
    bool isDark,
    Color accent,
  ) {
    if (card.isMatched) {
      // Invisible placeholder to keep grid geometry intact
      return const SizedBox();
    }

    Color cardBg;
    Color? borderColor;
    double borderWidth = 0;

    if (card.isError) {
      cardBg = isDark ? const Color(0xFF2E171B) : AppTheme.errorColor.withValues(alpha: 0.16);
      borderColor = AppTheme.errorColor;
      borderWidth = 1.8;
    } else if (card.isSelected) {
      cardBg = isDark ? const Color(0xFF143020) : accent.withValues(alpha: 0.16);
      borderColor = accent;
      borderWidth = 1.8;
    } else {
      cardBg = isDark ? const Color(0xFF242424) : AppTheme.surface2Color;
      borderColor = null;
      borderWidth = 0;
    }

    final textColor = card.isError
        ? AppTheme.errorColor
        : (card.isSelected
            ? accent
            : (isDark ? Colors.white : AppTheme.textColor));

    return PressableScale(
      onTap: () => _onCardTap(card),
      scaleDown: 0.93,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          border: borderColor != null
              ? Border.all(color: borderColor, width: borderWidth)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Language tag indicator (EN / VI)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: (card.isEnglish ? AppTheme.infoColor : AppTheme.warningColor)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                card.isEnglish ? 'EN' : 'VI',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: card.isEnglish ? AppTheme.infoColor : AppTheme.warningColor,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Card text
            Expanded(
              child: Center(
                child: Text(
                  card.text,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: card.isEnglish ? 13 : 11.5,
                    fontWeight: card.isEnglish ? FontWeight.w800 : FontWeight.w600,
                    color: textColor,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Game Over Screen ──────────────────────────────────────────────
  Widget _buildGameOverScreen(BuildContext context, bool isDark, Color accent) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A26) : accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isNewRecord ? Icons.emoji_events_rounded : Icons.timer_off_rounded,
                size: 44,
                color: _isNewRecord ? AppTheme.warningColor : accent,
              ),
            ),
            const SizedBox(height: 18),

            if (_isNewRecord)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                ),
                child: Text(
                  '🏆 KỶ LỤC MỚI!',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.warningColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

            Text(
              'HẾT GIỜ!',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.text(context),
              ),
            ),
            const SizedBox(height: 16),

            // Score Showcase
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181818) : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              ),
              child: Column(
                children: [
                  Text(
                    '$_score',
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  Text(
                    'TỔNG ĐIỂM ĐẠT ĐƯỢC',
                    style: AppTheme.labelSm(context).copyWith(
                      color: AppTheme.text3(context),
                      letterSpacing: 1.1,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(context, '$_matchedPairsCount', 'Cặp đã ghép', Icons.check_circle_outline),
                      _buildStatColumn(context, 'x$_maxCombo', 'Max Combo', Icons.bolt_rounded),
                      _buildStatColumn(context, 'Wave $_wave', 'Vòng đạt được', Icons.flag_outlined),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Actions
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                ),
                onPressed: _startGame,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 20, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      'CHƠI LẠI ⚡',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF242424) : AppTheme.surface2Color,
                  foregroundColor: isDark ? Colors.white : AppTheme.textColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                ),
                onPressed: () => context.pop(),
                child: Text(
                  'QUAY LẠI',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.text3(context)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.text(context),
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySm(context).copyWith(
            fontSize: 10.5,
            color: AppTheme.text3(context),
          ),
        ),
      ],
    );
  }
}
