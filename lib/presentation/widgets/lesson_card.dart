import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppTheme.cardDecoration(hasShadow: true),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Center(
                    child: Icon(Icons.menu_book_rounded, color: AppTheme.accentColor, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              lesson.title,
                              style: AppTheme.titleSm,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lesson.isOfficial) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: AppTheme.pillDecoration(
                                background: AppTheme.accentColor.withValues(alpha: 0.15),
                                border: AppTheme.accentDark.withValues(alpha: 0.4),
                              ),
                              child: Text(
                                'OFFICIAL',
                                style: AppTheme.labelSm.copyWith(
                                  color: AppTheme.accentColor,
                                  fontSize: 9,
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
                            style: AppTheme.bodySm,
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
                const Icon(Icons.layers_outlined, size: 13, color: AppTheme.text3Color),
                const SizedBox(width: 4),
                Text('${lesson.wordCount} từ', style: AppTheme.bodySm),
                const SizedBox(width: 14),
                const Icon(Icons.person_outline, size: 13, color: AppTheme.text3Color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lesson.creator,
                    style: AppTheme.bodySm,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yy').format(lesson.createdAt),
                  style: AppTheme.bodySm,
                ),
              ],
            ),

            if (onStudy != null || onReview != null || onTest != null) ...[
              const SizedBox(height: 12),
              Container(height: 0.8, color: AppTheme.borderColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onStudy != null)
                    _ActionChip(
                      label: 'FLASHCARD',
                      icon: Icons.layers_outlined,
                      color: AppTheme.infoColor,
                      onTap: onStudy!,
                    ),
                  if (onStudy != null && onReview != null) const SizedBox(width: 8),
                  if (onReview != null)
                    _ActionChip(
                      label: 'ÔN TẬP',
                      icon: Icons.menu_book_outlined,
                      color: AppTheme.accentColor,
                      onTap: onReview!,
                    ),
                  if (onReview != null && onTest != null) const SizedBox(width: 8),
                  if (onTest != null)
                    _ActionChip(
                      label: 'THI',
                      icon: Icons.edit_note_outlined,
                      color: AppTheme.warningColor,
                      onTap: onTest!,
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
  const _ActionChip({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: AppTheme.pillDecoration(
          background: color.withValues(alpha: 0.12),
          border: color.withValues(alpha: 0.25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.labelSm.copyWith(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
