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
      backgroundColor: AppTheme.bgColor,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppTheme.text3Color, size: 48),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${state.message}', style: AppTheme.bodyMd),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.read<HomeBloc>().add(HomeLoadRequested()),
                    child: const Text('THỬ LẠI'),
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
                  // ── SliverAppBar ──────────────────────────────
                  SliverAppBar(
                    backgroundColor: AppTheme.bgColor,
                    floating: true,
                    snap: true,
                    titleSpacing: 16,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Green dot logo
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppTheme.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Simple Quizlet', style: AppTheme.titleMd),
                          ],
                        ),
                        if (username.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Xin chào, $username 👋',
                              style: AppTheme.bodySm,
                            ),
                          ),
                      ],
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface2Color,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.borderColor, width: 0.8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.person_outline, size: 20),
                          onPressed: () => context.push('/profile'),
                          color: AppTheme.textColor,
                        ),
                      ),
                    ],
                  ),

                  // ── Search bar ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _buildSearchBar(),
                    ),
                  ),

                  // ── Quick Access Row ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push('/my-lessons'),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(
                                    color: AppTheme.accentColor.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder_shared_outlined, color: AppTheme.accentColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bài học của tôi',
                                      style: AppTheme.labelSm.copyWith(color: AppTheme.accentColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push('/srs-review'),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(
                                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: AppTheme.warningColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ôn tập SRS',
                                      style: AppTheme.labelSm.copyWith(color: AppTheme.warningColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Official Folders ──────────────────────────
                  if (state.officialFolders.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Row(
                          children: [
                            Text('THƯ MỤC HỆ THỐNG', style: AppTheme.labelMd),
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
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.officialFolders.length,
                          itemBuilder: (context, index) {
                            final folder = state.officialFolders[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: SizedBox(
                                width: 116,
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

                  // ── Lessons header ────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        children: [
                          Text(
                            state.searchTerm.isEmpty ? 'DANH SÁCH BÀI HỌC' : 'KẾT QUẢ TÌM KIẾM',
                            style: AppTheme.labelMd,
                          ),
                          const Spacer(),
                          Text(
                            '${state.totalCount} bài  •  trang ${state.currentPage}/${state.totalPages}',
                            style: AppTheme.bodySm,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Lessons list ──────────────────────────────
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
                  
                  // ── Pagination controls ───────────────────────────────
                  if (state.totalPages > 1)
                    SliverToBoxAdapter(
                      child: _PaginationBar(
                        currentPage: state.currentPage,
                        totalPages: state.totalPages,
                        hasPrev: state.hasPrevPage,
                        hasNext: state.hasNextPage,
                        onPrev: () => context.read<HomeBloc>().add(HomeLoadPrevPage()),
                        onNext: () => context.read<HomeBloc>().add(HomeLoadNextPage()),
                        onPage: (p) => context.read<HomeBloc>().add(HomeGoToPage(p)),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surface2Color,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.borderColor, width: 0.8),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: AppTheme.bodyLg,
        onChanged: (v) {
          setState(() {}); // Rebuild suffix icon
          if (v.isEmpty) {
            context.read<HomeBloc>().add(HomeSearchCleared());
          } else if (v.length > 1) {
            context.read<HomeBloc>().add(HomeSearchChanged(v));
          }
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bài học...',
          hintStyle: AppTheme.bodySm,
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.text3Color, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppTheme.text3Color, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                    context.read<HomeBloc>().add(HomeSearchCleared());
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        ),
      ),
    );
  }
}

// ── Pagination Bar ─────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(int page) onPage;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
    required this.onPage,
  });

  /// Generate page numbers to show: always show first, last, current ±1, with … gaps
  List<int?> _buildPageNumbers() {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }
    final pages = <int?>{};
    pages.add(1);
    pages.add(totalPages);
    for (int i = (currentPage - 1).clamp(1, totalPages);
        i <= (currentPage + 1).clamp(1, totalPages);
        i++) {
      pages.add(i);
    }
    final sorted = pages.toList()..sort((a, b) => a! - b!);
    final result = <int?>[];
    for (int i = 0; i < sorted.length; i++) {
      result.add(sorted[i]);
      if (i < sorted.length - 1 && sorted[i + 1]! - sorted[i]! > 1) {
        result.add(null); // null = ellipsis
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final pageNumbers = _buildPageNumbers();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.shadowMedium,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ← Prev button
            _NavButton(
              icon: Icons.chevron_left_rounded,
              enabled: hasPrev,
              onTap: onPrev,
            ),
            const SizedBox(width: 6),

            // Page numbers
            ...pageNumbers.map((page) {
              if (page == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('…', style: AppTheme.bodySm),
                );
              }
              final isActive = page == currentPage;
              return GestureDetector(
                onTap: isActive ? null : () => onPage(page),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.accentColor : AppTheme.surface2Color,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: isActive
                        ? null
                        : Border.all(color: AppTheme.borderColor, width: 0.8),
                  ),
                  child: Center(
                    child: Text(
                      '$page',
                      style: AppTheme.labelSm.copyWith(
                        color: isActive ? Colors.black : AppTheme.text2Color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(width: 6),
            // → Next button
            _NavButton(
              icon: Icons.chevron_right_rounded,
              enabled: hasNext,
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.accentColor.withValues(alpha: 0.1)
              : AppTheme.surface2Color,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: enabled
                ? AppTheme.accentColor.withValues(alpha: 0.4)
                : AppTheme.borderColor,
            width: 0.8,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppTheme.accentColor : AppTheme.text4Color,
          ),
        ),
      ),
    );
  }
}
