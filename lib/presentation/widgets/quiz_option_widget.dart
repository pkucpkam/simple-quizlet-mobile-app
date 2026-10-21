import 'package:flutter/material.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';

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
    final success = AppTheme.accent(context);
    final error = AppTheme.errorColor;
    final surface2 = AppTheme.surface2(context);
    final borderCol = AppTheme.border(context);
    final textCol = AppTheme.text(context);

    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget? icon;

    final isDark = AppTheme.isDark(context);

    switch (state) {
      case QuizOptionState.correct:
        bgColor = isDark ? const Color(0xFF143020) : success.withValues(alpha: 0.16);
        borderColor = success;
        textColor = success;
        icon = Icon(Icons.check_circle_rounded, color: success, size: 20);
        break;
      case QuizOptionState.incorrect:
        bgColor = isDark ? const Color(0xFF2E171B) : error.withValues(alpha: 0.14);
        borderColor = error;
        textColor = error;
        icon = Icon(Icons.cancel_rounded, color: error, size: 20);
        break;
      default:
        bgColor = isDark ? const Color(0xFF242424) : surface2;
        borderColor = borderCol;
        textColor = textCol;
        icon = null;
    }

    return PressableScale(
      onTap: state == QuizOptionState.idle ? onTap : null,
      scaleDown: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          border: (!isDark)
              ? Border.all(color: borderColor, width: state == QuizOptionState.idle ? 1.0 : 1.6)
              : null,
          boxShadow: AppTheme.shadow(context),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: state == QuizOptionState.idle ? FontWeight.w500 : FontWeight.w700,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              icon,
            ],
          ],
        ),
      ),
    );
  }
}
