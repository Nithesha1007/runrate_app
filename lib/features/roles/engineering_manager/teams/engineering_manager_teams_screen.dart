import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../ceo/more/profile_cubit.dart';
import 'engineering_manager_teams_cubit.dart';

/// Engineering Manager · Team
///
/// v5 changes:
///  - Employee Detail screen (Productivity / Workload / Budget / AI Tool
///    Usage / Recent Activity / manager actions) rebuilt with the same
///    "advanced" visual language used across the rest of the app: every
///    section header now carries a gradient icon badge instead of plain
///    text, stat rows use small gradient-icon tiles instead of bare
///    numbers, the Budget section gained a spend-vs-allocated progress
///    bar, AI Tool Usage rows now look like real tool cards (icon badge +
///    progress bar + spend chip) instead of a cramped three-column row,
///    Recent Activity is now a connected timeline instead of a flat list,
///    and the four manager actions at the bottom use the same gradient
///    quick-action tile style as the Home screens — built as a
///    content-sized 2x2 (`IntrinsicHeight` + `Row`, no `GridView`
///    `childAspectRatio`) so it can't overflow the way a fixed-ratio grid
///    can.
///
/// v4 changes (carried over):
///  - Removed the KPI health-breakdown card from the team hero (Delivery /
///    AI Adoption / Productivity / Budget bars) for a cleaner, less
///    cluttered hero. The hero now carries an ambient rotating glow instead.
///  - Member card: productivity badge and the "View details" link now sit
///    on the same row (no separate stacked row), and there's no
///    capacity/workload bar on the card — that detail lives on the
///    Employee Detail screen only.
///  - Search bar rebuilt with a glassmorphic shell and an animated
///    conic-gradient glow border that activates on focus.
///  - Filter chip row rebuilt with gradient-filled selected state, glow
///    shadow, and a small leading icon per filter for faster scanning.
///  - Status pill now uses a soft pulsing dot instead of a static one.
///
/// v3 changes (carried over):
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
// Ambient pulsing dot — used inside the hero status pill.
// ─────────────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 6 + t * 10,
                height: 6 + t * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (1 - t) * 0.55),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: widget.color, shape: BoxShape.circle),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Ambient rotating glow wrapper — used behind the hero card for a subtle
// futuristic "alive" feel without being distracting.
// ─────────────────────────────────────────────────────────────────────────

class _AmbientGlow extends StatefulWidget {
  const _AmbientGlow({required this.child, required this.colors}) : radius = 26;

  final Widget child;
  final AppColorsData colors;
  final double radius;

  @override
  State<_AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<_AmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * 2 * math.pi;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: widget.colors.primary
                    .withValues(alpha: 0.26 + 0.08 * math.sin(angle)),
                blurRadius: 26,
                spreadRadius: 0,
                offset: Offset(5 * math.cos(angle), 5 * math.sin(angle)),
              ),
              BoxShadow(
                color: widget.colors.secondary
                    .withValues(alpha: 0.20 + 0.08 * math.cos(angle)),
                blurRadius: 30,
                spreadRadius: 0,
                offset: Offset(-5 * math.cos(angle), -5 * math.sin(angle)),
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
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
    this.imageUrl,
  });

  final String name;
  final double size;
  final Color? ringColor;

  /// Real profile photo URL (e.g. from the app's ProfileCubit/session).
  /// When provided, this is used instead of the generated placeholder
  /// photo — pass this for the logged-in manager's own avatar so it shows
  /// their actual profile picture from the existing Profile screen.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColorFor(name);
    final resolvedUrl = imageUrl ?? _avatarUrlFor(name);
    final image = imageUrl != null &&
            (imageUrl!.startsWith('http://') ||
                imageUrl!.startsWith('https://'))
        ? NetworkImage(resolvedUrl)
        : imageUrl != null
            ? FileImage(File(resolvedUrl)) as ImageProvider
            : NetworkImage(resolvedUrl);
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
        child: Image(
          image: image,
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
    final profile = context.watch<ProfileCubit>().state;
    final managerName = profile.name.isNotEmpty ? profile.name : 'Manager';
    final teamName = overview?.teamName ?? 'Team';
    final hasUnread = overview?.hasUnreadNotifications ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
      child: Row(
        children: [
          _ProfileAvatar(
              name: managerName, size: 44, imageUrl: profile.avatarUrl),
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
// Team hero card — team name, status pill, on-track ring, and spend/
// members. The KPI health-breakdown card has been removed for a cleaner
// hero; a subtle ambient glow gives it presence instead.
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

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: _AmbientGlow(
        colors: colors,
        child: Container(
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
            ],
          ),
        ),
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
          _PulseDot(color: color),
          const SizedBox(width: 2),
          Text(label, style: AppTypography.caption(Colors.white)),
        ],
      ),
    );
  }
}

