import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import 'engineering_manager_teams_cubit.dart';

/// Engineering Manager · Team
///
/// v3 changes:
///  - Photo avatars everywhere (member cards, detail hero) instead of
///    letter-initial circles. Uses generated placeholder photos
///    (pravatar.cc, seeded by name hash so it's stable per person) with a
///    graceful gradient-initials fallback if the image fails to load or
///    there's no network. Swap `_avatarUrlFor` for real profile photo URLs
///    from your backend once available — the fallback keeps working either
///    way, so nothing breaks if a URL is missing.
///  - Header no longer shows a close (X) button — this is a bottom-nav TAB
///    (Teams stays selected), not a pushed modal, so it now matches the
///    Home-screen header pattern instead.
///  - Hero card upgraded: team name, status pill, productivity + budget
///    pills, and a compact 4-category health breakdown row.
///  - Member cards upgraded: productivity score + workload/capacity bar
///    added alongside the existing adoption ring / tool / sprint-pts row.
///  - Employee Detail screen upgraded: Productivity, Workload, and Budget
///    sections added (data already exists on `TeamMember`), and the action
///    row now offers the four manager actions instead of Message/Assign.
class EngineeringManagerTeamsScreen extends StatelessWidget {
  const EngineeringManagerTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EngineeringManagerTeamsCubit()..loadTeams(),
      child: const _EngineeringManagerTeamsView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared animation vocabulary
// ─────────────────────────────────────────────────────────────────────────

class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 50).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _ScaleOnTap extends StatefulWidget {
  const _ScaleOnTap({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

Route<T> _slideFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Photo avatar — replaces letter-initial circles everywhere. Falls back to
// gradient initials automatically if the image can't load.
// ─────────────────────────────────────────────────────────────────────────

const List<Color> _kAvatarPalette = [
  Color(0xFF6C5CE7),
  Color(0xFF2F80ED),
  Color(0xFFE85D75),
  Color(0xFFF2994A),
  Color(0xFF11998E),
  Color(0xFF9B51E0),
];

int _hashOf(String s) => s.codeUnits.fold<int>(0, (a, c) => a + c);

Color _avatarColorFor(String name) =>
    _kAvatarPalette[_hashOf(name) % _kAvatarPalette.length];

String _initialsFor(String name) {
  if (name.isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

/// Placeholder photo, stable per-name. Swap for a real backend avatar URL
/// (e.g. `member.photoUrl`) once available — the widget's fallback path
/// keeps working unchanged either way.
String _avatarUrlFor(String name) {
  final seed = (_hashOf(name) % 70) + 1;
  return 'https://i.pravatar.cc/150?img=$seed';
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    this.size = 44,
    this.ringColor,
  });

  final String name;
  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColorFor(name);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringColor == null ? 0 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            ringColor == null ? null : Border.all(color: ringColor!, width: 2),
      ),
      child: ClipOval(
        child: Image.network(
          _avatarUrlFor(name),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _fallback(color, size),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _fallback(color, size);
          },
        ),
      ),
    );
  }

  Widget _fallback(Color color, double size) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.7)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _initialsFor(name),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.34,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────

class _EngineeringManagerTeamsView extends StatefulWidget {
  const _EngineeringManagerTeamsView();

  @override
  State<_EngineeringManagerTeamsView> createState() =>
      _EngineeringManagerTeamsViewState();
}

