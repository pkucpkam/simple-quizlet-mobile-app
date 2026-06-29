import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/folder/folder_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/lesson_card.dart';

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
    return BlocBuilder<FolderBloc, FolderState>(
      builder: (context, state) {
        if (state is FolderLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
          );
        }
        if (state is FolderError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Lỗi: ${state.message}', style: AppTheme.bodyMd)),
          );
        }
        if (state is FolderLoaded) {
          final folder = state.folder;
          final color = _parseColor(folder.color);

          return Scaffold(
            body: CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  expandedHeight: 160,
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
                          colors: [
                            color.withValues(alpha: 0.15),
                            AppTheme.bgColor,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(color: color.withValues(alpha: 0.3)),
                                ),
                                child: Center(
                                  child: Text(folder.icon, style: const TextStyle(fontSize: 26)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(folder.name, style: AppTheme.titleLg),
                                    if (folder.description.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(
                                          folder.description,
                                          style: AppTheme.bodyMd,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${state.lessons.length} bài học',
                                        style: AppTheme.bodySm.copyWith(color: color),
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
                            Text('Thư mục chưa có bài học', style: AppTheme.bodyMd),
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LessonCard(
                              lesson: lesson,
                              onTap: () => context.push('/lesson/${lesson.id}'),
                              onStudy: () => context.push('/study/${lesson.id}'),
                              onReview: () => context.push('/review/${lesson.id}'),
                              onTest: () => context.push('/test/${lesson.id}'),
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
        return const Scaffold();
      },
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
