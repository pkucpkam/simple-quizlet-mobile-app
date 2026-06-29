import 'package:flutter/material.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';

/// GitHub-style activity heatmap calendar showing last N weeks of activity
class ActivityHeatmap extends StatelessWidget {
  final Map<String, int> dailyActivity;
  final int weeksToShow;

  const ActivityHeatmap({
    super.key,
    required this.dailyActivity,
    this.weeksToShow = 16,
  });

  @override
  Widget build(BuildContext context) {
    final days = _generateDays();
    final maxActivity = dailyActivity.values.isEmpty
        ? 1
        : dailyActivity.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoạt động học tập',
          style: AppTheme.labelMd.copyWith(
            color: AppTheme.text2Color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildWeekColumns(days, maxActivity),
          ),
        ),
        const SizedBox(height: 6),
        _buildLegend(maxActivity),
      ],
    );
  }

  List<DateTime> _generateDays() {
    final today = DateTime.now();
    final daysToShow = weeksToShow * 7;
    return List.generate(
      daysToShow,
      (i) => DateTime(today.year, today.month, today.day - (daysToShow - 1 - i)),
    );
  }

  List<Widget> _buildWeekColumns(List<DateTime> days, int maxActivity) {
    final weeks = <List<DateTime>>[];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, (i + 7).clamp(0, days.length)));
    }

    return weeks.map((week) {
      return Padding(
        padding: const EdgeInsets.only(right: 3),
        child: Column(
          children: week.map((day) {
            final dateStr =
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final count = dailyActivity[dateStr] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: _buildCell(count, maxActivity),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Widget _buildCell(int count, int maxActivity) {
    Color cellColor;
    if (count == 0) {
      cellColor = AppTheme.surface2Color;
    } else {
      final intensity = (count / maxActivity).clamp(0.15, 1.0);
      cellColor = AppTheme.accentColor.withValues(alpha: intensity);
    }

    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: count > 0
              ? AppTheme.accentColor.withValues(alpha: 0.2)
              : AppTheme.borderColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
    );
  }

  Widget _buildLegend(int maxActivity) {
    return Row(
      children: [
        Text('Ít hơn', style: AppTheme.bodySm.copyWith(fontSize: 10)),
        const SizedBox(width: 4),
        ...List.generate(5, (i) {
          final intensity = i == 0 ? 0.0 : (i / 4 * 0.8 + 0.15);
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: i == 0
                    ? AppTheme.surface2Color
                    : AppTheme.accentColor.withValues(alpha: intensity),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text('Nhiều hơn', style: AppTheme.bodySm.copyWith(fontSize: 10)),
      ],
    );
  }
}
