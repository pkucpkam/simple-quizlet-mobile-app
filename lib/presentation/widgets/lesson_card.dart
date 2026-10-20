import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';

class LessonCard extends StatelessWidget {
  final LessonEntity lesson;
  final VoidCallback onTap;
  final VoidCallback? onStudy;
  final VoidCallback? onReview;
  final VoidCallback? onTest;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
    this.onStudy,
    this.onReview,
    this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);
    final text3Col = AppTheme.text3(context);

    return PressableScale(
      onTap: onTap,
      scaleDown: 0.98,
      child: Container(
        decoration: AppTheme.cardDecoration(
          context: context,
          hasShadow: true,
          hasBorder: true,
          radius: AppTheme.radiusMd,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.isDark(context)
                        ? const Color(0xFF242424)
                        : accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Center(
                    child: Icon(Icons.menu_book_rounded, color: accent, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              lesson.title,
                              style: AppTheme.titleSm(context).copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lesson.isOfficial) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              child: Text(
                                'OFFICIAL',
                                style: AppTheme.labelSm(context).copyWith(
                                  color: accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (lesson.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            lesson.description,
                            style: AppTheme.bodySm(context).copyWith(color: text2Col),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Meta row
            Row(
              children: [
                Icon(Icons.layers_outlined, size: 14, color: text3Col),
                const SizedBox(width: 4),
                Text(
                  '${lesson.wordCount} từ',
                  style: AppTheme.bodySm(context).copyWith(
                    color: text2Col,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.person_outline, size: 14, color: text3Col),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lesson.creator,
                    style: AppTheme.bodySm(context).copyWith(color: text3Col),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yy').format(lesson.createdAt),
                  style: AppTheme.bodySm(context).copyWith(color: text3Col),
                ),
              ],
            ),

            if (onStudy != null || onReview != null || onTest != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (onStudy != null)
                    Expanded(
                      child: _ActionChip(
                        label: 'FLASHCARD',
                        icon: Icons.layers_outlined,
                        color: AppTheme.infoColor,
                        onTap: onStudy!,
                      ),
                    ),
                  if (onStudy != null && onReview != null) const SizedBox(width: 8),
                  if (onReview != null)
                    Expanded(
                      child: _ActionChip(
                        label: 'ÔN TẬP',
                        icon: Icons.menu_book_outlined,
                        color: accent,
                        onTap: onReview!,
                      ),
                    ),
                  if (onReview != null && onTest != null) const SizedBox(width: 8),
                  if (onTest != null)
                    Expanded(
                      child: _ActionChip(
                        label: 'THI',
                        icon: Icons.edit_note_outlined,
                        color: AppTheme.warningColor,
                        onTap: onTest!,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final chipBg = isDark
        ? const Color(0xFF242424)
        : AppTheme.lightSurface2Color;
    final contentColor = isDark ? Colors.white : AppTheme.lightTextColor;

    return PressableScale(
      onTap: onTap,
      scaleDown: 0.94,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: AppTheme.labelSm(context).copyWith(
                  color: contentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
