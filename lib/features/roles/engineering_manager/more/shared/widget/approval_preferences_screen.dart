import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// More → Approval Preferences
///
/// "AI Approval Control Center" — lets an Engineering Manager configure how
/// AI spending requests are reviewed: auto-approval thresholds, alerting,
/// new-tool/subscription gating, team spend limits, and AI-driven smart
/// detection rules (risk, duplicate subscriptions, unusual spend, policy
/// violations). Self-contained (no external design-system deps) so it can
/// replace the in-progress placeholder directly — swap `_save()` for a real
/// ApprovalPreferencesCubit call.

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

class _RRColors {
  static const primary = Color(0xFF6D5BFF);
  static const secondary = Color(0xFF4B8BFF);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF8FAFC);
  static const border = Color(0xFFE5E7EB);
  static const ink = Color(0xFF111827);
  static const mutedInk = Color(0xFF6B7280);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ApprovalPreferencesScreen extends StatefulWidget {
  const ApprovalPreferencesScreen({super.key});

  @override
  State<ApprovalPreferencesScreen> createState() =>
      _ApprovalPreferencesScreenState();
}

class _ApprovalPreferencesScreenState extends State<ApprovalPreferencesScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _coreController;

  // ---- Preference state (swap for a real cubit) ----------------------
  bool _autoApprovalEnabled = true;
  double _autoApprovalMax = 2000; // ₹
  double _approvalThreshold = 5000; // ₹
  bool _highCostAlerts = true;
  bool _newAiToolApproval = true;
  bool _subscriptionRenewalApproval = false;
  double _teamMonthlyLimit = 150000; // ₹
  final double _teamCurrentUsage = 96500; // ₹

  bool _highRiskDetection = true;
  bool _duplicateSubscriptionDetection = true;
  bool _unusualSpendingAlerts = true;
  bool _policyViolationDetection = false;

  bool _saving = false;
  bool _showSavedBanner = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _coreController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _coreController.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int index, int total) {
    final start = (index / (total + 2)).clamp(0.0, 1.0);
    final end = (start + 0.5).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _showSavedBanner = true;
    });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _showSavedBanner = false);
  }

  @override
  Widget build(BuildContext context) {
    const totalSections = 9;

    return Scaffold(
      backgroundColor: _RRColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: _FadeSlide(
                    animation: _stagger(0, totalSections),
                    child: _AiApprovalIntelligenceCard(
                      controller: _coreController,
                      requestsAnalyzed: 128,
                      efficiency: 0.94,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FadeSlide(
                    animation: _stagger(1, totalSections),
                    child: _sectionLabel('Approval Rules'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FadeSlide(
                    animation: _stagger(2, totalSections),
                    child: _AutoApprovalCard(
                      enabled: _autoApprovalEnabled,
                      maxAmount: _autoApprovalMax,
                      onToggle: (v) => setState(() => _autoApprovalEnabled = v),
                      onAmountChanged: (v) =>
                          setState(() => _autoApprovalMax = v),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FadeSlide(
                    animation: _stagger(3, totalSections),
                    child: _ApprovalThresholdCard(
                      value: _approvalThreshold,
                      onChanged: (v) =>
                          setState(() => _approvalThreshold = v),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FadeSlide(
                    animation: _stagger(4, totalSections),
                    child: Column(
                      children: [
                        _ToggleRuleCard(
                          icon: Icons.warning_amber_rounded,
                          iconColor: _RRColors.warning,
                          title: 'High-Cost Request Alerts',
                          subtitle:
                              'Alert when requests exceed the configured threshold',
                          value: _highCostAlerts,
                          onChanged: (v) =>
                              setState(() => _highCostAlerts = v),
                        ),
                        const SizedBox(height: 12),
                        _ToggleRuleCard(
                          icon: Icons.extension_outlined,
                          iconColor: _RRColors.primary,
                          title: 'New AI Tool Approval',
                          subtitle:
                              'Require manager approval before a new AI tool can be added',
                          value: _newAiToolApproval,
                          onChanged: (v) =>
                              setState(() => _newAiToolApproval = v),
                        ),
                        const SizedBox(height: 12),
                        _ToggleRuleCard(
                          icon: Icons.autorenew_rounded,
                          iconColor: _RRColors.secondary,
                          title: 'Subscription Renewal',
                          subtitle:
                              'Require approval before AI subscription renewals',
                          value: _subscriptionRenewalApproval,
                          onChanged: (v) =>
                              setState(() => _subscriptionRenewalApproval = v),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FadeSlide(
                    animation: _stagger(5, totalSections),
                    child: _TeamSpendingLimitCard(
                      limit: _teamMonthlyLimit,
                      usage: _teamCurrentUsage,
                      onLimitChanged: (v) =>
                          setState(() => _teamMonthlyLimit = v),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FadeSlide(
                    animation: _stagger(6, totalSections),
                    child: _sectionLabel('AI Smart Rules'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FadeSlide(
                    animation: _stagger(7, totalSections),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        children: [
                          _SmartRuleCard(
                            icon: Icons.gpp_maybe_outlined,
                            title: 'High-Risk Spending Detection',
                            description:
                                'Flags requests that deviate sharply from a team\'s normal spending pattern.',
                            value: _highRiskDetection,
                            onChanged: (v) =>
                                setState(() => _highRiskDetection = v),
                          ),
                          const SizedBox(height: 12),
                          _SmartRuleCard(
                            icon: Icons.content_copy_outlined,
                            title: 'Duplicate Subscription Detection',
                            description:
                                'Detects overlapping tools or plans already covered by an existing subscription.',
                            value: _duplicateSubscriptionDetection,
                            onChanged: (v) => setState(
                                () => _duplicateSubscriptionDetection = v),
                          ),
                          const SizedBox(height: 12),
                          _SmartRuleCard(
                            icon: Icons.trending_up_rounded,
                            title: 'Unusual Spending Alerts',
                            description:
                                'Notifies you of sudden spikes or off-pattern spend across AI tools.',
                            value: _unusualSpendingAlerts,
                            onChanged: (v) =>
                                setState(() => _unusualSpendingAlerts = v),
                          ),
                          const SizedBox(height: 12),
                          _SmartRuleCard(
                            icon: Icons.policy_outlined,
                            title: 'Policy Violation Detection',
                            description:
                                'Checks new requests against org spending policy before they reach approval.',
                            value: _policyViolationDetection,
                            onChanged: (v) =>
                                setState(() => _policyViolationDetection = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FadeSlide(
                    animation: _stagger(8, totalSections),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                      child: _SaveButton(saving: _saving, onTap: _save),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SavedConfirmationOverlay(visible: _showSavedBanner),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: _RRColors.ink),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approval Preferences',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _RRColors.ink,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Configure how AI spending requests are reviewed',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _RRColors.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _RRColors.ink,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entrance animation wrapper
// ---------------------------------------------------------------------------

class _FadeSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _FadeSlide({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Opacity(
        opacity: animation.value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * 22),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// AI Approval Intelligence Card
// ---------------------------------------------------------------------------

class _AiApprovalIntelligenceCard extends StatelessWidget {
  final AnimationController controller;
  final int requestsAnalyzed;
  final double efficiency; // 0..1

  const _AiApprovalIntelligenceCard({
    required this.controller,
    required this.requestsAnalyzed,
    required this.efficiency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171432), Color(0xFF1E1B4B)],
        ),
        boxShadow: [
          BoxShadow(
            color: _RRColors.primary.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => CustomPaint(
                painter: _ApprovalCorePainter(progress: controller.value),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: controller,
                            builder: (context, _) {
                              final pulse =
                                  0.6 + 0.4 * sin(controller.value * 2 * pi);
                              return Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _RRColors.success
                                      .withValues(alpha: pulse.clamp(0.4, 1)),
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'AI Approval Engine · Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.shield_moon_outlined,
                        size: 16, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 130),
                Row(
                  children: [
                    Expanded(
                      child: _coreStat(
                        label: 'Analyzed today',
                        value: '$requestsAnalyzed',
                        icon: Icons.query_stats_rounded,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _coreStat(
                        label: 'Efficiency',
                        value: '${(efficiency * 100).round()}%',
                        icon: Icons.speed_rounded,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _coreStat(
                        label: 'Policy monitor',
                        value: 'Live',
                        icon: Icons.visibility_outlined,
                        valueColor: _RRColors.success,
                      ),
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

  Widget _coreStat({
    required String label,
    required String value,
    required IconData icon,
    Color valueColor = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _ApprovalCorePainter extends CustomPainter {
  final double progress;
  _ApprovalCorePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 92);

    // Faint grid.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, 170), gridPaint);
    }

    // Orbiting data particles around the core.
    const particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      final t = (progress + i / particleCount) % 1.0;
      final angle = t * 2 * pi;
      final radius = 46 + 10 * sin(progress * 2 * pi + i);
      final pos = center + Offset(cos(angle) * radius, sin(angle) * radius * 0.55);
      final glow = Paint()
        ..color = _RRColors.secondary.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(pos, 3, glow);
      canvas.drawCircle(pos, 1.6, Paint()..color = Colors.white);
    }

    // Flowing concentric rings.
    for (int ring = 1; ring <= 3; ring++) {
      final ringRadius = 30.0 + ring * 18 + 6 * sin(progress * 2 * pi + ring);
      final ringPaint = Paint()
        ..color = _RRColors.primary
            .withValues(alpha: (0.18 - ring * 0.03).clamp(0.02, 1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: ringRadius * 2,
          height: ringRadius * 1.15,
        ),
        ringPaint,
      );
    }

    // Pulsing core.
    final pulse = 0.5 + 0.5 * sin(progress * 2 * pi);
    canvas.drawCircle(
      center,
      30 + pulse * 6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _RRColors.primary.withValues(alpha: 0.4 * pulse + 0.12),
            _RRColors.primary.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 40)),
    );
    canvas.drawCircle(
      center,
      16,
      Paint()
        ..shader = const LinearGradient(
          colors: [_RRColors.primary, _RRColors.secondary],
        ).createShader(Rect.fromCircle(center: center, radius: 16)),
    );
    canvas.drawCircle(
      center,
      16,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Small AI glyph in the core (sparkle).
    final sparkPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    _drawSparkle(canvas, center, 6, sparkPaint);
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.28, c.dy - r * 0.28)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.28, c.dy + r * 0.28)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.28, c.dy + r * 0.28)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.28, c.dy - r * 0.28)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ApprovalCorePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Shared glass card shell
// ---------------------------------------------------------------------------

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  const _GlassCard({
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _RRColors.surface.withValues(alpha: 0.6),
              border: Border.all(color: _RRColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spring toggle
// ---------------------------------------------------------------------------

class _SpringToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SpringToggle({required this.value, required this.onChanged});

  @override
  State<_SpringToggle> createState() => _SpringToggleState();
}

class _SpringToggleState extends State<_SpringToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.value ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _SpringToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.value ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.elasticOut.transform(_controller.value);
          final tClamped = t.clamp(0.0, 1.0);
          return Container(
            width: 46,
            height: 27,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Color.lerp(_RRColors.border, _RRColors.primary, tClamped)!,
                  Color.lerp(_RRColors.border, _RRColors.secondary, tClamped)!,
                ],
              ),
            ),
            alignment:
                Alignment(-1 + 2 * _controller.value.clamp(0, 1), 0),
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
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

// ---------------------------------------------------------------------------
// Auto-Approval card
// ---------------------------------------------------------------------------

class _AutoApprovalCard extends StatelessWidget {
  final bool enabled;
  final double maxAmount;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onAmountChanged;

  const _AutoApprovalCard({
    required this.enabled,
    required this.maxAmount,
    required this.onToggle,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconBadge(Icons.bolt_rounded, _RRColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Approval',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _RRColors.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Enable auto-approval for low-value requests',
                        style: TextStyle(
                          fontSize: 12,
                          color: _RRColors.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
                _SpringToggle(value: enabled, onChanged: onToggle),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: enabled
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _AmountSlider(
                        label: 'Maximum auto-approval amount',
                        value: maxAmount,
                        min: 500,
                        max: 10000,
                        onChanged: onAmountChanged,
                        accent: _RRColors.primary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBadge(IconData icon, Color color) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
        ),
        child: Icon(icon, size: 18, color: color),
      );
}

// ---------------------------------------------------------------------------
// Approval Threshold card
// ---------------------------------------------------------------------------

class _ApprovalThresholdCard extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ApprovalThresholdCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approval Threshold',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _RRColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Requests above this amount require manual review',
              style: TextStyle(fontSize: 12, color: _RRColors.mutedInk),
            ),
            const SizedBox(height: 16),
            _AmountSlider(
              label: null,
              value: value,
              min: 1000,
              max: 25000,
              onChanged: onChanged,
              accent: _RRColors.secondary,
              big: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable amount slider with glow
// ---------------------------------------------------------------------------

class _AmountSlider extends StatelessWidget {
  final String? label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color accent;
  final bool big;

  const _AmountSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.accent,
    this.big = false,
  });

  String get _formatted => '₹${value.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (label != null)
              Text(
                label!,
                style: const TextStyle(fontSize: 12.5, color: _RRColors.mutedInk),
              )
            else
              const SizedBox.shrink(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Container(
                key: ValueKey(value.round()),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.14),
                      accent.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Text(
                  _formatted,
                  style: TextStyle(
                    fontSize: big ? 15 : 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: accent,
            inactiveTrackColor: _RRColors.border,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 18),
            thumbColor: Colors.white,
            overlayColor: accent.withValues(alpha: 0.15),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Glow behind the active track.
              Positioned(
                left: 0,
                right: 0,
                child: FractionallySizedBox(
                  widthFactor: ((value - min) / (max - min)).clamp(0.02, 1),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₹${min.round()}',
                style: const TextStyle(fontSize: 10.5, color: _RRColors.mutedInk)),
            Text('₹${max.round()}',
                style: const TextStyle(fontSize: 10.5, color: _RRColors.mutedInk)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Generic toggle rule card
// ---------------------------------------------------------------------------

class _ToggleRuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRuleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _RRColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: _RRColors.mutedInk),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SpringToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Team Spending Limit card
// ---------------------------------------------------------------------------

class _TeamSpendingLimitCard extends StatelessWidget {
  final double limit;
  final double usage;
  final ValueChanged<double> onLimitChanged;

  const _TeamSpendingLimitCard({
    required this.limit,
    required this.usage,
    required this.onLimitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (usage / limit).clamp(0.0, 1.0);
    final overBudget = ratio > 0.85;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _RRColors.secondary.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      size: 18, color: _RRColors.secondary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Team Spending Limit',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _RRColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(height: 10, color: _RRColors.border),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => FractionallySizedBox(
                      widthFactor: t,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: overBudget
                                ? [_RRColors.warning, _RRColors.danger]
                                : [_RRColors.primary, _RRColors.secondary],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${usage.round()} used',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _RRColors.ink,
                  ),
                ),
                Text(
                  '${(ratio * 100).round()}% of ₹${limit.round()}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: overBudget ? _RRColors.danger : _RRColors.mutedInk,
                    fontWeight: overBudget ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AmountSlider(
              label: 'Monthly limit',
              value: limit,
              min: 50000,
              max: 500000,
              onChanged: onLimitChanged,
              accent: _RRColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Smart rule card (AI Smart Rules section)
// ---------------------------------------------------------------------------

class _SmartRuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SmartRuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: value
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _RRColors.primary.withValues(alpha: 0.06),
                  _RRColors.secondary.withValues(alpha: 0.06),
                ],
              )
            : null,
        color: value ? null : Colors.white,
        border: Border.all(
          color: value ? _RRColors.primary.withValues(alpha: 0.25) : _RRColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value
                  ? _RRColors.primary.withValues(alpha: 0.12)
                  : _RRColors.mutedInk.withValues(alpha: 0.08),
            ),
            child: Icon(
              icon,
              size: 17,
              color: value ? _RRColors.primary : _RRColors.mutedInk,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _RRColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _RRColors.mutedInk,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SpringToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save button
// ---------------------------------------------------------------------------

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;
  const _SaveButton({required this.saving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [_RRColors.primary, _RRColors.secondary],
          ),
          boxShadow: [
            BoxShadow(
              color: _RRColors.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'Save Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved confirmation overlay
// ---------------------------------------------------------------------------

class _SavedConfirmationOverlay extends StatelessWidget {
  final bool visible;
  const _SavedConfirmationOverlay({required this.visible});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AnimatedScale(
                scale: visible ? 1 : 0.9,
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [_RRColors.primary, _RRColors.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _RRColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Preferences Updated',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}