import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/lesson/lesson_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/staggered_fade_slide.dart';

class LessonPage extends StatefulWidget {
  final String lessonId;
  const LessonPage({super.key, required this.lessonId});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  @override
  void initState() {
    super.initState();
    context.read<LessonBloc>().add(LessonLoadRequested(widget.lessonId));
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);
    final text3Col = AppTheme.text3(context);

    return BlocBuilder<LessonBloc, LessonState>(
      builder: (context, state) {
        if (state is LessonLoading) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(backgroundColor: bg),
            body: Center(child: CircularProgressIndicator(color: accent)),
          );
        }
        if (state is LessonError) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(backgroundColor: bg),
            body: Center(child: Text('Lỗi: ${state.message}', style: AppTheme.bodyMd(context))),
          );
        }
        if (state is LessonLoaded) {
          final lesson = state.lesson;
          final vocab = lesson.vocabulary ?? [];

          return Scaffold(
            backgroundColor: bg,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Gradient Header ───────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: bg,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2(context).withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 16, color: textCol),
                    ),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: lesson.isOfficial
                              ? [
                                  accent.withValues(alpha: 0.2),
                                  bg,
                                ]
                              : [
                                  AppTheme.infoColor.withValues(alpha: 0.18),
                                  bg,
                                ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 56, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: lesson.isOfficial
                                            ? [accent, AppTheme.accentDark]
                                            : [AppTheme.infoColor, const Color(0xFF0284C7)],
                                      ),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (lesson.isOfficial ? accent : AppTheme.infoColor).withValues(alpha: 0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 30),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (lesson.isOfficial)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: AppTheme.pillDecoration(
                                                context: context,
                                                background: accent.withValues(alpha: 0.15),
                                                border: accent.withValues(alpha: 0.4),
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
                                          ),
                                        Text(
                                          lesson.title,
                                          style: AppTheme.titleLg(context).copyWith(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: textCol,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lesson.description.isEmpty
                                              ? 'Khám phá từ vựng tiếng Anh'
                                              : lesson.description,
                                          style: AppTheme.bodyMd(context).copyWith(color: text2Col),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text('by ${lesson.creator}', style: AppTheme.bodySm(context).copyWith(color: text3Col)),
                                      ],
                                    ),
                                  ),
                                  // Word count badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.isDark(context) ? const Color(0xFF242424) : AppTheme.surface2(context),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${lesson.wordCount}',
                                          style: AppTheme.displayMd(context).copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                                        ),
                                        Text('từ', style: AppTheme.bodySm(context).copyWith(fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Action Buttons ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        _ActionButton(
                          label: 'FLASHCARD',
                          icon: Icons.layers_outlined,
                          color: AppTheme.infoColor,
                          onTap: () => context.push('/study/${lesson.id}'),
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          label: 'ÔN TẬP',
                          icon: Icons.menu_book_outlined,
                          color: accent,
                          onTap: () => context.push('/review/${lesson.id}'),
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          label: 'THI',
                          icon: Icons.edit_note_outlined,
                          color: AppTheme.warningColor,
                          onTap: () => context.push('/test/${lesson.id}'),
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          label: 'MATCH',
                          icon: Icons.bolt_rounded,
                          color: const Color(0xFFF43F5E),
                          onTap: () => context.push('/match/${lesson.id}'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Vocab Header ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      'TỪ VỰNG (${vocab.length})',
                      style: AppTheme.labelMd(context).copyWith(color: text2Col, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                // ── Vocabulary list ───────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = vocab[index];
                      return StaggeredFadeSlide(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _VocabItemCard(item: item, index: index),
                        ),
                      );
                    },
                    childCount: vocab.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 36)),
              ],
            ),
          );
        }
        return Scaffold(backgroundColor: bg);
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final btnBg = isDark
        ? const Color(0xFF242424)
        : color.withValues(alpha: 0.12);
    final fgColor = isDark ? Colors.white : color;

    return Expanded(
      child: PressableScale(
        onTap: onTap,
        scaleDown: 0.94,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTheme.labelSm(context).copyWith(
                  color: fgColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VocabItemCard extends StatelessWidget {
  final VocabItemEntity item;
  final int index;
  const _VocabItemCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(
        context: context,
        hasShadow: true,
        hasBorder: true,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index badge
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTheme.labelSm(context).copyWith(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.word,
                      style: AppTheme.titleSm(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textCol,
                      ),
                    ),
                    if (item.wordType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: AppTheme.pillDecoration(
                          context: context,
                          background: AppTheme.warningColor.withValues(alpha: 0.12),
                          border: AppTheme.warningColor.withValues(alpha: 0.35),
                        ),
                        child: Text(
                          item.wordType!,
                          style: AppTheme.bodySm(context).copyWith(
                            color: AppTheme.warningColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.ipa != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '/${item.ipa}/',
                      style: AppTheme.bodySm(context).copyWith(
                        color: AppTheme.infoColor,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(item.definition, style: AppTheme.bodyMd(context).copyWith(color: text2Col)),
                if (item.exampleEn != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.isDark(context) ? const Color(0xFF202020) : AppTheme.surface2(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"${item.exampleEn}"',
                            style: AppTheme.bodyMd(context).copyWith(
                              fontStyle: FontStyle.italic,
                              color: textCol,
                            ),
                          ),
                          if (item.exampleVi != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(item.exampleVi!, style: AppTheme.bodySm(context)),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
