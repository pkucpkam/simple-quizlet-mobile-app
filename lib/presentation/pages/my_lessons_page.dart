import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/my_lessons/my_lessons_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/lesson_card.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/staggered_fade_slide.dart';

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

    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);
    final textCol = AppTheme.text(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Bài học của tôi', style: AppTheme.titleSm(context)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 16, color: textCol),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        foregroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
        icon: Icon(Icons.add_rounded, color: isDarkMode ? Colors.black : Colors.white),
        label: Text('Tạo bài học', style: AppTheme.labelSm(context).copyWith(color: isDarkMode ? Colors.black : Colors.white, fontWeight: FontWeight.w800)),
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
            return Center(child: CircularProgressIndicator(color: accent));
          }

          if (state is MyLessonsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 48),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${state.message}', style: AppTheme.bodyMd(context)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? const Color(0xFF242424) : AppTheme.surface2Color,
                      foregroundColor: isDarkMode ? Colors.white : AppTheme.textColor,
                      elevation: 0,
                    ),
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
              color: accent,
              backgroundColor: AppTheme.surface(context),
              onRefresh: () async => _loadMyLessons(),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Banner Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: isDarkMode
                          ? null
                          : LinearGradient(
                              colors: [
                                accent.withValues(alpha: 0.18),
                                AppTheme.surface2(context),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: isDarkMode ? const Color(0xFF181818) : null,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: !isDarkMode
                          ? Border.all(
                              color: accent.withValues(alpha: 0.35),
                              width: 1,
                            )
                          : null,
                      boxShadow: isDarkMode ? null : AppTheme.shadow(context),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF242424) : accent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.folder_shared_outlined, color: accent, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(username, style: AppTheme.titleSm(context).copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                '${lessons.length} bài học đã tạo',
                                style: AppTheme.bodySm(context).copyWith(color: accent, fontWeight: FontWeight.w700),
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
                            Text('Bạn chưa tạo bài học nào', style: AppTheme.titleSm(context)),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy tạo bài học mới trên web hoặc nút bên dưới!',
                              style: AppTheme.bodySm(context),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...lessons.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final lesson = entry.value;
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
