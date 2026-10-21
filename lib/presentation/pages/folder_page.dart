import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/folder/folder_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/lesson_card.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/staggered_fade_slide.dart';

class FolderPage extends StatefulWidget {
  final String folderId;
  const FolderPage({super.key, required this.folderId});

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  @override
  void initState() {
    super.initState();
    context.read<FolderBloc>().add(FolderLoadRequested(widget.folderId));
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);

    return BlocBuilder<FolderBloc, FolderState>(
      builder: (context, state) {
        if (state is FolderLoading) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(backgroundColor: bg),
            body: Center(child: CircularProgressIndicator(color: accent)),
          );
        }
        if (state is FolderError) {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(backgroundColor: bg),
            body: Center(child: Text('Lỗi: ${state.message}', style: AppTheme.bodyMd(context))),
          );
        }
        if (state is FolderLoaded) {
          final folder = state.folder;
          final color = _parseColor(folder.color, context);

          return Scaffold(
            backgroundColor: bg,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverAppBar(
                  expandedHeight: 170,
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
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.2),
                            bg,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                          child: Row(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: AppTheme.isDark(context)
                                      ? const Color(0xFF242424)
                                      : color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: Center(
                                  child: Text(folder.icon, style: const TextStyle(fontSize: 28)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      folder.name,
                                      style: AppTheme.titleLg(context).copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (folder.description.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(
                                          folder.description,
                                          style: AppTheme.bodyMd(context).copyWith(color: text2Col),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        '${state.lessons.length} bài học',
                                        style: AppTheme.bodySm(context).copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Lessons
                if (state.lessons.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Text('📂', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('Thư mục chưa có bài học', style: AppTheme.bodyMd(context)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final lesson = state.lessons[index];
                          return StaggeredFadeSlide(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LessonCard(
                                lesson: lesson,
                                onTap: () => context.push('/lesson/${lesson.id}'),
                                onStudy: () => context.push('/study/${lesson.id}'),
                                onReview: () => context.push('/review/${lesson.id}'),
                                onTest: () => context.push('/test/${lesson.id}'),
                              ),
                            ),
                          );
                        },
                        childCount: state.lessons.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        return Scaffold(backgroundColor: bg);
      },
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
