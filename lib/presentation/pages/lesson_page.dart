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
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
          );
        }
        if (state is LessonError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Lỗi: ${state.message}', style: AppTheme.bodyMd)),
          );
        }
        if (state is LessonLoaded) {
          final lesson = state.lesson;
          final vocab = lesson.vocabulary ?? [];

          return Scaffold(
            body: CustomScrollView(
              slivers: [
                // Gradient Header
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppTheme.surfaceColor,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    color: AppTheme.textColor,
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: lesson.isOfficial
                              ? [AppTheme.surface2Color, AppTheme.bgColor]
                              : [AppTheme.accentColor.withValues(alpha: 0.12), AppTheme.bgColor],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.menu_book_rounded, color: AppTheme.accentColor, size: 26),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(lesson.title,
                                                  style: AppTheme.titleLg, maxLines: 2, overflow: TextOverflow.ellipsis),
                                            ),
                                            if (lesson.isOfficial)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentColor.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text('Official',
                                                    style: const TextStyle(fontSize: 10, color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(lesson.description.isEmpty
                                            ? 'Khám phá từ vựng tiếng Anh'
                                            : lesson.description,
                                            style: AppTheme.bodyMd, maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('Tạo bởi: ${lesson.creator}', style: AppTheme.bodySm),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.textColor.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: Column(
                                      children: [
                                        Text('${lesson.wordCount}',
                                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                                        Text('từ', style: AppTheme.bodySm.copyWith(fontSize: 10, color: AppTheme.text2Color)),
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

                // Action Buttons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          _ActionButton(
                            label: 'Flashcard',
                            icon: Icons.layers_outlined,
                            color: const Color(0xFF2563EB),
                            onTap: () => context.push('/study/${lesson.id}'),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            label: 'Ôn tập',
                            icon: Icons.menu_book_outlined,
                            color: AppTheme.successColor,
                            onTap: () => context.push('/review/${lesson.id}'),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            label: 'Kiểm tra',
                            icon: Icons.edit_note_outlined,
                            color: AppTheme.accentColor,
                            onTap: () => context.push('/test/${lesson.id}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Vocabulary Table Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'DANH SÁCH TỪ VỰNG (${vocab.length})',
                      style: AppTheme.labelMd,
                    ),
                  ),
                ),

                // Vocabulary list
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
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.accentColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.word,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                        if (item.wordType != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(item.wordType!,
                                style: const TextStyle(fontSize: 10, color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    if (item.ipa != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('/${item.ipa}/',
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'monospace', color: Color(0xFF60A5FA))),
                      ),
                    const SizedBox(height: 6),
                    Text(item.definition, style: AppTheme.bodyMd.copyWith(color: AppTheme.text2Color)),
                    if (item.exampleEn != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface2Color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('"${item.exampleEn}"',
                                  style: AppTheme.bodyMd.copyWith(fontStyle: FontStyle.italic, color: AppTheme.textColor)),
                              if (item.exampleVi != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
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
        ],
      ),
    );
  }
}
