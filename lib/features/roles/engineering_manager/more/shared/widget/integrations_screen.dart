import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// More → Integrations
///
/// "AI Infrastructure Command Center" — a centralized hub for connecting
/// Runrate to AI providers, cloud platforms, dev tools, communication,
/// productivity and finance systems. Built around a glassmorphic,
/// purple-blue futuristic language consistent with the EM "More" suite.
///
/// Visual language:
///   - Base surface: #F8FAFC, card glass tint: #EEF0FF
///   - Primary accent: #6D5BFF, secondary accent: #4B8BFF
///   - Ink: #111827, muted ink: #6B7280
///
/// This screen is self-contained (no external design system deps) so it
/// can be dropped into the EM `more/integrations/` feature folder and
/// wired to a real IntegrationsCubit later — see [_IntegrationsScreenState]
/// for the single spot (`_integrations` + `_toggleConnection`) where a
/// cubit/bloc would replace local state.

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

class _RRColors {
  static const primary = Color(0xFF6D5BFF);
  static const secondary = Color(0xFF4B8BFF);
  static const glassTint = Color(0xFFEEF0FF);
  static const surface = Color(0xFFF8FAFC);
  static const ink = Color(0xFF111827);
  static const mutedInk = Color(0xFF6B7280);
  static const success = Color(0xFF22C55E);
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

enum IntegrationCategory {
  aiProviders('AI Providers', Icons.psychology_outlined),
  cloudPlatforms('Cloud Platforms', Icons.cloud_queue_rounded),
  developerTools('Developer Tools', Icons.terminal_rounded),
  communication('Communication', Icons.forum_outlined),
  productivity('Productivity', Icons.workspaces_outlined),
  finance('Finance', Icons.account_balance_outlined);

  final String label;
  final IconData icon;
  const IntegrationCategory(this.label, this.icon);
}

class IntegrationModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final IntegrationCategory category;
  bool connected;
  String? lastSynced;
  double connectionStrength; // 0..1, drives the pulse intensity

  IntegrationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.connected = false,
    this.lastSynced,
    this.connectionStrength = 0.7,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  IntegrationCategory _selectedCategory = IntegrationCategory.aiProviders;

