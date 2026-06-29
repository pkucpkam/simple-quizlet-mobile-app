import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/home/home_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/folder_card.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/lesson_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadRequested());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final username = authState is AuthAuthenticated ? authState.user.username : '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Simple Quizlet', style: AppTheme.titleMd),
            if (username.isNotEmpty)
              Text('Xin chào, $username', style: AppTheme.bodySm.copyWith(fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 22),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
          }
          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${state.message}', style: AppTheme.bodyMd),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<HomeBloc>().add(HomeLoadRequested()),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          if (state is HomeLoaded) {
            return RefreshIndicator(
              color: AppTheme.accentColor,
              backgroundColor: AppTheme.surfaceColor,
              onRefresh: () async {
                context.read<HomeBloc>().add(HomeLoadRequested());
              },
              child: CustomScrollView(
                slivers: [
                  // Search bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _buildSearchBar(),
                    ),
                  ),

                  // Official Folders
                  if (state.officialFolders.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                        child: Row(
                          children: [
                            Text('Thư mục hệ thống', style: AppTheme.titleMd),
                            const Spacer(),
                            Text(
                              '${state.officialFolders.length} thư mục',
                              style: AppTheme.bodySm,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.officialFolders.length,
                          itemBuilder: (context, index) {
                            final folder = state.officialFolders[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: SizedBox(
                                width: 110,
                                child: FolderCard(
                                  folder: folder,
                                  onTap: () => context.push('/folder/${folder.id}'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // Lessons header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Row(
                        children: [
                          Text(
                            state.searchTerm.isEmpty ? 'Danh sách bài học' : 'Kết quả tìm kiếm',
                            style: AppTheme.titleMd,
                          ),
                          const Spacer(),
                          Text('${state.lessons.length} bài', style: AppTheme.bodySm),
                        ],
                      ),
                    ),
                  ),

                  // Lessons list
                  if (state.lessons.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Text('📚', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text('Chưa có bài học nào', style: AppTheme.bodyMd),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final lesson = state.lessons[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: AppTheme.bodyLg,
        onChanged: (v) {
          if (v.isEmpty) {
            context.read<HomeBloc>().add(HomeSearchCleared());
          } else if (v.length > 1) {
            context.read<HomeBloc>().add(HomeSearchChanged(v));
          }
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bài học...',
          hintStyle: AppTheme.bodySm,
          prefixIcon: const Icon(Icons.search, color: AppTheme.text3Color, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.text3Color, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<HomeBloc>().add(HomeSearchCleared());
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
