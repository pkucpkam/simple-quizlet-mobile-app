import 'package:flutter/material.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';

/// GitHub-style activity heatmap calendar showing last N weeks of activity,
/// automatically stretching to fill 100% of the available container width.
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hoạt động học tập',
                  style: AppTheme.labelMd.copyWith(
                    color: AppTheme.text2Color,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$weeks tuần qua',
                  style: AppTheme.bodySm.copyWith(
                    color: AppTheme.text3Color,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildWeekColumns(days, maxActivity, exactCellSize, weeks),
            ),
            const SizedBox(height: 10),
            _buildLegend(maxActivity),
          ],
        );
      },
    );
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
          final dateStr =
              '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
          final count = dailyActivity[dateStr] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _buildCell(count, maxActivity, cellSize),
          );
        }).toList(),
      );
    }).toList();
  }

  Widget _buildCell(int count, int maxActivity, double cellSize) {
    Color cellColor;
    if (count == 0) {
      cellColor = AppTheme.surface3Color;
    } else {
      final intensity = (count / maxActivity).clamp(0.2, 1.0);
      cellColor = AppTheme.accentColor.withValues(alpha: intensity);
    }

    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2),
        border: count > 0
            ? Border.all(
                color: AppTheme.accentColor.withValues(alpha: 0.25),
                width: 0.5,
              )
            : null,
      ),
    );
  }

  Widget _buildLegend(int maxActivity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Thống kê theo ngày',
          style: AppTheme.bodySm.copyWith(fontSize: 10, color: AppTheme.text3Color),
        ),
        Row(
          children: [
            Text('Ít hơn', style: AppTheme.bodySm.copyWith(fontSize: 10)),
            const SizedBox(width: 6),
            ...List.generate(5, (i) {
              final intensity = i == 0 ? 0.0 : (i / 4 * 0.8 + 0.15);
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? AppTheme.surface3Color
                        : AppTheme.accentColor.withValues(alpha: intensity),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text('Nhiều hơn', style: AppTheme.bodySm.copyWith(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
