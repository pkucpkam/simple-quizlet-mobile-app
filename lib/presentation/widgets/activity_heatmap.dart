import 'package:flutter/material.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/flickering_flame_widget.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';

/// GitHub-style activity heatmap calendar with an integrated Animated Flame Streak Banner.
/// Shows consecutive study streak, record milestone, and last N weeks of daily activity.
class ActivityHeatmap extends StatelessWidget {
  final Map<String, int> dailyActivity;
  final int? weeksToShow;

  const ActivityHeatmap({
    super.key,
    required this.dailyActivity,
    this.weeksToShow,
  });

  @override
  Widget build(BuildContext context) {
    final streak = _calculateCurrentStreak(dailyActivity);
    final longestStreak = _calculateLongestStreak(dailyActivity);
    final studiedToday = _hasActivityToday(dailyActivity);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Target cell size ~13px, minimum spacing 3px
        const targetCellWidth = 13.0;
        const cellSpacing = 3.0;

        // Dynamically calculate how many weeks fit across the container width
        int weeks = weeksToShow ??
            ((availableWidth + cellSpacing) / (targetCellWidth + cellSpacing)).floor();
        if (weeks < 8) weeks = 8;

        // Calculate exact cell size to fit 100% of available width perfectly
        final exactCellSize = ((availableWidth - (weeks - 1) * cellSpacing) / weeks)
            .clamp(10.0, 18.0);

        final days = _generateDays(weeks);
        final maxActivity = dailyActivity.values.isEmpty
            ? 1
            : dailyActivity.values.reduce((a, b) => a > b ? a : b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Animated Flickering Flame Streak Banner ──────────
            _StreakHeroBanner(
              streak: streak,
              longestStreak: longestStreak,
              studiedToday: studiedToday,
            ),
            const SizedBox(height: 16),

            // ── Divider ──────────────────────────────────────────────
            Container(
              height: 0.8,
              color: AppTheme.border(context).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 14),

            // ── 2. Heatmap Header ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lịch sử học tập',
                  style: AppTheme.labelMd(context).copyWith(
                    color: AppTheme.text2(context),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$weeks tuần qua',
                  style: AppTheme.bodySm(context).copyWith(
                    color: AppTheme.text3(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── 3. Heatmap Grid ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildWeekColumns(context, days, maxActivity, exactCellSize, weeks),
            ),
            const SizedBox(height: 12),

            // ── 4. Legend ────────────────────────────────────────────
            _buildLegend(context, maxActivity),
          ],
        );
      },
    );
  }

  // ── Streak Calculation Helpers ─────────────────────────────────────
  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static bool _hasActivityToday(Map<String, int> activity) {
    final todayStr = _formatDate(DateTime.now());
    return (activity[todayStr] ?? 0) > 0;
  }

  static int _calculateCurrentStreak(Map<String, int> activity) {
    if (activity.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = _formatDate(today);
    final yesterdayStr = _formatDate(today.subtract(const Duration(days: 1)));

    DateTime checkDate;
    if ((activity[todayStr] ?? 0) > 0) {
      checkDate = today;
    } else if ((activity[yesterdayStr] ?? 0) > 0) {
      checkDate = today.subtract(const Duration(days: 1));
    } else {
      return 0;
    }

    int streak = 0;
    while (true) {
      final dateStr = _formatDate(checkDate);
      if ((activity[dateStr] ?? 0) > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  static int _calculateLongestStreak(Map<String, int> activity) {
    if (activity.isEmpty) return 0;
    final activeDates = activity.entries
        .where((e) => e.value > 0)
        .map((e) => DateTime.tryParse(e.key))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    if (activeDates.isEmpty) return 0;

    int maxS = 1;
    int currentS = 1;
    for (int i = 1; i < activeDates.length; i++) {
      if (activeDates[i].difference(activeDates[i - 1]).inDays == 1) {
        currentS++;
        if (currentS > maxS) maxS = currentS;
      } else {
        currentS = 1;
      }
    }
    return maxS;
  }

  List<DateTime> _generateDays(int weeksCount) {
    final today = DateTime.now();
    final daysToShow = weeksCount * 7;
    return List.generate(
      daysToShow,
      (i) => DateTime(today.year, today.month, today.day - (daysToShow - 1 - i)),
    );
  }

  List<Widget> _buildWeekColumns(
    BuildContext context,
    List<DateTime> days,
    int maxActivity,
    double cellSize,
    int weeksCount,
  ) {
    final weeks = <List<DateTime>>[];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, (i + 7).clamp(0, days.length)));
    }

    return weeks.map((week) {
      return Column(
        children: week.map((day) {
          final dateStr = _formatDate(day);
          final count = dailyActivity[dateStr] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _buildCell(context, count, maxActivity, cellSize),
          );
        }).toList(),
      );
    }).toList();
  }

  Widget _buildCell(BuildContext context, int count, int maxActivity, double cellSize) {
    final accent = AppTheme.accent(context);
    final emptyColor = AppTheme.surface3(context);

    Color cellColor;
    if (count == 0) {
      cellColor = emptyColor;
    } else {
      final intensity = (count / maxActivity).clamp(0.25, 1.0);
      cellColor = accent.withValues(alpha: intensity);
    }

    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, int maxActivity) {
    final accent = AppTheme.accent(context);
    final emptyColor = AppTheme.surface3(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Thống kê theo ngày',
          style: AppTheme.bodySm(context).copyWith(fontSize: 10, color: AppTheme.text3(context)),
        ),
        Row(
          children: [
            Text('Ít hơn', style: AppTheme.bodySm(context).copyWith(fontSize: 10)),
            const SizedBox(width: 6),
            ...List.generate(5, (i) {
              final intensity = i == 0 ? 0.0 : (i / 4 * 0.8 + 0.2);
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? emptyColor
                        : accent.withValues(alpha: intensity),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text('Nhiều hơn', style: AppTheme.bodySm(context).copyWith(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

/// Hero Banner featuring the multi-layer Flickering Flame and Streak stats
class _StreakHeroBanner extends StatelessWidget {
  final int streak;
  final int longestStreak;
  final bool studiedToday;

  const _StreakHeroBanner({
    required this.streak,
    required this.longestStreak,
    required this.studiedToday,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);

    // Warm ambient background
    final bannerBg = isDark
        ? const Color(0xFF242424)
        : const Color(0xFFFFFBEB);

    String statusText;
    Color statusBadgeBg;
    Color statusBadgeText;
    IconData statusIcon;

    if (streak > 0 && studiedToday) {
      statusText = 'Đã giữ streak hôm nay';
      statusBadgeBg = AppTheme.accent(context).withValues(alpha: 0.15);
      statusBadgeText = AppTheme.accent(context);
      statusIcon = Icons.check_circle_rounded;
    } else if (streak > 0 && !studiedToday) {
      statusText = 'Học ngay để giữ chuỗi';
      statusBadgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      statusBadgeText = const Color(0xFFF59E0B);
      statusIcon = Icons.schedule_rounded;
    } else {
      statusText = 'Học hôm nay để tạo chuỗi';
      statusBadgeBg = AppTheme.surface3(context);
      statusBadgeText = text2Col;
      statusIcon = Icons.bolt_rounded;
    }

    String motivationalMessage;
    if (streak >= 14) {
      motivationalMessage = '🔥 Phong độ thần sầu! Bạn đang duy trì thói quen phi thường.';
    } else if (streak >= 7) {
      motivationalMessage = '✨ Rực cháy một tuần liên tiếp! Giữ vững ngọn lửa nhé.';
    } else if (streak >= 3) {
      motivationalMessage = '⚡ Chuỗi học tập ổn định! Thói quen đang hình thành rất tốt.';
    } else if (streak >= 1) {
      motivationalMessage = '🌱 Ngọn lửa đã thắp sáng! Tiếp tục bồi đắp mỗi ngày nhé.';
    } else {
      motivationalMessage = 'Thắp sáng ngọn lửa bằng một bài học từ vựng hôm nay!';
    }

    return PressableScale(
      scaleDown: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bannerBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: (isDark ? const Color(0xFFF59E0B) : const Color(0xFFF97316))
                  .withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Animated Flickering Flame ───────────────────────────
            FlickeringFlameWidget(
              size: 48,
              streakCount: streak,
            ),
            const SizedBox(width: 12),

            // ── Streak Counter & Motivational text ──────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$streak',
                        style: AppTheme.displayMd(context).copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFF59E0B),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ngày chuỗi',
                        style: AppTheme.titleSm(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: textCol,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Badge
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBadgeBg,
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 10, color: statusBadgeText),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  statusText,
                                  style: AppTheme.bodySm(context).copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: statusBadgeText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    motivationalMessage,
                    style: AppTheme.bodySm(context).copyWith(
                      color: text2Col,
                      fontSize: 11,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Longest Streak Trophy Pill ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C201B) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kỷ lục',
                    style: AppTheme.bodySm(context).copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: text2Col,
                    ),
                  ),
                  Text(
                    '$longestStreak d',
                    style: AppTheme.labelSm(context).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
