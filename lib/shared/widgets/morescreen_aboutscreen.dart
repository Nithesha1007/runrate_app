// ============================================================================
// more_screen.dart
// Engineering Manager → More
//
// ASSUMPTIONS (please reconcile with your real design system before merging):
//   1. `EmScreenScaffold` signature matches the stub you pasted:
//        EmScreenScaffold({ required String title, required Widget body })
//      If it also exposes e.g. `showAppBar` / `scrollable` params, wire this
//      screen's own SingleChildScrollView through them instead of double
//      scrolling.
//   2. I don't have your real `AppColors.of(context)` / `AppTypography` /
//      `AppSpacing` classes in this chat, so I've defined local
//      `_RunrateColors`, `_RunrateType`, `_gap()` helpers using the exact
//      hex values you gave me. Swap these call sites for your real theme
//      tokens — the structure/usage pattern is identical
//      (`_RunrateColors.primary` → `AppColors.of(context).primary`, etc.)
//      so it should be a find/replace.
//   3. Navigation to About Runrate / Settings / Integrations / etc. uses a
//      plain `Navigator.push(MaterialPageRoute(...))` with a 
//      where your custom slide+fade `PageRouteBuilder` should go instead.
//   4. No external packages used — everything (glass blur, particle grid,
//      stagger, pulse) is built with core Flutter (`BackdropFilter`,
//      `CustomPainter`, `AnimationController`) so this compiles standalone.
// ============================================================================

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/about_runrate_screen.dart';

// ---------------------------------------------------------------------------
// Local design tokens (swap for your real AppColors / AppTypography / AppSpacing)
// ---------------------------------------------------------------------------

class _RunrateColors {
  static const primary = Color(0xFF6D5BFF); // violet
  static const secondary = Color(0xFF4B8BFF); // blue
  static const tint = Color(0xFFEEF0FF); // light lavender surface
  static const surface = Color(0xFFF8FAFC); // page background
  static const ink = Color(0xFF111827); // primary text
  static const muted = Color(0xFF6B7280); // secondary text
  static const danger = Color(0xFFEF4444);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}

class _RunrateType {
  static const title = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: _RunrateColors.ink,
    letterSpacing: -0.2,
  );
  static const cardTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: _RunrateColors.ink,
  );
  static const cardSubtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: _RunrateColors.muted,
  );
  static const label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: _RunrateColors.primary,
    letterSpacing: 0.4,
  );
}

