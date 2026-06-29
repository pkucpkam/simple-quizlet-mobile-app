import 'package:flutter/material.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/folder_entity.dart';

class FolderCard extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback onTap;

  const FolderCard({super.key, required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(folder.color);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderColor),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Center(
                child: Text(
                  folder.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              folder.name,
              style: AppTheme.bodyMd.copyWith(
                color: AppTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (folder.lessonCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${folder.lessonCount} bài',
                  style: AppTheme.bodySm,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.accentColor;
    }
  }
}
