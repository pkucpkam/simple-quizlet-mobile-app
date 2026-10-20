import 'package:flutter/material.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(
          context: context,
          hasShadow: true,
          hasBorder: true,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.isDark(context)
                    ? const Color(0xFF242424)
                    : color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Center(child: Icon(icon, color: color, size: 20)),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTheme.displayMd(context).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textCol,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: AppTheme.bodySm(context).copyWith(color: text2Col),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