class _EngineeringManagerTeamsViewState
    extends State<_EngineeringManagerTeamsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<EngineeringManagerTeamsCubit,
            EngineeringManagerTeamsState>(
          builder: (context, state) {
            final overview = state is EngineeringManagerTeamsLoaded
                ? state.data.overview
                : null;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _Header(colors: colors, overview: overview)),
                if (state is EngineeringManagerTeamsLoaded)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: _TeamHeroCard(
                          overview: state.data.overview, colors: colors),
                    ),
                  ),
                if (state is EngineeringManagerTeamsLoaded) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        0,
                      ),
                      child: _ThemedSearchField(
                        controller: _searchController,
                        colors: colors,
                        onChanged: (q) => context
                            .read<EngineeringManagerTeamsCubit>()
                            .search(q),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.md,
                        AppSpacing.xl,
                        0,
                      ),
                      child: _FilterChipRow(data: state.data, colors: colors),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.md)),
                ],
                _buildBody(context, state, colors),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EngineeringManagerTeamsState state,
    AppColorsData colors,
  ) {
    if (state is EngineeringManagerTeamsLoading ||
        state is EngineeringManagerTeamsInitial) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: List.generate(
              5,
              (index) => Padding(
                padding:
                    EdgeInsets.only(bottom: index == 4 ? 0 : AppSpacing.md),
                child: const SkeletonLoader(height: 104),
              ),
            ),
          ),
        ),
      );
    }
    if (state is EngineeringManagerTeamsError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          message: state.message,
        ),
      );
    }
    if (state is EngineeringManagerTeamsLoaded) {
      final members = state.data.filteredMembers;
      if (members.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.groups_outlined,
            title: 'No team members found',
            message: 'Try a different search term or filter.',
          ),
        );
      }
      return SliverToBoxAdapter(
        child: RefreshIndicator(
          color: colors.primary,
          onRefresh: () =>
              context.read<EngineeringManagerTeamsCubit>().refresh(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              children: [
                for (var i = 0; i < members.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _Staggered(
                      index: i,
                      child: _MemberCard(
                        member: members[i],
                        colors: colors,
                        onTap: () => Navigator.of(context).push(
                          _slideFadeRoute(
                              EngineerDetailScreen(member: members[i])),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Header — tab-style now (no close button): manager avatar, greeting,
// team name, notification bell.
// ─────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.colors, required this.overview});

  final AppColorsData colors;
  final EngineeringTeamOverview? overview;

  @override
  Widget build(BuildContext context) {
    final managerName = overview?.managerName ?? 'Manager';
    final teamName = overview?.teamName ?? 'Team';
    final hasUnread = overview?.hasUnreadNotifications ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
      child: Row(
        children: [
          _ProfileAvatar(name: managerName, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Team', style: AppTypography.h1(colors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '$teamName · sprint & AI activity',
                  style: AppTypography.caption(colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Icon(Icons.notifications_outlined,
                    color: colors.textPrimary, size: 20),
              ),
              if (hasUnread)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: colors.danger, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Team hero card — team name, status pill, on-track ring, spend/members,
// metric pills, and a compact 4-category health breakdown row.
// ─────────────────────────────────────────────────────────────────────────

class _TeamHeroCard extends StatelessWidget {
  const _TeamHeroCard({required this.overview, required this.colors});

  final EngineeringTeamOverview overview;
  final AppColorsData colors;

  ({String label, Color color}) _statusStyle(AppColorsData colors) {
    switch (overview.healthStatus) {
      case TeamHealthStatus.healthy:
        return (label: 'Healthy', color: colors.success);
      case TeamHealthStatus.warning:
        return (label: 'Warning', color: colors.warning);
      case TeamHealthStatus.critical:
        return (label: 'Critical', color: colors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(colors);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.secondary,
            colors.primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(overview.teamName,
                    style: AppTypography.h3(Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              _StatusPill(label: status.label, color: status.color),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AnimatedOnTrackRing(
                  percent: overview.onTrackPercent, color: Colors.white),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${overview.onTrackPercent}% on track',
                      style: AppTypography.h2(Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.groups_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 4),
                        _AnimatedCounter(
                          value: overview.totalMembers,
                          style: AppTypography.caption(
                                  Colors.white.withValues(alpha: 0.85))
                              .copyWith(fontWeight: FontWeight.w600),
                          suffix: ' members',
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.currency_rupee_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85)),
                        Text(
                          _formatAmount(overview.totalMonthlyAiSpend),
                          style: AppTypography.caption(
                                  Colors.white.withValues(alpha: 0.85))
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '/mo spend',
                          style: AppTypography.caption(
                              Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroMetricPill(
                    label: 'Adoption',
                    value: '${overview.avgAiAdoptionPercent}%'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroMetricPill(
                    label: 'Productivity',
                    value: '${overview.productivityScore}'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroMetricPill(
                  label: 'Budget left',
                  value: _formatAmount(overview.budgetRemaining),
                  icon: Icons.currency_rupee_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final cat in overview.healthBreakdown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 84,
                          child: Text(cat.name,
                              style: AppTypography.caption(
                                  Colors.white.withValues(alpha: 0.85)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: cat.score / 100),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) =>
                                  LinearProgressIndicator(
                                value: v,
                                minHeight: 6,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.18),
                                valueColor:
                                    const AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 26,
                          child: Text('${cat.score}',
                              textAlign: TextAlign.end,
                              style: AppTypography.caption(Colors.white)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ],
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

final _amountFormat = RegExp(r'\B(?=(\d{3})+(?!\d))');
String _formatAmount(double value) =>
    value.toStringAsFixed(0).replaceAllMapped(_amountFormat, (m) => ',');

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption(Colors.white)),
        ],
      ),
    );
  }
}

/// Labels never get cut off — single line, ellipsis, breathing room.
class _HeroMetricPill extends StatelessWidget {
  const _HeroMetricPill({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: Colors.white),
              ],
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.h3(Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption(Colors.white.withValues(alpha: 0.85))
                .copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AnimatedOnTrackRing extends StatelessWidget {
  const _AnimatedOnTrackRing({required this.percent, required this.color});

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 64,
          height: 64,
          child: CustomPaint(
            painter: _RingPainter(progress: value, color: color),
            child: Center(
              child: Text(
                '${(value * 100).round()}%',
                style: AppTypography.caption(color)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final track = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _AnimatedCounter extends StatelessWidget {
  const _AnimatedCounter(
      {required this.value, required this.style, this.suffix = ''});

  final int value;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Search field
// ─────────────────────────────────────────────────────────────────────────

class _ThemedSearchField extends StatefulWidget {
  const _ThemedSearchField({
    required this.controller,
    required this.colors,
    required this.onChanged,
  });

  final TextEditingController controller;
  final AppColorsData colors;
  final ValueChanged<String> onChanged;

  @override
  State<_ThemedSearchField> createState() => _ThemedSearchFieldState();
}

class _ThemedSearchFieldState extends State<_ThemedSearchField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode
        .addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: 52,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused ? colors.primary : colors.border,
          width: _focused ? 1.6 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        style: AppTypography.body(colors.textPrimary),
        cursorColor: colors.primary,
        decoration: InputDecoration(
          hintText: 'Search by name or role',
          hintStyle: AppTypography.body(colors.textSecondary),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _focused ? colors.primary : colors.textSecondary,
            size: 20,
          ),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: colors.textSecondary),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged('');
                  },
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Filter chip row — adoption/attention filters + presence filters.
// ─────────────────────────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.data, required this.colors});

  final EngineeringManagerTeamsData data;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    final chips = <(MemberFilter, String, int)>[
      (MemberFilter.all, 'All', data.allMembers.length),
      (MemberFilter.presenceActive, 'Active', data.presenceActiveCount),
      (MemberFilter.highAdoption, 'High adoption', data.highAdoptionCount),
      (
        MemberFilter.needsAttention,
        'Needs attention',
        data.needsAttentionCount
      ),
      (MemberFilter.blocked, 'Blocked', data.blockedCount),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (filter, label, count) = chips[index];
          final selected = data.activeFilter == filter;
          return _ScaleOnTap(
            onTap: () => context
                .read<EngineeringManagerTeamsCubit>()
                .applyFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: selected ? colors.primary : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: selected ? colors.primary : colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption(
                            selected ? Colors.white : colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.22)
                          : colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.caption(
                              selected ? Colors.white : colors.textSecondary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Member card — photo avatar with status-colored ring, productivity score,
// and an explicit workload/capacity bar in addition to the existing
// adoption ring / primary tool / sprint-pts row.
// ─────────────────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard(
      {required this.member, required this.colors, required this.onTap});

  final TeamMember member;
  final AppColorsData colors;
  final VoidCallback onTap;

  Color _capacityColor(AppColorsData colors, int percent) {
    if (percent >= 100) return colors.danger;
    if (percent >= 85) return colors.warning;
    return colors.success;
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(member.engagementStatus, colors);
    final capacityColor = _capacityColor(colors, member.capacityPercent);

    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileAvatar(
                    name: member.name, size: 44, ringColor: statusInfo.color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.name,
                              style: AppTypography.body(colors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _StatusBadge(info: statusInfo),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.role,
                        style: AppTypography.caption(colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          _SmallAdoptionRing(
                              percent: member.aiAdoptionPercent,
                              colors: colors),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              member.primaryTool,
                              style:
                                  AppTypography.caption(colors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Icon(Icons.bolt_rounded,
                              size: 14, color: colors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${member.sprintPointsAssigned} pts',
                            style: AppTypography.caption(colors.textSecondary)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed_rounded,
                          size: 12, color: colors.primary),
                      const SizedBox(width: 3),
                      Text('${member.productivityScore} productivity',
                          style: AppTypography.caption(colors.primary)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Spacer(),
                Text('Capacity ${member.capacityPercent}%',
                    style: AppTypography.caption(colors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                    begin: 0,
                    end: (member.capacityPercent / 100).clamp(0, 1.3)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation(capacityColor),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View profile',
                      style: AppTypography.caption(colors.primary)
                          .copyWith(fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: colors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallAdoptionRing extends StatelessWidget {
  const _SmallAdoptionRing({required this.percent, required this.colors});

  final int percent;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(20, 20),
            painter:
                _RingPainter(progress: percent / 100, color: colors.primary),
          ),
          Text(
            '$percent',
            style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: colors.primary),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo {
  const _StatusInfo(this.label, this.color, this.bg);
  final String label;
  final Color color;
  final Color bg;
}

_StatusInfo _statusInfo(MemberEngagementStatus status, AppColorsData colors) {
  switch (status) {
    case MemberEngagementStatus.onTrack:
      return _StatusInfo(
          'On Track', colors.success, colors.success.withValues(alpha: 0.14));
    case MemberEngagementStatus.needsAttention:
      return _StatusInfo('Needs Attention', colors.warning,
          colors.warning.withValues(alpha: 0.14));
    case MemberEngagementStatus.overloaded:
      return _StatusInfo(
          'Overloaded', colors.danger, colors.danger.withValues(alpha: 0.14));
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.info});

  final _StatusInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: info.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        info.label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: info.color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Engineer Detail screen — photo hero, Productivity / Workload / Budget
// sections added, plus the four manager actions.
// ─────────────────────────────────────────────────────────────────────────

class EngineerDetailScreen extends StatelessWidget {
  const EngineerDetailScreen({super.key, required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final statusInfo = _statusInfo(member.engagementStatus, colors);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Row(
              children: [
                _ScaleOnTap(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(Icons.arrow_back_rounded,
                        color: colors.textSecondary, size: 20),
                  ),
                ),
                const Spacer(),
                _StatusBadge(info: statusInfo),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailHero(member: member, colors: colors),
            const SizedBox(height: AppSpacing.lg),
            _ProductivitySection(member: member, colors: colors),
            const SizedBox(height: AppSpacing.lg),
            _WorkloadSection(member: member, colors: colors),
            const SizedBox(height: AppSpacing.lg),
            _BudgetSection(member: member, colors: colors),
            const SizedBox(height: AppSpacing.lg),
            _ToolBreakdownSection(member: member, colors: colors),
            const SizedBox(height: AppSpacing.lg),
            _RecentActivitySection(member: member, colors: colors),
            const SizedBox(height: AppSpacing.lg),
            _ActionGrid(colors: colors),
          ],
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.member, required this.colors});

  final TeamMember member;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.secondary,
            colors.primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfileAvatar(
                  name: member.name,
                  size: 56,
                  ringColor: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: AppTypography.h3(Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      member.role,
                      style: AppTypography.caption(
                          Colors.white.withValues(alpha: 0.85)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _AnimatedOnTrackRing(
                  percent: member.aiAdoptionPercent, color: Colors.white),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroMetricPill(
                  label: 'Sprint pts',
                  value:
                      '${member.sprintPointsAssigned}/${member.sprintCapacity}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroMetricPill(
                  label: 'Reviewed',
                  value: '${member.prsReviewed}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroMetricPill(
                  label: 'Open PRs',
                  value: '${member.prsOpen}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.colors, required this.child});
  final String title;
  final AppColorsData colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _ProductivitySection extends StatelessWidget {
  const _ProductivitySection({required this.member, required this.colors});
  final TeamMember member;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    final completionRate = member.currentTasks + member.completedTasks == 0
        ? 0
        : ((member.completedTasks /
                    (member.currentTasks + member.completedTasks)) *
                100)
            .round();
    return _SectionCard(
      title: 'Productivity',
      colors: colors,
      child: Row(
        children: [
          Expanded(
              child: _StatBlock(
                  label: 'Score',
                  value: '${member.productivityScore}',
                  colors: colors)),
          Expanded(
              child: _StatBlock(
                  label: 'Task completion',
                  value: '$completionRate%',
                  colors: colors)),
          Expanded(
              child: _StatBlock(
                  label: 'AI-assisted',
                  value: member.primaryTool,
                  colors: colors)),
        ],
      ),
    );
  }
}

class _WorkloadSection extends StatelessWidget {
  const _WorkloadSection({required this.member, required this.colors});
  final TeamMember member;
  final AppColorsData colors;

  Color _capacityColor() {
    if (member.capacityPercent >= 100) return colors.danger;
    if (member.capacityPercent >= 85) return colors.warning;
    return colors.success;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Workload',
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _StatBlock(
                      label: 'Current',
                      value: '${member.currentTasks}',
                      colors: colors)),
              Expanded(
                  child: _StatBlock(
                      label: 'Completed',
                      value: '${member.completedTasks}',
                      colors: colors)),
              Expanded(
                  child: _StatBlock(
                      label: 'Overdue',
                      value: '${member.overdueTasks}',
                      valueColor:
                          member.overdueTasks > 0 ? colors.danger : null,
                      colors: colors)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('Capacity',
                  style: AppTypography.caption(colors.textSecondary)),
              const Spacer(),
              Text('${member.capacityPercent}%',
                  style: AppTypography.caption(_capacityColor())
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                  begin: 0, end: (member.capacityPercent / 100).clamp(0, 1.3)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v.clamp(0, 1),
                minHeight: 7,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation(_capacityColor()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSection extends StatelessWidget {
  const _BudgetSection({required this.member, required this.colors});
  final TeamMember member;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    final remaining = (member.allocatedBudget - member.monthlyAiSpend)
        .clamp(0, double.infinity);
    return _SectionCard(
      title: 'Budget',
      colors: colors,
      child: Row(
        children: [
          Expanded(
              child: _StatBlock(
                  label: 'Spend',
                  value: _formatAmount(member.monthlyAiSpend),
                  icon: Icons.currency_rupee_rounded,
                  colors: colors)),
          Expanded(
              child: _StatBlock(
                  label: 'Allocated',
                  value: _formatAmount(member.allocatedBudget),
                  icon: Icons.currency_rupee_rounded,
                  colors: colors)),
          Expanded(
              child: _StatBlock(
                  label: 'Remaining',
                  value: _formatAmount(remaining as double),
                  icon: Icons.currency_rupee_rounded,
                  colors: colors)),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.colors,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final AppColorsData colors;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null)
              Icon(icon, size: 13, color: valueColor ?? colors.textPrimary),
            Flexible(
              child: Text(value,
                  style: AppTypography.h3(valueColor ?? colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        Text(label, style: AppTypography.caption(colors.textSecondary)),
      ],
    );
  }
}

class _ToolBreakdownSection extends StatelessWidget {
  const _ToolBreakdownSection({required this.member, required this.colors});

  final TeamMember member;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'AI Tool Usage',
      colors: colors,
      child: member.toolBreakdown.isEmpty
          ? Text('No AI tools in use',
              style: AppTypography.body(colors.textSecondary))
          : Column(
              children: [
                for (final tool in member.toolBreakdown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            tool.toolName,
                            style: AppTypography.body(colors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: tool.adoptionPercent / 100,
                              minHeight: 6,
                              backgroundColor: colors.border,
                              valueColor:
                                  AlwaysStoppedAnimation(colors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(Icons.currency_rupee_rounded,
                                size: 12, color: colors.textSecondary),
                            Text(
                              tool.monthlySpend.toStringAsFixed(0),
                              style:
                                  AppTypography.caption(colors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.member, required this.colors});

  final TeamMember member;
  final AppColorsData colors;

  Color _activityColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.success:
        return colors.success;
      case ActivityStatus.warning:
        return colors.warning;
      case ActivityStatus.danger:
        return colors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent Activity',
      colors: colors,
      child: member.recentActivity.isEmpty
          ? Text('No recent activity',
              style: AppTypography.body(colors.textSecondary))
          : Column(
              children: [
                for (final item in member.recentActivity)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.body(colors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _activityColor(item.status)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                item.statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _activityColor(item.status),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.relativeTime,
                              style:
                                  AppTypography.caption(colors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Four manager actions, 2x2 grid: View AI Usage / Adjust Tool Access /
/// Request Approval / Review Activity.
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.colors});

  final AppColorsData colors;

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String)>[
      (Icons.query_stats_rounded, 'View AI Usage'),
      (Icons.tune_rounded, 'Adjust Tool Access'),
      (Icons.approval_rounded, 'Request Approval'),
      (Icons.history_rounded, 'Review Activity'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.4,
      children: actions.map((a) {
        return _ScaleOnTap(
          onTap: () => _showComingSoon(context, a.$2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(a.$1, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(a.$2,
                      style: AppTypography.caption(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
