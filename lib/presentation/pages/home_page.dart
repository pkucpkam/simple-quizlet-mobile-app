import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/home/home_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/folder_card.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/lesson_card.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/pressable_scale.dart';
import 'package:simple_quizlet_mobile_app/presentation/widgets/staggered_fade_slide.dart';

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

    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);
    final text3Col = AppTheme.text3(context);
    final surfaceCol = AppTheme.surface(context);

    return Scaffold(
      backgroundColor: bg,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return Center(
              child: CircularProgressIndicator(color: accent),
            );
          }
          if (state is HomeError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: text3Col, size: 52),
                    const SizedBox(height: 14),
                    Text(
                      'Lỗi kết nối: ${state.message}',
                      style: AppTheme.bodyMd(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    PressableScale(
                      onTap: () => context.read<HomeBloc>().add(HomeLoadRequested()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: AppTheme.pillDecoration(
                          context: context,
                          border: accent,
                        ),
                        child: Text(
                          'THỬ LẠI',
                          style: AppTheme.labelSm(context).copyWith(color: accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is HomeLoaded) {
            return RefreshIndicator(
              color: accent,
              backgroundColor: surfaceCol,
              onRefresh: () async {
                context.read<HomeBloc>().add(HomeLoadRequested());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── SliverAppBar ──────────────────────────────
                  SliverAppBar(
                    backgroundColor: bg,
                    floating: true,
                    snap: true,
                    elevation: 0,
                    titleSpacing: 16,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Neon glowing indicator dot
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Simple Quizlet',
                              style: AppTheme.titleMd(context).copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        if (username.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Xin chào, $username 👋',
                              style: AppTheme.bodySm(context).copyWith(color: text2Col),
                            ),
                          ),
                      ],
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: PressableScale(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.isDark(context)
                                  ? const Color(0xFF242424)
                                  : AppTheme.surface2(context),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(Icons.person_outline, size: 20, color: textCol),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Search bar ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _buildSearchBar(context),
                    ),
                  ),

                  // ── Quick Access Row ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: PressableScale(
                              onTap: () => context.push('/my-lessons'),
                              scaleDown: 0.96,
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.isDark(context)
                                      ? const Color(0xFF242424)
                                      : AppTheme.lightSurface2Color,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.folder_shared_outlined, color: accent, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Bài học của tôi',
                                        style: AppTheme.labelSm(context).copyWith(
                                          color: textCol,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PressableScale(
                              onTap: () => context.push('/srs-review'),
                              scaleDown: 0.96,
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.isDark(context)
                                      ? const Color(0xFF242424)
                                      : AppTheme.lightSurface2Color,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: AppTheme.warningColor, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Ôn tập SRS',
                                        style: AppTheme.labelSm(context).copyWith(
                                          color: textCol,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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

                  // ── Match Rush Game Banner ────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: PressableScale(
                        onTap: () => context.push('/match'),
                        scaleDown: 0.97,
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.isDark(context)
                                ? const Color(0xFF1E3A26)
                                : accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'MATCH RUSH 60S',
                                          style: GoogleFonts.inter(
                                            color: AppTheme.text(context),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'MINIGAME',
                                            style: GoogleFonts.inter(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ghép thẻ tốc độ cao • Đua điểm kỷ lục',
                                      style: AppTheme.bodySm(context).copyWith(
                                        color: AppTheme.text2(context),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.play_circle_filled_rounded, color: accent, size: 26),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Official Folders ──────────────────────────
                  if (state.officialFolders.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              'THƯ MỤC HỆ THỐNG',
                              style: AppTheme.labelMd(context).copyWith(
                                color: text2Col,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${state.officialFolders.length} thư mục',
                              style: AppTheme.bodySm(context).copyWith(color: text3Col),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 148,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.officialFolders.length,
                          itemBuilder: (context, index) {
                            final folder = state.officialFolders[index];
                            return StaggeredFadeSlide(
                              index: index,
                              slideOffset: const Offset(0.15, 0),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 124,
                                  child: FolderCard(
                                    folder: folder,
                                    onTap: () => context.push('/folder/${folder.id}'),
                                  ),
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
                            style: AppTheme.labelMd(context).copyWith(
                              color: text2Col,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.totalCount} bài  •  trang ${state.currentPage}/${state.totalPages}',
                            style: AppTheme.bodySm(context).copyWith(color: text3Col),
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
                              const SizedBox(height: 14),
                              Text('Chưa có bài học nào', style: AppTheme.bodyMd(context)),
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
                          return StaggeredFadeSlide(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final surface2 = AppTheme.surface2(context);
    final textCol = AppTheme.text(context);
    final text3Col = AppTheme.text3(context);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.isDark(context) ? const Color(0xFF242424) : surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: AppTheme.bodyLg(context).copyWith(color: textCol),
        onChanged: (v) {
          setState(() {});
          if (v.isEmpty) {
            context.read<HomeBloc>().add(HomeSearchCleared());
          } else if (v.length > 1) {
            context.read<HomeBloc>().add(HomeSearchChanged(v));
          }
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bài học...',
          hintStyle: AppTheme.bodyMd(context).copyWith(color: text3Col),
          prefixIcon: Icon(Icons.search_rounded, color: text3Col, size: 22),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: text3Col, size: 18),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final pageNumbers = _buildPageNumbers();
    final accent = AppTheme.accent(context);
    final surface2 = AppTheme.surface2(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: AppTheme.cardDecoration(
          context: context,
          hasShadow: true,
          hasBorder: true,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              enabled: hasPrev,
              onTap: onPrev,
            ),
            const SizedBox(width: 8),
            ...pageNumbers.map((page) {
              if (page == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('…', style: AppTheme.bodySm(context)),
                );
              }
              final isActive = page == currentPage;
              return PressableScale(
                onTap: isActive ? null : () => onPage(page),
                scaleDown: 0.9,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive ? accent : (AppTheme.isDark(context) ? const Color(0xFF242424) : surface2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      '$page',
                      style: AppTheme.labelSm(context).copyWith(
                        color: isActive ? Colors.black : AppTheme.text2(context),
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
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
    final accent = AppTheme.accent(context);
    final isDark = AppTheme.isDark(context);
    return PressableScale(
      onTap: enabled ? onTap : null,
      scaleDown: 0.9,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? (isDark ? const Color(0xFF242424) : accent.withValues(alpha: 0.12))
              : (isDark ? const Color(0xFF1A1A1A) : AppTheme.surface2(context)),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: enabled ? accent : AppTheme.text3(context),
          ),
        ),
      ),
    );
  }
}