/// Labels never get cut off — single line, ellipsis, breathing room.
class _HeroMetricPill extends StatelessWidget {
  const _HeroMetricPill({required this.label, required this.value});

  final String label;
  final String value;

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
// Search field — glassmorphic shell with an animated conic-gradient glow
// border that spins in on focus.
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

class _ThemedSearchFieldState extends State<_ThemedSearchField>
    with SingleTickerProviderStateMixin {
  final _focusNode = FocusNode();
  bool _focused = false;
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _focusNode
        .addListener(() => setState(() => _focused = _focusNode.hasFocus));
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final angle = _glowController.value * 2 * math.pi;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(_focused ? 1.6 : 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: _focused
                ? SweepGradient(
                    transform: GradientRotation(angle),
                    colors: [
                      colors.primary,
                      colors.secondary,
                      colors.primary.withValues(alpha: 0.35),
                      colors.secondary.withValues(alpha: 0.6),
                      colors.primary,
                    ],
                  )
                : null,
            color: _focused ? null : colors.border,
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.28),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(16.4),
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
                prefixIcon: AnimatedScale(
                  scale: _focused ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.search_rounded,
                    color: _focused ? colors.primary : colors.textSecondary,
                    size: 20,
                  ),
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
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Filter chip row — gradient-filled selected state with glow shadow and a
// small leading icon per filter.
// ─────────────────────────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.data, required this.colors});

  final EngineeringManagerTeamsData data;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    final chips = <(MemberFilter, String, int, IconData)>[
      (MemberFilter.all, 'All', data.allMembers.length,
          Icons.grid_view_rounded),
      (MemberFilter.presenceActive, 'Active', data.presenceActiveCount,
          Icons.bolt_rounded),
      (MemberFilter.highAdoption, 'High adoption', data.highAdoptionCount,
          Icons.trending_up_rounded),
      (
        MemberFilter.needsAttention,
        'Needs attention',
        data.needsAttentionCount,
        Icons.warning_amber_rounded,
      ),
      (MemberFilter.blocked, 'Blocked', data.blockedCount,
          Icons.block_rounded),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (filter, label, count, icon) = chips[index];
          final selected = data.activeFilter == filter;
          return _ScaleOnTap(
            onTap: () => context
                .read<EngineeringManagerTeamsCubit>()
                .applyFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.primary, colors.secondary],
                      )
                    : null,
                color: selected ? null : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? Colors.transparent : colors.border,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: selected ? Colors.white : colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTypography.caption(
                            selected ? Colors.white : colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.24)
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
// Member card — photo avatar with status-colored ring, adoption ring /
// primary tool / sprint-pts row, and a single bottom row that carries both
// the productivity badge and the "View details" link. No capacity/workload
// bar here — that detail lives on the Employee Detail screen.
// ─────────────────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard(
      {required this.member, required this.colors, required this.onTap});

  final TeamMember member;
  final AppColorsData colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(member.engagementStatus, colors);

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
                      horizontal: AppSpacing.sm, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withValues(alpha: 0.18),
                        colors.secondary.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: colors.primary.withValues(alpha: 0.25)),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View details',
                        style: AppTypography.caption(colors.primary)
                            .copyWith(fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: colors.primary),
                  ],
                ),
              ],
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
// Engineer Detail screen — photo hero, Productivity / Workload / Budget /
// AI Tool Usage / Recent Activity sections, plus the four manager actions.
//
// v5 rebuild: every section below now shares one visual language — a
// gradient icon badge in the section header, and gradient-icon "stat
// tiles" in place of bare numbers — so the screen reads as a cohesive
// dashboard instead of a stack of plain text rows.
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

