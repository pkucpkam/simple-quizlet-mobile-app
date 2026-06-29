import 'package:flutter/material.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';

enum QuizOptionState { idle, correct, incorrect }

class QuizOptionWidget extends StatelessWidget {
  final String text;
  final QuizOptionState state;
  final VoidCallback? onTap;

  const QuizOptionWidget({
    super.key,
    required this.text,
    this.state = QuizOptionState.idle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget? icon;

    switch (state) {
      case QuizOptionState.correct:
        bgColor = AppTheme.successColor.withValues(alpha: 0.15);
        borderColor = AppTheme.successColor;
        textColor = AppTheme.successColor;
        icon = const Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 18);
        break;
      case QuizOptionState.incorrect:
        bgColor = AppTheme.errorColor.withValues(alpha: 0.12);
        borderColor = AppTheme.errorColor;
        textColor = AppTheme.errorColor;
        icon = const Icon(Icons.cancel_outlined, color: AppTheme.errorColor, size: 18);
        break;
      default:
        bgColor = AppTheme.surface2Color;
        borderColor = AppTheme.borderColor;
        textColor = AppTheme.textColor;
        icon = null;
    }

    return GestureDetector(
      onTap: state == QuizOptionState.idle ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (icon != null) icon,
          ],
        ),
      ),
    );
  }
}
