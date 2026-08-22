import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/authentication/presentation/add_workspace.dart';
import 'package:runrate/shared/models/role_enum.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../roles/role_home_shell.dart';

class Organization {
  final String id;
  final String name;
  final String memberLabel;
  final IconData icon;

  const Organization({
    required this.id,
    required this.name,
    required this.memberLabel,
    this.icon = Icons.apartment_rounded,
  });
}

class OrgSelectionScreen extends StatefulWidget {
  const OrgSelectionScreen({super.key});

  @override
  State<OrgSelectionScreen> createState() => _OrgSelectionScreenState();
}

class _OrgSelectionScreenState extends State<OrgSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

 
  final List<Organization> _orgs = const [
    Organization(id: 'org_1', name: 'Acme Corp', memberLabel: '128 members'),
    Organization(id: 'org_2', name: 'Nimbus Labs', memberLabel: '42 members'),
    Organization(
        id: 'org_3', name: 'Vertex Holdings', memberLabel: '9 members'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _staggerFor(int index, int totalCount) {
    final start = (index / (totalCount + 1)).clamp(0.0, 1.0);
    final end = ((index + 2) / (totalCount + 1)).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  void _goToRoleHome(dynamic user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RoleHomeShell(user: user)),
    );
  }

  Future<void> _openAddWorkspace() async {
    final result = await Navigator.of(context).push<Organization>(
      MaterialPageRoute(builder: (_) => const AddWorkspaceScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _orgs.add(result);
        _controller
          ..reset()
          ..forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AuthCubit>().state;
    final user = state is AuthAuthenticated ? state.user : null;

    // total items = orgs + the "Add Workspace" tile
    final totalCount = _orgs.length + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Organization')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose a workspace to continue',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: totalCount,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final animation = _staggerFor(index, totalCount);

                    Widget child;
                    if (index < _orgs.length) {
                      final org = _orgs[index];
                      child = AppCard(
                        onTap: user == null ? null : () => _goToRoleHome(user),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                              child: Icon(org.icon),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    org.name,
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    org.memberLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      );
                    } else {
                      child = _AddWorkspaceTile(onTap: _openAddWorkspace);
                    }

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
              if (user != null) ...[
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Continue as ${user.role.label}',
                  onPressed: () => _goToRoleHome(user),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Distinct, futuristic-looking "Add Workspace" tile with a pulsing
/// plus icon and an animated gradient border, built purely from the
/// existing theme colors (no new hardcoded colors).
class _AddWorkspaceTile extends StatefulWidget {
  final VoidCallback onTap;
  const _AddWorkspaceTile({required this.onTap});

  @override
  State<_AddWorkspaceTile> createState() => _AddWorkspaceTileState();
}

class _AddWorkspaceTileState extends State<_AddWorkspaceTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value; // 0..1
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.05 + 0.03 * t),
                  primary.withValues(alpha: 0.0),
                ],
              ),
              border: Border.all(
                color: primary.withValues(alpha: 0.25 + 0.2 * t),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.0 + 0.08 * t,
                  child: CircleAvatar(
                    backgroundColor: primary.withValues(alpha: 0.12),
                    foregroundColor: primary,
                    child: const Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Workspace',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create a new organization',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: primary),
              ],
            ),
          );
        },
      ),
    );
  }
}