  // Local demo state — swap for IntegrationsCubit in production.
  final List<IntegrationModel> _integrations = [
    IntegrationModel(
      id: 'openai',
      name: 'OpenAI',
      description: 'GPT model usage & spend tracking',
      icon: Icons.auto_awesome_outlined,
      category: IntegrationCategory.aiProviders,
      connected: true,
      lastSynced: '2 minutes ago',
      connectionStrength: 0.9,
    ),
    IntegrationModel(
      id: 'anthropic',
      name: 'Anthropic',
      description: 'Claude API cost & token analytics',
      icon: Icons.hub_outlined,
      category: IntegrationCategory.aiProviders,
      connected: true,
      lastSynced: '5 minutes ago',
      connectionStrength: 0.8,
    ),
    IntegrationModel(
      id: 'cohere',
      name: 'Cohere',
      description: 'Embeddings & generation spend',
      icon: Icons.blur_on_outlined,
      category: IntegrationCategory.aiProviders,
      connected: false,
    ),
    IntegrationModel(
      id: 'aws',
      name: 'AWS',
      description: 'Compute & storage cost sync',
      icon: Icons.cloud_outlined,
      category: IntegrationCategory.cloudPlatforms,
      connected: true,
      lastSynced: '12 minutes ago',
      connectionStrength: 0.85,
    ),
    IntegrationModel(
      id: 'gcp',
      name: 'Google Cloud',
      description: 'GCP billing & usage insights',
      icon: Icons.dns_outlined,
      category: IntegrationCategory.cloudPlatforms,
      connected: false,
    ),
    IntegrationModel(
      id: 'azure',
      name: 'Azure',
      description: 'Resource spend & quota tracking',
      icon: Icons.cloud_circle_outlined,
      category: IntegrationCategory.cloudPlatforms,
      connected: false,
    ),
    IntegrationModel(
      id: 'github',
      name: 'GitHub',
      description: 'Actions minutes & Copilot seats',
      icon: Icons.code_rounded,
      category: IntegrationCategory.developerTools,
      connected: true,
      lastSynced: '1 hour ago',
      connectionStrength: 0.75,
    ),
    IntegrationModel(
      id: 'gitlab',
      name: 'GitLab',
      description: 'CI/CD pipeline cost tracking',
      icon: Icons.merge_type_rounded,
      category: IntegrationCategory.developerTools,
      connected: false,
    ),
    IntegrationModel(
      id: 'slack',
      name: 'Slack',
      description: 'Budget alerts & approval pings',
      icon: Icons.tag_rounded,
      category: IntegrationCategory.communication,
      connected: true,
      lastSynced: 'Just now',
      connectionStrength: 0.95,
    ),
    IntegrationModel(
      id: 'teams',
      name: 'Microsoft Teams',
      description: 'Notifications & approval routing',
      icon: Icons.groups_2_outlined,
      category: IntegrationCategory.communication,
      connected: false,
    ),
    IntegrationModel(
      id: 'notion',
      name: 'Notion',
      description: 'Report exports & documentation',
      icon: Icons.description_outlined,
      category: IntegrationCategory.productivity,
      connected: false,
    ),
    IntegrationModel(
      id: 'jira',
      name: 'Jira',
      description: 'Project spend attribution',
      icon: Icons.view_kanban_outlined,
      category: IntegrationCategory.productivity,
      connected: true,
      lastSynced: '30 minutes ago',
      connectionStrength: 0.65,
    ),
    IntegrationModel(
      id: 'quickbooks',
      name: 'QuickBooks',
      description: 'Ledger sync & invoice matching',
      icon: Icons.receipt_long_outlined,
      category: IntegrationCategory.finance,
      connected: false,
    ),
    IntegrationModel(
      id: 'netsuite',
      name: 'NetSuite',
      description: 'ERP spend reconciliation',
      icon: Icons.account_tree_outlined,
      category: IntegrationCategory.finance,
      connected: false,
    ),
  ];

  // id -> in-flight connect animation state
  final Set<String> _connecting = {};
  final Set<String> _justConnected = {};

