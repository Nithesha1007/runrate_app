// ============================================================================
// about_runrate_screen.dart
// More → About Runrate
//
// Replaces the EmScreenInProgress stub with the full experience: an
// animated AI neural-core / orbit visualization, "Intelligence for every
// AI spend." statement, and the full section list.
//
// ASSUMPTIONS (same caveats as more_screen.dart):
//   1. `EmScreenScaffold(title: ..., body: ...)` signature per your stub —
//      I've kept using it directly here since you already wired it in.
//   2. Local `_RunrateColors` / `_RunrateType` stand in for your real
//      `AppColors.of(context)` / `AppTypography` — swap 1:1.
//   3. True scroll-position-triggered reveal (each section animating in as
//      it crosses into the viewport) normally wants a visibility package
//      (e.g. `visibility_detector`). To keep this dependency-free I've
//      implemented the "smooth transitions" as a staggered fade+rise on
//      screen open, which reads the same on first view. If you already
//      depend on `visibility_detector` elsewhere, say the word and I'll
//      wire true scroll-linked reveals instead.
//   4. Version/build numbers are placeholders — wire to `package_info_plus`
//      or your existing constant if you already read it elsewhere.
// ============================================================================

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';

// ---------------------------------------------------------------------------
// Local design tokens (swap for your real theme system)
// ---------------------------------------------------------------------------

class _RunrateColors {
  static const primary = Color(0xFF6D5BFF);
  static const secondary = Color(0xFF4B8BFF);
  static const tint = Color(0xFFEEF0FF);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}

class _RunrateType {
  static const statement = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: _RunrateColors.ink,
    height: 1.4,
  );
  static const cardTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: _RunrateColors.ink,
  );
  static const cardSubtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: _RunrateColors.muted,
  );
}

double _gap(num units) => units * 8.0;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AboutRunrateScreen extends StatefulWidget {
  const AboutRunrateScreen({super.key});

  @override
  State<AboutRunrateScreen> createState() => _AboutRunrateScreenState();
}

