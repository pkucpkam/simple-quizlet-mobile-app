import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/my_lessons/my_lessons_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/lesson_card.dart';

class MyLessonsPage extends StatefulWidget {
  const MyLessonsPage({super.key});

  @override
  State<MyLessonsPage> createState() => _MyLessonsPageState();
}

class _MyLessonsPageState extends State<MyLessonsPage> {
  @override
  void initState() {
    super.initState();
    _loadMyLessons();
  }

  void _loadMyLessons() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final username = authState.user.username;
      context.read<MyLessonsBloc>().add(MyLessonsLoadRequested(username));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final username = authState is AuthAuthenticated ? authState.user.username : '';

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor,
        title: const Text('Bài học của tôi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: Text('Tạo bài học', style: AppTheme.labelSm.copyWith(color: Colors.black)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tính năng Tạo bài học trên mobile sẽ có ở phiên bản tiếp theo!'),
            ),
          );
        },
      ),
      body: BlocBuilder<MyLessonsBloc, MyLessonsState>(
        builder: (context, state) {
          if (state is MyLessonsLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
          }

          if (state is MyLessonsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 48),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${state.message}', style: AppTheme.bodyMd),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _loadMyLessons,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is MyLessonsLoaded) {
            final lessons = state.lessons;

            return RefreshIndicator(
              color: AppTheme.accentColor,
              backgroundColor: AppTheme.surfaceColor,
              onRefresh: () async => _loadMyLessons(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Banner Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentColor.withValues(alpha: 0.15),
                          AppTheme.surface2Color,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: AppTheme.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.folder_shared_outlined, color: AppTheme.accentColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(username, style: AppTheme.titleSm),
                              const SizedBox(height: 4),
                              Text(
                                '${lessons.length} bài học đã tạo',
                                style: AppTheme.bodySm.copyWith(color: AppTheme.accentColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (lessons.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            const Text('📝', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text('Bạn chưa tạo bài học nào', style: AppTheme.titleSm),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy tạo bài học mới trên web hoặc nút bên dưới!',
                              style: AppTheme.bodySm,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...lessons.map(
                      (lesson) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LessonCard(
                          lesson: lesson,
                          onTap: () => context.push('/lesson/${lesson.id}'),
                          onStudy: () => context.push('/study/${lesson.id}'),
                          onReview: () => context.push('/review/${lesson.id}'),
                          onTest: () => context.push('/test/${lesson.id}'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 60),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
