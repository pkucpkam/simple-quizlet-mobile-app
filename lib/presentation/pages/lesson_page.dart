import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/lesson/lesson_bloc.dart';

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
    return BlocBuilder<LessonBloc, LessonState>(
      builder: (context, state) {
        if (state is LessonLoading) {
          return Scaffold(
            backgroundColor: AppTheme.bgColor,
            appBar: AppBar(backgroundColor: AppTheme.bgColor),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is LessonError) {
          return Scaffold(
            backgroundColor: AppTheme.bgColor,
            appBar: AppBar(backgroundColor: AppTheme.bgColor),
            body: Center(child: Text('Lỗi: ${state.message}', style: AppTheme.bodyMd)),
          );
        }
        if (state is LessonLoaded) {
          final lesson = state.lesson;
          final vocab = lesson.vocabulary ?? [];

          return Scaffold(
            backgroundColor: AppTheme.bgColor,
            body: CustomScrollView(
              slivers: [
                // ── Gradient Header ───────────────────────────
                SliverAppBar(
                  expandedHeight: 210,
                  pinned: true,
                  backgroundColor: AppTheme.bgColor,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2Color.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppTheme.textColor),
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
                                  AppTheme.accentColor.withValues(alpha: 0.18),
                                  AppTheme.bgColor,
                                ]
                              : [
                                  AppTheme.infoColor.withValues(alpha: 0.15),
                                  AppTheme.bgColor,
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
                                  // Album art style icon
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: lesson.isOfficial
                                            ? [
                                                AppTheme.accentColor.withValues(alpha: 0.8),
                                                AppTheme.accentDark,
                                              ]
                                            : [
                                                AppTheme.infoColor.withValues(alpha: 0.8),
                                                const Color(0xFF1D4ED8),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      boxShadow: AppTheme.shadowHeavy,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
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
                                          ),
                                        Text(
                                          lesson.title,
                                          style: AppTheme.titleLg,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lesson.description.isEmpty
                                              ? 'Khám phá từ vựng tiếng Anh'
                                              : lesson.description,
                                          style: AppTheme.bodyMd,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text('by ${lesson.creator}', style: AppTheme.bodySm),
                                      ],
                                    ),
                                  ),
                                  // Word count badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface2Color,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      border: Border.all(color: AppTheme.borderColor, width: 0.8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${lesson.wordCount}',
                                          style: AppTheme.displayMd.copyWith(fontSize: 24),
                                        ),
                                        Text('từ', style: AppTheme.bodySm.copyWith(fontSize: 10)),
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
                        const SizedBox(width: 10),
                        _ActionButton(
                          label: 'ÔN TẬP',
                          icon: Icons.menu_book_outlined,
                          color: AppTheme.accentColor,
                          onTap: () => context.push('/review/${lesson.id}'),
                        ),
                        const SizedBox(width: 10),
                        _ActionButton(
                          label: 'THI',
                          icon: Icons.edit_note_outlined,
                          color: AppTheme.warningColor,
                          onTap: () => context.push('/test/${lesson.id}'),
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
                      style: AppTheme.labelMd,
                    ),
                  ),
                ),

                // ── Vocabulary list ───────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = vocab[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _VocabItemCard(item: item, index: index),
                      );
                    },
                    childCount: vocab.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        }
        return const Scaffold();
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTheme.labelSm.copyWith(color: color, fontSize: 10),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(hasShadow: false, hasBorder: true),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index badge
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTheme.labelSm.copyWith(
                  color: AppTheme.accentColor,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.word,
                      style: AppTheme.titleSm,
                    ),
                    if (item.wordType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: AppTheme.pillDecoration(
                          background: AppTheme.warningColor.withValues(alpha: 0.1),
                          border: AppTheme.warningColor.withValues(alpha: 0.3),
                        ),
                        child: Text(
                          item.wordType!,
                          style: AppTheme.bodySm.copyWith(
                            color: AppTheme.warningColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.ipa != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '/${item.ipa}/',
                      style: AppTheme.bodySm.copyWith(
                        color: AppTheme.infoColor,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(item.definition, style: AppTheme.bodyMd),
                if (item.exampleEn != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2Color,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.borderColor, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"${item.exampleEn}"',
                            style: AppTheme.bodyMd.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textColor,
                            ),
                          ),
                          if (item.exampleVi != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(item.exampleVi!, style: AppTheme.bodySm),
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
