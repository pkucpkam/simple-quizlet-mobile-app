import 'package:flutter/material.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/folder_entity.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';

class FolderCard extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback onTap;

  const FolderCard({super.key, required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(folder.color, context);
    final textCol = AppTheme.text(context);
    final text3Col = AppTheme.text3(context);

    return PressableScale(
      onTap: onTap,
      scaleDown: 0.95,
      child: Container(
        decoration: AppTheme.cardDecoration(
          context: context,
          hasShadow: true,
          hasBorder: true,
          radius: AppTheme.radiusMd,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with color glow
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.isDark(context)
                    ? const Color(0xFF242424)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Center(
                child: Text(
                  folder.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              folder.name,
              style: AppTheme.titleSm(context).copyWith(
                color: textCol,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (folder.lessonCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${folder.lessonCount} bài',
                  style: AppTheme.bodySm(context).copyWith(
                    color: text3Col,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorStr, BuildContext context) {
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.accent(context);
    }
  }
}
