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
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderColor),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lesson.title,
                              style: AppTheme.titleMd,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lesson.isOfficial)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'Official',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (lesson.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.layers_outlined, size: 14, color: AppTheme.text3Color),
                const SizedBox(width: 4),
                Text('${lesson.wordCount} từ', style: AppTheme.bodySm),
                const SizedBox(width: 12),
                Icon(Icons.person_outline, size: 14, color: AppTheme.text3Color),
                const SizedBox(width: 4),
                Text(lesson.creator, style: AppTheme.bodySm),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yy').format(lesson.createdAt),
                  style: AppTheme.bodySm,
                ),
              ],
            ),
            if (onStudy != null || onReview != null || onTest != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (onStudy != null)
                    _ActionBtn(label: 'Flashcard', color: const Color(0xFF2563EB), onTap: onStudy!),
                  if (onStudy != null && onReview != null) const SizedBox(width: 6),
                  if (onReview != null)
                    _ActionBtn(label: 'Ôn tập', color: AppTheme.successColor, onTap: onReview!),
                  if (onReview != null && onTest != null) const SizedBox(width: 6),
                  if (onTest != null)
                    _ActionBtn(label: 'Kiểm tra', color: AppTheme.accentColor, onTap: onTest!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