double _gap(num units) => units * 8.0; // 8-point spacing scale

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MoreScreen extends StatefulWidget {
  const MoreScreen({
    super.key,
    this.managerName = 'Arjun Mehta',
    this.managerEmail = 'arjun.mehta@company.com',
    this.teamLabel = 'Platform Engineering · 12 members',
  });

  final String managerName;
  final String managerEmail;
  final String teamLabel;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;

  // Order drives the staggered reveal.
  late final List<_MoreItemData> _items;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _items = [
      _MoreItemData(
        icon: Icons.hub_outlined,
        title: 'Integrations',
        subtitle: '6 connected · 1 needs attention',
        showPulse: true,
        onTap: (context) => _navigatePlaceholder(context, 'Integrations'),
      ),
      _MoreItemData(
        icon: Icons.help_outline_rounded,
        title: 'Help & Support',
        subtitle: 'Guides, contact, and live chat',
        onTap: (context) => _navigatePlaceholder(context, 'Help & Support'),
      ),
      _MoreItemData(
        icon: Icons.info_outline_rounded,
        title: 'About Runrate',
        subtitle: 'Version, mission, and legal',
        onTap: (context) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutRunrateScreen()),
        ),
      ),
      _MoreItemData(
        icon: Icons.tune_rounded,
        title: 'Settings',
        subtitle: 'Notifications, preferences, theme',
        onTap: (context) => _navigatePlaceholder(context, 'Settings'),
      ),
      _MoreItemData(
        icon: Icons.shield_outlined,
        title: 'Security & Privacy',
        subtitle: 'Two-factor auth, sessions, data',
        onTap: (context) => _navigatePlaceholder(context, 'Security & Privacy'),
      ),
    ];
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _navigatePlaceholder(BuildContext context, String label) {
    // TODO: wire real destinations.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
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
    // If EmScreenScaffold already provides an app bar + scroll body, drop the
    // Scaffold/AppBar below and return just the Stack as `body:`.
    return Scaffold(
      backgroundColor: _RunrateColors.surface,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SoftGridPainter())),
          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(_gap(2), _gap(2), _gap(2), _gap(5)),
              children: [
                Text('More', style: _RunrateType.title),
                SizedBox(height: _gap(3)),
                _buildProfileCard(0, _items.length + 2),
                SizedBox(height: _gap(3)),
                ..._buildMenuCards(),
                SizedBox(height: _gap(3)),
                _buildLogoutCard(_items.length + 1, _items.length + 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(int index, int total) {
    final anim = _stagger(index, total);
    return _StaggeredIn(
      animation: anim,
      child: _GlassCard(
        padding: EdgeInsets.all(_gap(2.5)),
        child: Row(
          children: [
            _GlowAvatar(initials: _initialsOf(widget.managerName)),
            SizedBox(width: _gap(2)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.managerName, style: _RunrateType.cardTitle),
                  const SizedBox(height: 2),
                  Text(widget.managerEmail, style: _RunrateType.cardSubtitle),
                  SizedBox(height: _gap(1)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _RunrateColors.tint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child:
                        Text('ENGINEERING MANAGER', style: _RunrateType.label),
                  ),
                ],
              ),
            ),
            _AnimatedIconTap(
              icon: Icons.chevron_right_rounded,
              onTap: () => _navigatePlaceholder(context, 'Profile'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuCards() {
    final total = _items.length + 2;
    return List.generate(_items.length, (i) {
      final item = _items[i];
      final anim = _stagger(i + 1, total);
      return Padding(
        padding: EdgeInsets.only(bottom: _gap(1.5)),
        child: _StaggeredIn(
          animation: anim,
          child: _MoreTile(item: item),
        ),
      );
    });
  }

  Widget _buildLogoutCard(int index, int total) {
    final anim = _stagger(index, total);
    return _StaggeredIn(
      animation: anim,
      child: _GlassCard(
        borderColor: _RunrateColors.danger.withValues(alpha: 0.25),
        padding: EdgeInsets.symmetric(horizontal: _gap(2.5), vertical: _gap(2)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _confirmLogout(context),
          child: Row(
            children: [
              Icon(Icons.logout_rounded,
                  color: _RunrateColors.danger, size: 20),
              SizedBox(width: _gap(1.5)),
              Text(
                'Log Out',
                style: _RunrateType.cardTitle.copyWith(
                  color: _RunrateColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out of Runrate?'),
        content: const Text(
            'You\'ll need to sign in again to access your workspace.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx), // TODO: wire real sign-out
            child:
                Text('Log Out', style: TextStyle(color: _RunrateColors.danger)),
          ),
        ],
      ),
    );
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _MoreItemData {
  _MoreItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showPulse = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool showPulse;
  final void Function(BuildContext context) onTap;
}

// ---------------------------------------------------------------------------
// Menu tile
// ---------------------------------------------------------------------------

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.item});

  final _MoreItemData item;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: EdgeInsets.symmetric(horizontal: _gap(2), vertical: _gap(1.75)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => item.onTap(context),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _RunrateColors.primary.withValues(alpha: 0.12),
                        _RunrateColors.secondary.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(item.icon, color: _RunrateColors.primary, size: 20),
                ),
                if (item.showPulse)
                  const Positioned(
                      right: -2, top: -2, child: _ConnectionPulseDot()),
              ],
            ),
            SizedBox(width: _gap(2)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: _RunrateType.cardTitle),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: _RunrateType.cardSubtitle),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _RunrateColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Small breathing dot on the Integrations icon signalling live connections.
class _ConnectionPulseDot extends StatefulWidget {
  const _ConnectionPulseDot();

  @override
  State<_ConnectionPulseDot> createState() => _ConnectionPulseDotState();
}

class _ConnectionPulseDotState extends State<_ConnectionPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final scale = 1.0 + (t * 1.6);
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _RunrateColors.secondary
                        .withValues(alpha: opacity * 0.5),
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _RunrateColors.secondary,
                  boxShadow: [
                    BoxShadow(
                      color: _RunrateColors.secondary.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

/// Fade + upward-motion wrapper used for the staggered entrance.
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

/// Frosted glass card: translucent fill + blur + fine glowing border.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;
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
              color:
                  borderColor ?? _RunrateColors.primary.withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _RunrateColors.primary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowAvatar extends StatelessWidget {
  const _GlowAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: _RunrateColors.gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _RunrateColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Icon button with a subtle scale-down tap animation.
class _AnimatedIconTap extends StatefulWidget {
  const _AnimatedIconTap({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_AnimatedIconTap> createState() => _AnimatedIconTapState();
}

class _AnimatedIconTapState extends State<_AnimatedIconTap> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.86),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Icon(widget.icon, color: _RunrateColors.muted, size: 22),
      ),
    );
  }
}

/// Very faint dot-grid + drifting particles for depth. Kept low-opacity so
/// it reads as texture, not noise.
class _SoftGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = _RunrateColors.primary.withValues(alpha: 0.04);
    const spacing = 28.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _RunrateColors.secondary.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.05),
        radius: 220,
      ));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.05), 220, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Unused import guard for math (kept for parity with about screen palette
// utilities if you later share the painter code between screens).
// ignore: unused_element
double _unusedMathRef() => math.pi;
