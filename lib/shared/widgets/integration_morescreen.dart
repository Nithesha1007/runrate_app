import 'dart:ui';
import 'package:flutter/material.dart';

/// Engineering Manager → More
///
/// A next-generation "control center" landing screen for secondary
/// destinations: profile identity, Integrations, Help & Support, About,
/// Settings, Security/Privacy, and Logout. Staggered fade+rise entrance,
/// glassmorphic cards, soft purple-blue gradients, subtle grid backdrop.
///
/// Wire `onNavigate` to your router (e.g. push IntegrationsScreen,
/// SecurityScreen, etc.) and `onLogout` to your auth cubit.

class _RRColors {
  static const primary = Color(0xFF6D5BFF);
  static const secondary = Color(0xFF4B8BFF);
  static const glassTint = Color(0xFFEEF0FF);
  static const surface = Color(0xFFF8FAFC);
  static const ink = Color(0xFF111827);
  static const mutedInk = Color(0xFF6B7280);
  static const danger = Color(0xFFEF4444);
}

enum EmMoreDestination {
  integrations,
  helpSupport,
  aboutRunrate,
  settings,
  security,
}

class EmMoreScreen extends StatefulWidget {
  final String managerName;
  final String managerRole;
  final String? avatarInitials;
  final void Function(EmMoreDestination destination)? onNavigate;
  final VoidCallback? onEditProfile;
  final VoidCallback? onLogout;

  const EmMoreScreen({
    super.key,
    this.managerName = 'Engineering Manager',
    this.managerRole = 'Engineering · Runrate',
    this.avatarInitials,
    this.onNavigate,
    this.onEditProfile,
    this.onLogout,
  });

  @override
  State<EmMoreScreen> createState() => _EmMoreScreenState();
}

class _EmMoreScreenState extends State<EmMoreScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _gridController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int index, int total) {
    final start = index / (total + 2);
    final end = start + 0.5;
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start.clamp(0, 1), end.clamp(0, 1),
          curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _menuItems();

    return Scaffold(
      backgroundColor: _RRColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridController,
              builder: (context, _) => CustomPaint(
                painter: _AmbientGridPainter(progress: _gridController.value),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Text(
                      'More',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _RRColors.ink,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FadeRise(
                    animation: _stagger(0, items.length + 1),
                    child: _ProfileCard(
                      name: widget.managerName,
                      role: widget.managerRole,
                      initials: widget.avatarInitials ??
                          _initialsFrom(widget.managerName),
                      onEdit: widget.onEditProfile,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _FadeRise(
                        animation: _stagger(index + 1, items.length + 1),
                        child: _MoreTile(
                          data: item,
                          onTap: () {
                            if (item.destination != null) {
                              widget.onNavigate?.call(item.destination!);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FadeRise(
                    animation: _stagger(items.length + 1, items.length + 1),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: _LogoutTile(onTap: widget.onLogout),
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

  String _initialsFrom(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'EM';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  List<_MoreItemData> _menuItems() => const [
        _MoreItemData(
          icon: Icons.hub_outlined,
          title: 'Integrations',
          subtitle: 'Connect AI, cloud & dev tools',
          destination: EmMoreDestination.integrations,
          showPulse: true,
        ),
        _MoreItemData(
          icon: Icons.support_agent_outlined,
          title: 'Help & Support',
          subtitle: 'Guides, FAQs & contact',
          destination: EmMoreDestination.helpSupport,
        ),
        _MoreItemData(
          icon: Icons.info_outline_rounded,
          title: 'About Runrate',
          subtitle: 'Version, licenses & policies',
          destination: EmMoreDestination.aboutRunrate,
        ),
        _MoreItemData(
          icon: Icons.tune_rounded,
          title: 'Settings',
          subtitle: 'Preferences & notifications',
          destination: EmMoreDestination.settings,
        ),
        _MoreItemData(
          icon: Icons.shield_outlined,
          title: 'Security & Privacy',
          subtitle: 'Password, 2FA & data controls',
          destination: EmMoreDestination.security,
        ),
      ];
}

class _MoreItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final EmMoreDestination? destination;
  final bool showPulse;

  const _MoreItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.destination,
    this.showPulse = false,
  });
}

// ---------------------------------------------------------------------------
// Entrance animation wrapper
// ---------------------------------------------------------------------------

class _FadeRise extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _FadeRise({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Opacity(
        opacity: animation.value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * 20),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Profile card
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  final String initials;
  final VoidCallback? onEdit;

  const _ProfileCard({
    required this.name,
    required this.role,
    required this.initials,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.8),
                  _RRColors.glassTint.withOpacity(0.6),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.7)),
              boxShadow: [
                BoxShadow(
                  color: _RRColors.primary.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_RRColors.primary, _RRColors.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _RRColors.primary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _RRColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _RRColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Engineering Manager',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _RRColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _RRColors.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: _RRColors.mutedInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu tile
// ---------------------------------------------------------------------------

class _MoreTile extends StatefulWidget {
  final _MoreItemData data;
  final VoidCallback onTap;

  const _MoreTile({required this.data, required this.onTap});

  @override
  State<_MoreTile> createState() => _MoreTileState();
}

class _MoreTileState extends State<_MoreTile>
    with SingleTickerProviderStateMixin {
  double _scale = 1;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDEFF7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (data.showPulse)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final v = _pulseController.value;
                          return Container(
                            width: 42 + v * 10,
                            height: 42 + v * 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _RRColors.primary
                                  .withOpacity((1 - v) * 0.18),
                            ),
                          );
                        },
                      ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _RRColors.primary.withOpacity(0.12),
                            _RRColors.secondary.withOpacity(0.12),
                          ],
                        ),
                      ),
                      child: Icon(data.icon, size: 18, color: _RRColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: _RRColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _RRColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: _RRColors.mutedInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout tile
// ---------------------------------------------------------------------------

class _LogoutTile extends StatelessWidget {
  final VoidCallback? onTap;
  const _LogoutTile({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _RRColors.danger.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _RRColors.danger.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 18, color: _RRColors.danger),
            const SizedBox(width: 8),
            const Text(
              'Log Out',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _RRColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ambient background grid / particle drift
// ---------------------------------------------------------------------------

class _AmbientGridPainter extends CustomPainter {
  final double progress;
  _AmbientGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Soft floating gradient blobs, top-right and bottom-left, to add
    // depth without visual noise.
    final blob1 = Paint()
      ..shader = RadialGradient(
        colors: [
          _RRColors.primary.withOpacity(0.08),
          _RRColors.primary.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.06 + progress * 10),
        radius: 140,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.06 + progress * 10),
      140,
      blob1,
    );

    final blob2 = Paint()
      ..shader = RadialGradient(
        colors: [
          _RRColors.secondary.withOpacity(0.07),
          _RRColors.secondary.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.1, size.height * 0.9 - progress * 12),
        radius: 160,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.9 - progress * 12),
      160,
      blob2,
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}