  @override
  void initState() {
    super.initState();
    _ambientController =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  List<IntegrationModel> get _filtered =>
      _integrations.where((i) => i.category == _selectedCategory).toList();

  int get _connectedCount => _integrations.where((i) => i.connected).length;

  Future<void> _toggleConnection(IntegrationModel model) async {
    if (model.connected) {
      setState(() => model.connected = false);
      return;
    }

    setState(() => _connecting.add(model.id));

    // Simulated handshake — replace with real API call via cubit.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    setState(() {
      _connecting.remove(model.id);
      model.connected = true;
      model.lastSynced = 'Just now';
      model.connectionStrength = 0.8;
      _justConnected.add(model.id);
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _justConnected.remove(model.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RRColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _RRColors.surface.withValues(alpha: 0.85),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: const BackButton(color: _RRColors.ink),
            title: const Text(
              'Integrations',
              style: TextStyle(
                color: _RRColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
          ),
          SliverToBoxAdapter(
            child: _CoreVisualization(
              controller: _ambientController,
              connectedCount: _connectedCount,
              totalCount: _integrations.length,
            ),
          ),
          SliverToBoxAdapter(
            child: _CategoryRail(
              selected: _selectedCategory,
              onSelect: (c) => setState(() => _selectedCategory = c),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final model = _filtered[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + index * 60),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 16),
                      child: child,
                    ),
                  ),
                  child: _IntegrationCard(
                    model: model,
                    connecting: _connecting.contains(model.id),
                    justConnected: _justConnected.contains(model.id),
                    onTap: () => _toggleConnection(model),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top visualization — Runrate Core → Connected Services
// ---------------------------------------------------------------------------

class _CoreVisualization extends StatelessWidget {
  final AnimationController controller;
  final int connectedCount;
  final int totalCount;

  const _CoreVisualization({
    required this.controller,
    required this.connectedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      height: 220,
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
            offset: const Offset(0, 12),
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
                painter: _CoreNetworkPainter(progress: controller.value),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 14,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _RRColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$connectedCount of $totalCount live',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            right: 16,
            child: Text(
              'Runrate Core is streaming live spend signals across your\nconnected AI infrastructure.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoreNetworkPainter extends CustomPainter {
  final double progress; // 0..1 looping
  _CoreNetworkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    const nodeCount = 6;
    final radius = min(size.width, size.height) * 0.32;

    // Faint grid backdrop.
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final nodePositions = <Offset>[];
    for (int i = 0; i < nodeCount; i++) {
      final angle = (2 * pi / nodeCount) * i - pi / 2;
      nodePositions.add(
        center + Offset(cos(angle) * radius, sin(angle) * radius * 0.7),
      );
    }

    // Connection lines from core to each node.
    final linePaint = Paint()
      ..color = _RRColors.secondary.withOpacity(0.35)
      ..strokeWidth = 1.4;
    for (final p in nodePositions) {
      canvas.drawLine(center, p, linePaint);
    }

    // Animated data particles traveling core -> node.
    final particlePaint = Paint()..color = Colors.white;
    for (int i = 0; i < nodePositions.length; i++) {
      final t = (progress + i / nodePositions.length) % 1.0;
      final pos = Offset.lerp(center, nodePositions[i], t)!;
      final glow = Paint()
        ..color = _RRColors.primary.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, 4, glow);
      canvas.drawCircle(pos, 2, particlePaint);
    }

    // Outer nodes.
    for (final p in nodePositions) {
      final ringPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(p, 9, ringPaint);
      canvas.drawCircle(
        p,
        4,
        Paint()..color = _RRColors.secondary.withOpacity(0.9),
      );
    }

    // Pulsing core node.
    final pulse = 0.5 + 0.5 * sin(progress * 2 * pi);
    canvas.drawCircle(
      center,
      22 + pulse * 4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _RRColors.primary.withOpacity(0.35 * pulse + 0.1),
            _RRColors.primary.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 26)),
    );
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..shader = const LinearGradient(
          colors: [_RRColors.primary, _RRColors.secondary],
        ).createShader(Rect.fromCircle(center: center, radius: 12)),
    );
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _CoreNetworkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Category rail
// ---------------------------------------------------------------------------

class _CategoryRail extends StatelessWidget {
  final IntegrationCategory selected;
  final ValueChanged<IntegrationCategory> onSelect;

  const _CategoryRail({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: IntegrationCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = IntegrationCategory.values[i];
          final isSelected = category == selected;
          return GestureDetector(
            onTap: () => onSelect(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_RRColors.primary, _RRColors.secondary])
                    : null,
                color: isSelected ? null : Colors.white,
                border: Border.all(
                  color:
                      isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _RRColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected ? Colors.white : _RRColors.mutedInk,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _RRColors.ink,
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

// ---------------------------------------------------------------------------
// Integration card
// ---------------------------------------------------------------------------

class _IntegrationCard extends StatefulWidget {
  final IntegrationModel model;
  final bool connecting;
  final bool justConnected;
  final VoidCallback onTap;

  const _IntegrationCard({
    required this.model,
    required this.connecting,
    required this.justConnected,
    required this.onTap,
  });

  @override
  State<_IntegrationCard> createState() => _IntegrationCardState();
}

class _IntegrationCardState extends State<_IntegrationCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _streamController;
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _streamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(covariant _IntegrationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.justConnected && !oldWidget.justConnected) {
      _successController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _streamController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.75),
                _RRColors.glassTint.withOpacity(0.55),
              ],
            ),
            border: Border.all(
              color: model.connected
                  ? _RRColors.primary.withOpacity(0.35)
                  : Colors.white.withOpacity(0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: model.connected
                    ? _RRColors.primary.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconWithPulse(model),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            model.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _RRColors.ink,
                            ),
                          ),
                        ),
                        _buildStatusChip(model),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      model.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _RRColors.mutedInk,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: _RRColors.mutedInk.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          model.connected
                              ? 'Synced ${model.lastSynced}'
                              : 'Not connected',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _RRColors.mutedInk.withOpacity(0.9),
                          ),
                        ),
                        const Spacer(),
                        _buildActionButton(model),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconWithPulse(IntegrationModel model) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (model.connected)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final v = _pulseController.value;
                return Container(
                  width: 52 + v * 14,
                  height: 52 + v * 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _RRColors.primary
                        .withOpacity((1 - v) * 0.18 * model.connectionStrength),
                  ),
                );
              },
            ),
          if (widget.connecting)
            AnimatedBuilder(
              animation: _streamController,
              builder: (context, _) => CustomPaint(
                size: const Size(52, 52),
                painter:
                    _ConnectingRingPainter(progress: _streamController.value),
              ),
            ),
          if (widget.justConnected)
            AnimatedBuilder(
              animation: _successController,
              builder: (context, _) => CustomPaint(
                size: const Size(56, 56),
                painter:
                    _SuccessRingPainter(progress: _successController.value),
              ),
            ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: model.connected
                  ? const LinearGradient(
                      colors: [_RRColors.primary, _RRColors.secondary])
                  : null,
              color: model.connected ? null : Colors.white,
              border: Border.all(
                color: model.connected
                    ? Colors.transparent
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Icon(
              model.icon,
              size: 20,
              color: model.connected ? Colors.white : _RRColors.mutedInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IntegrationModel model) {
    final connected = model.connected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: connected
            ? _RRColors.success.withOpacity(0.12)
            : _RRColors.mutedInk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? _RRColors.success : _RRColors.mutedInk,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            connected ? 'Connected' : 'Not connected',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: connected ? const Color(0xFF166534) : _RRColors.mutedInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IntegrationModel model) {
    if (widget.connecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _RRColors.primary.withOpacity(0.1),
        ),
        child: const SizedBox(
          width: 60,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_RRColors.primary),
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Linking',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _RRColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: model.connected
              ? null
              : const LinearGradient(
                  colors: [_RRColors.primary, _RRColors.secondary]),
          color: model.connected ? Colors.white : null,
          border: model.connected
              ? Border.all(color: const Color(0xFFE5E7EB))
              : null,
          boxShadow: model.connected
              ? []
              : [
                  BoxShadow(
                    color: _RRColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          model.connected ? 'Manage' : 'Connect',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: model.connected ? _RRColors.ink : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Rotating dashed ring + traveling dot shown while a connection handshake
/// (the "data-stream" effect) is in progress.
class _ConnectingRingPainter extends CustomPainter {
  final double progress;
  _ConnectingRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;

    final basePaint = Paint()
      ..color = _RRColors.secondary.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, basePaint);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: pi * 1.4,
        colors: [
          _RRColors.primary.withOpacity(0),
          _RRColors.primary,
        ],
        transform: GradientRotation(progress * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * 2 * pi,
      pi * 1.2,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConnectingRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Smooth circular "completion" sweep shown right after a successful
/// connection — draws a ring that closes fully then fades.
class _SuccessRingPainter extends CustomPainter {
  final double progress; // 0..1
  _SuccessRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    final sweep =
        Curves.easeOutCubic.transform(min(progress * 1.4, 1)) * 2 * pi;
    final fade = progress > 0.7 ? (1 - (progress - 0.7) / 0.3) : 1.0;

    final paint = Paint()
      ..color = _RRColors.success.withOpacity(fade.clamp(0, 1).toDouble())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SuccessRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

typedef EmIntegrationsScreen = IntegrationsScreen;
