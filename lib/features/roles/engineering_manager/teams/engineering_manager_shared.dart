// ASSUMPTION: import depth (`../../../../core/...`) matches the original
// engineering_manager_teams_screen.dart you uploaded verbatim, so this file
// and the 4 new screen files are assumed to sit in the SAME directory as
// engineering_manager_teams_screen.dart / engineering_manager_teams_cubit.dart.
// If your real folder layout differs, fix these 6 files' import paths
// together (they all share the same relative depth).
//
// Shared vocabulary extracted out of engineering_manager_teams_screen.dart so
// the new screens (Performance, Tool Detail, AI Usage, Budget) can reuse the
// exact same animation helpers, ring painter, avatar palette, and status-pill
// logic instead of duplicating them. Nothing here changes visual behavior —
// it's the same code, just made public (no leading underscore) and moved to
// its own file so it can be imported.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import 'engineering_manager_teams_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────
// Animation helpers
// ─────────────────────────────────────────────────────────────────────────

class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({super.key, required this.index, required this.child});

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

class ScaleOnTap extends StatefulWidget {
  const ScaleOnTap({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> {
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

Route<T> slideFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
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

void showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature is coming soon')),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Ring painter + counters
// ─────────────────────────────────────────────────────────────────────────

class RingPainter extends CustomPainter {
  RingPainter({required this.progress, required this.color, this.trackAlpha = 0.25});

  final double progress;
  final Color color;
  final double trackAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final track = Paint()
      ..color = color.withValues(alpha: trackAlpha)
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
      2 * math.pi * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class AnimatedOnTrackRing extends StatelessWidget {
  const AnimatedOnTrackRing({
    super.key,
    required this.percent,
    required this.color,
    this.size = 64,
  });

  final int percent;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: RingPainter(progress: value, color: color),
            child: Center(
              child: Text(
                '${(value * 100).round()}%',
                style: AppTypography.caption(color).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({super.key, required this.value, required this.style, this.suffix = ''});

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
// Hero metric pill (white-on-gradient)
// ─────────────────────────────────────────────────────────────────────────

class HeroMetricPill extends StatelessWidget {
  const HeroMetricPill({super.key, required this.label, required this.value});

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
          Text(value, style: AppTypography.h3(Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption(Colors.white.withValues(alpha: 0.85)).copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Avatars
// ─────────────────────────────────────────────────────────────────────────

const List<Color> kAvatarPalette = [
  Color(0xFF6C5CE7),
  Color(0xFF2F80ED),
  Color(0xFFE85D75),
  Color(0xFFF2994A),
  Color(0xFF11998E),
  Color(0xFF9B51E0),
];

Color avatarColorFor(String name) {
  final hash = name.codeUnits.fold<int>(0, (acc, c) => acc + c);
  return kAvatarPalette[hash % kAvatarPalette.length];
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = avatarColorFor(name);
    final initials = name.isEmpty ? '?' : name.trim().split(' ').take(2).map((s) => s[0]).join();
    return Container(
      width: size,
      height: size,
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
        initials.toUpperCase(),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.32),
      ),
    );
  }
}

class InitialsAvatarOnGradient extends StatelessWidget {
  const InitialsAvatarOnGradient({super.key, required this.name, this.size = 52});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.isEmpty ? '?' : name.trim().split(' ').take(2).map((s) => s[0]).join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials.toUpperCase(), style: AppTypography.h3(Colors.white)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Status pill helpers (member engagement + team health)
// ─────────────────────────────────────────────────────────────────────────

class StatusInfo {
  const StatusInfo(this.label, this.color, this.bg);
  final String label;
  final Color color;
  final Color bg;
}

StatusInfo statusInfoFor(MemberEngagementStatus status, AppColorsData colors) {
  switch (status) {
    case MemberEngagementStatus.onTrack:
      return StatusInfo('On Track', colors.success, colors.success.withValues(alpha: 0.14));
    case MemberEngagementStatus.needsAttention:
      return StatusInfo('Needs Attention', colors.warning, colors.warning.withValues(alpha: 0.14));
    case MemberEngagementStatus.overloaded:
      return StatusInfo('Overloaded', colors.danger, colors.danger.withValues(alpha: 0.14));
  }
}

StatusInfo teamHealthStatusInfo(TeamHealthStatus status, AppColorsData colors) {
  switch (status) {
    case TeamHealthStatus.healthy:
      return StatusInfo('Healthy', colors.success, colors.success.withValues(alpha: 0.14));
    case TeamHealthStatus.warning:
      return StatusInfo('Warning', colors.warning, colors.warning.withValues(alpha: 0.14));
    case TeamHealthStatus.critical:
      return StatusInfo('Critical', colors.danger, colors.danger.withValues(alpha: 0.14));
  }
}

/// Green/amber/red bar color for a workload/capacity percentage.
Color workloadColor(int capacityPercent, AppColorsData colors) {
  if (capacityPercent > 100) return colors.danger;
  if (capacityPercent >= 85) return colors.warning;
  return colors.success;
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.info});

  final StatusInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: info.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        info.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: info.color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Currency — NEVER a raw ₹/$ symbol string (tofu box on this font).
// ─────────────────────────────────────────────────────────────────────────

class CurrencyValue extends StatelessWidget {
  const CurrencyValue({
    super.key,
    required this.value,
    required this.style,
    this.iconSize = 12,
    this.iconColor,
  });

  final double value;
  final TextStyle style;
  final double iconSize;
  final Color? iconColor;

  static String format(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.currency_rupee_rounded, size: iconSize, color: iconColor ?? style.color),
        Text(format(value), style: style),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Generic section card shell reused by the new sections/screens.
// ─────────────────────────────────────────────────────────────────────────

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.colors,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final AppColorsData colors;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.colors,
    this.trailing,
  });

  final String title;
  final AppColorsData colors;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.h3(colors.textPrimary))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class TextCta extends StatelessWidget {
  const TextCta({super.key, required this.label, required this.onTap, required this.color});

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}