/// Section header + card shell shared by every detail-screen section below
/// — a gradient icon badge next to the title instead of plain text, so
/// each block is visually anchored the same way the rest of the app does
/// it (hero cards, KPI grids, quick actions).
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.colors,
    required this.child,
  });

  final String title;
  final IconData icon;
  final List<Color> accent;
  final AppColorsData colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: accent[0].withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(colors: accent),
                  boxShadow: [
                    BoxShadow(
                      color: accent[0].withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 15),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTypography.h3(colors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Small gradient-icon stat used inside section bodies, replacing bare
/// "number over label" columns.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
    required this.colors,
    this.valueColor,
  });

  final IconData icon;
  final List<Color> accent;
  final String value;
  final String label;
  final AppColorsData colors;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(colors: accent),
          ),
          child: Icon(icon, color: Colors.white, size: 13),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.body(valueColor ?? colors.textPrimary)
              .copyWith(fontWeight: FontWeight.w800, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: AppTypography.caption(colors.textSecondary)
              .copyWith(fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

const _kProductivityAccent = [Color(0xFF6C5CE7), Color(0xFF8E7CFF)];
const _kWorkloadAccent = [Color(0xFF2F80ED), Color(0xFF56CCF2)];
const _kBudgetAccent = [Color(0xFF11998E), Color(0xFF38EF7D)];
const _kToolsAccent = [Color(0xFFF2994A), Color(0xFFF2C94C)];
const _kActivityAccent = [Color(0xFFE85D75), Color(0xFF9B51E0)];

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
      icon: Icons.speed_rounded,
      accent: _kProductivityAccent,
      colors: colors,
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.military_tech_rounded,
              accent: _kProductivityAccent,
              value: '${member.productivityScore}',
              label: 'Score',
              colors: colors,
            ),
          ),
          Expanded(
            child: _StatTile(
              icon: Icons.check_circle_outline_rounded,
              accent: _kProductivityAccent,
              value: '$completionRate%',
              label: 'Task completion',
              colors: colors,
            ),
          ),
          Expanded(
            child: _StatTile(
              icon: Icons.auto_awesome_rounded,
              accent: _kProductivityAccent,
              value: member.primaryTool,
              label: 'AI-assisted',
              colors: colors,
            ),
          ),
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
    final capacityColor = _capacityColor();
    return _SectionCard(
      title: 'Workload',
      icon: Icons.view_kanban_rounded,
      accent: _kWorkloadAccent,
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.pending_actions_rounded,
                  accent: _kWorkloadAccent,
                  value: '${member.currentTasks}',
                  label: 'Current',
                  colors: colors,
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.task_alt_rounded,
                  accent: _kWorkloadAccent,
                  value: '${member.completedTasks}',
                  label: 'Completed',
                  colors: colors,
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.error_outline_rounded,
                  accent: member.overdueTasks > 0
                      ? [colors.danger, colors.danger.withValues(alpha: 0.7)]
                      : _kWorkloadAccent,
                  value: '${member.overdueTasks}',
                  label: 'Overdue',
                  valueColor: member.overdueTasks > 0 ? colors.danger : null,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Capacity',
                        style: AppTypography.caption(colors.textSecondary)),
                    const Spacer(),
                    Text('${member.capacityPercent}%',
                        style: AppTypography.caption(capacityColor)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                        begin: 0,
                        end: (member.capacityPercent / 100).clamp(0, 1.3)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation(capacityColor),
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

class _BudgetSection extends StatelessWidget {
  const _BudgetSection({required this.member, required this.colors});
  final TeamMember member;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    final remaining = (member.allocatedBudget - member.monthlyAiSpend)
        .clamp(0, double.infinity)
        .toDouble();
    final ratio = member.allocatedBudget <= 0
        ? 0.0
        : (member.monthlyAiSpend / member.allocatedBudget).clamp(0.0, 1.0);
    final barColor = ratio >= 0.95
        ? colors.danger
        : (ratio >= 0.8 ? colors.warning : colors.success);

    return _SectionCard(
      title: 'Budget',
      icon: Icons.account_balance_wallet_rounded,
      accent: _kBudgetAccent,
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.currency_rupee_rounded,
                  accent: _kBudgetAccent,
                  value: '₹${_formatAmount(member.monthlyAiSpend)}',
                  label: 'Spend',
                  colors: colors,
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.savings_rounded,
                  accent: _kBudgetAccent,
                  value: '₹${_formatAmount(member.allocatedBudget)}',
                  label: 'Allocated',
                  colors: colors,
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.account_balance_rounded,
                  accent: _kBudgetAccent,
                  value: '₹${_formatAmount(remaining)}',
                  label: 'Remaining',
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Spend vs allocated',
                        style: AppTypography.caption(colors.textSecondary)),
                    const Spacer(),
                    Text('${(ratio * 100).round()}%',
                        style: AppTypography.caption(barColor)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation(barColor),
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

class _ToolBreakdownSection extends StatelessWidget {
  const _ToolBreakdownSection({required this.member, required this.colors});

  final TeamMember member;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'AI Tool Usage',
      icon: Icons.extension_rounded,
      accent: _kToolsAccent,
      colors: colors,
      child: member.toolBreakdown.isEmpty
          ? Text('No AI tools in use',
              style: AppTypography.body(colors.textSecondary))
          : Column(
              children: [
                for (var i = 0; i < member.toolBreakdown.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom:
                            i == member.toolBreakdown.length - 1 ? 0 : AppSpacing.sm),
                    child: _ToolUsageTile(
                      toolName: member.toolBreakdown[i].toolName,
                      adoptionPercent:
                          member.toolBreakdown[i].adoptionPercent,
                      monthlySpend: member.toolBreakdown[i].monthlySpend,
                      colors: colors,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ToolUsageTile extends StatelessWidget {
  const _ToolUsageTile({
    required this.toolName,
    required this.adoptionPercent,
    required this.monthlySpend,
    required this.colors,
  });

  final String toolName;
  final int adoptionPercent;
  final double monthlySpend;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: const LinearGradient(colors: _kToolsAccent),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 14),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  toolName,
                  style: AppTypography.body(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.currency_rupee_rounded,
                      size: 12, color: colors.textSecondary),
                  Text(
                    monthlySpend.toStringAsFixed(0),
                    style: AppTypography.caption(colors.textSecondary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: adoptionPercent / 100),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: colors.border,
                      valueColor:
                          AlwaysStoppedAnimation(_kToolsAccent[0]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('$adoptionPercent%',
                  style: AppTypography.caption(_kToolsAccent[0])
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
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
      icon: Icons.history_rounded,
      accent: _kActivityAccent,
      colors: colors,
      child: member.recentActivity.isEmpty
          ? Text('No recent activity',
              style: AppTypography.body(colors.textSecondary))
          : Column(
              children: [
                for (var i = 0; i < member.recentActivity.length; i++)
                  _TimelineRow(
                    item: member.recentActivity[i],
                    color: _activityColor(member.recentActivity[i].status),
                    isLast: i == member.recentActivity.length - 1,
                    colors: colors,
                  ),
              ],
            ),
    );
  }
}

/// One row of the recent-activity timeline: a colored dot with a
/// connecting line down to the next item, so the list reads as a
/// continuous history rather than a flat stack of rows.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.color,
    required this.isLast,
    required this.colors,
  });

  final ActivityItem item;
  final Color color;
  final bool isLast;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: colors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
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
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.relativeTime,
                        style: AppTypography.caption(colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Four manager actions — View AI Usage / Adjust Tool Access / Request
/// Approval / Review Activity — built as a content-sized 2x2
/// (`IntrinsicHeight` + `Row`, no `GridView` `childAspectRatio`) using the
/// same gradient quick-action tile style as the Home screens, so it can't
/// overflow the way a fixed-aspect-ratio grid can.
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.colors});

  final AppColorsData colors;

  static const _accents = [
    [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
    [Color(0xFF2F80ED), Color(0xFF56CCF2)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFE85D75), Color(0xFFF2994A)],
  ];

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

    final rows = <List<int>>[];
    for (var i = 0; i < actions.length; i += 2) {
      rows.add([i, if (i + 1 < actions.length) i + 1]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions', style: AppTypography.h3(colors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        for (var r = 0; r < rows.length; r++) ...[
          if (r != 0) const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < rows[r].length; c++) ...[
                  if (c != 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ActionTile(
                      icon: actions[rows[r][c]].$1,
                      label: actions[rows[r][c]].$2,
                      accent: _accents[rows[r][c] % _accents.length],
                      colors: colors,
                      onTap: () =>
                          _showComingSoon(context, actions[rows[r][c]].$2),
                    ),
                  ),
                ],
                if (rows[r].length == 1) const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> accent;
  final AppColorsData colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: accent[0].withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(colors: accent),
                boxShadow: [
                  BoxShadow(
                    color: accent[0].withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTypography.caption(colors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}