class _AboutRunrateScreenState extends State<AboutRunrateScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbit;
  late final AnimationController _entrance;

  final List<_AboutSection> _sections = const [
    _AboutSection(
      icon: Icons.info_outline_rounded,
      title: 'About Runrate',
      subtitle:
          'Enterprise AI spend intelligence, built for finance and engineering.',
    ),
    _AboutSection(
      icon: Icons.smart_toy_outlined,
      title: 'AI Spend Copilot',
      subtitle:
          'Your always-on copilot for tracking, forecasting, and governing AI cost.',
    ),
    _AboutSection(
      icon: Icons.tag_outlined,
      title: 'Version',
      subtitle: 'v2.4.1 (Build 1042)',
    ),
    _AboutSection(
      icon: Icons.flag_outlined,
      title: 'Our Mission',
      subtitle: 'Give every organization clarity and control over AI spend.',
    ),
    _AboutSection(
      icon: Icons.shield_outlined,
      title: 'Security & Privacy',
      subtitle: 'SOC 2-aligned practices, encryption in transit and at rest.',
    ),
    _AboutSection(
      icon: Icons.description_outlined,
      title: 'Terms of Service',
      subtitle: 'The terms that govern your use of Runrate.',
    ),
    _AboutSection(
      icon: Icons.privacy_tip_outlined,
      title: 'Privacy Policy',
      subtitle: 'How we collect, use, and protect your data.',
    ),
    _AboutSection(
      icon: Icons.code_rounded,
      title: 'Open Source Licenses',
      subtitle: 'Third-party libraries that power Runrate.',
    ),
    _AboutSection(
      icon: Icons.mail_outline_rounded,
      title: 'Contact',
      subtitle: 'support@runrate.ai',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _orbit.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int index, int total) {
    final start = (index / (total + 2)).clamp(0.0, 1.0);
    final end = ((index + 3) / (total + 2)).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmScreenScaffold(
      title: 'About Runrate',
      padded: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _AmbientFieldPainter(_orbit)),
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(_gap(2), _gap(1), _gap(2), _gap(5)),
            children: [
              SizedBox(height: _gap(1)),
              _NeuralCore(controller: _orbit),
              SizedBox(height: _gap(3)),
              const Text(
                'Intelligence for every AI spend.',
                textAlign: TextAlign.center,
                style: _RunrateType.statement,
              ),
              SizedBox(height: _gap(4)),
              ...List.generate(_sections.length, (i) {
                final anim = _stagger(i, _sections.length);
                return Padding(
                  padding: EdgeInsets.only(bottom: _gap(1.5)),
                  child: _StaggeredIn(
                    animation: anim,
                    child: _SectionTile(section: _sections[i]),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutSection {
  const _AboutSection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

// ---------------------------------------------------------------------------
// Neural-core / orbit visualization
// ---------------------------------------------------------------------------

class _NeuralCore extends StatelessWidget {
  const _NeuralCore({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _OrbitPainter(t: controller.value),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: _RunrateColors.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _RunrateColors.primary.withValues(
                          alpha: 0.45 +
                              0.1 * math.sin(controller.value * 2 * math.pi)),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 26),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Draws two slowly counter-rotating orbital rings with glowing nodes and
/// faint connecting lines back to the core — restrained, not "gamey".
class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.t});

  final double t; // 0..1 looping

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    _drawRing(
      canvas,
      center: center,
      radius: 68,
      rotation: t * 2 * math.pi,
      nodeCount: 3,
      color: _RunrateColors.primary,
    );
    _drawRing(
      canvas,
      center: center,
      radius: 100,
      rotation: -t * 2 * math.pi * 0.6,
      nodeCount: 4,
      color: _RunrateColors.secondary,
    );
  }

  void _drawRing(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
    required int nodeCount,
    required Color color,
  }) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.16);
    canvas.drawCircle(center, radius, ringPaint);

    for (int i = 0; i < nodeCount; i++) {
      final angle = rotation + (2 * math.pi / nodeCount) * i;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * radius;

      // Faint connecting line to core.
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.10);
      canvas.drawLine(center, pos, linePaint);

      // Glowing node.
      final nodeGlow = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, 5, nodeGlow);

      final nodeCore = Paint()..color = color.withValues(alpha: 0.9);
      canvas.drawCircle(pos, 2.4, nodeCore);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) => oldDelegate.t != t;
}

/// Very low-opacity drifting particles + gradient wash across the whole
/// screen for ambient depth — sits behind everything.
class _AmbientFieldPainter extends CustomPainter {
  _AmbientFieldPainter(this.controller) : super(repaint: controller);

  final Animation<double> controller;

  @override
  void paint(Canvas canvas, Size size) {
    final t = controller.value;

    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          _RunrateColors.tint.withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.06),
        radius: 260,
      ));
    canvas.drawRect(Offset.zero & size, wash);

    final particlePaint = Paint()
      ..color = _RunrateColors.secondary.withValues(alpha: 0.10);
    const count = 22;
    for (int i = 0; i < count; i++) {
      final seed = i * 47.0;
      final x = (math.sin(seed) * 0.5 + 0.5) * size.width;
      final baseY = (math.cos(seed * 1.3) * 0.5 + 0.5) * size.height;
      final y = (baseY + t * 40) % size.height;
      canvas.drawCircle(Offset(x, y), 1.4, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientFieldPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Section tile + shared primitives
// ---------------------------------------------------------------------------

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});

  final _AboutSection section;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: EdgeInsets.symmetric(horizontal: _gap(2), vertical: _gap(1.75)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _RunrateColors.primary.withValues(alpha: 0.12),
                    _RunrateColors.secondary.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child:
                  Icon(section.icon, color: _RunrateColors.primary, size: 18),
            ),
            SizedBox(width: _gap(2)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: _RunrateType.cardTitle),
                  const SizedBox(height: 2),
                  Text(
                    section.subtitle,
                    style: _RunrateType.cardSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _RunrateColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _StaggeredIn extends StatelessWidget {
  const _StaggeredIn({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    const radius = 18.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: _RunrateColors.primary.withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _RunrateColors.primary.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
