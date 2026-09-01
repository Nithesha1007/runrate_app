import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/cfo/more/ai_finance_wallet/ai_finance_wallet_screen.dart';
import 'package:runrate/features/roles/cfo/more/cfo_notifications_screen/cfo_notifications_screen.dart';
import 'package:runrate/features/roles/cfo/more/cfo_settings_screen/cfo_settings_screen.dart';
import 'cfo_more_cubit.dart';

/// CFO · More
/// Organization, Insights, Preferences, Support, Log Out —
/// wired to [CfoMoreCubit].
class CfoMoreScreen extends StatelessWidget {
  const CfoMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CfoMoreCubit(),
      child: const _CfoMoreView(),
    );
  }
}

/// ---------------------------------------------------------------------
/// Palette — gradient hero + outlined-card language shared across the
/// CFO surface (Approvals, Teams, More).
/// ---------------------------------------------------------------------
class _Palette {
  static const bg = Color(0xFFF7F6FB);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFEDEBF4);
  static const gradientStart = Color(0xFF6C5CE7);
  static const gradientEnd = Color(0xFF4C6FEF);
  static const iconTileBg = Color(0xFFEDE9FC);
  static const iconPurple = Color(0xFF6C4FF0);
  static const titleDark = Color(0xFF1E1B2E);
  static const subtitleGray = Color(0xFF8B8798);
  static const chipText = Color(0xFF6C4FF0);
  static const badgeNewBg = Color(0xFFFBDDD3);
  static const badgeNewText = Color(0xFFE4572E);
  static const badgeCountBg = Color(0xFFD32F2F);
  static const logoutBg = Color(0xFFFBE0DE);
  static const logoutText = Color(0xFFE4453A);
}

class _CfoMoreView extends StatelessWidget {
  const _CfoMoreView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<CfoMoreCubit, CfoMoreState>(
          listener: (context, state) {
            if (state is CfoMoreLoggedOut) {
              // TODO: replace with real navigation to the login/auth flow.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out.')),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                const _TopBar(),
                Expanded(child: _buildBody(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CfoMoreState state) {
    if (state is CfoMoreLoading || state is CfoMoreInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CfoMoreError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<CfoMoreCubit>().load(),
      );
    }

    if (state is CfoMoreLoggedOut) {
      return const Center(child: Text('You have been logged out.'));
    }

    final loaded = state as CfoMoreLoaded;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _ProfileHero(profile: loaded.profile),
        const SizedBox(height: 24),

        const _SectionLabel('Wallet'),
        _SectionCard(
          children: [
            _MoreListTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet',
              subtitle: loaded.walletBalance,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AiFinanceWalletScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        const _SectionLabel('Organization'),
        _SectionCard(
          children: [
            _MoreListTile(
              icon: Icons.groups_outlined,
              title: 'Departments',
              subtitle: 'Manage ${loaded.departmentsManaged} departments',
              onTap: () {
                // TODO: navigate to departments.
              },
            ),
            const _TileDivider(),
            _MoreListTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Global AI Budget',
              subtitle: loaded.aiBudgetAllocation,
              onTap: () {
                // TODO: navigate to global AI budget.
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        const _SectionLabel('Insights'),
        _SectionCard(
          children: [
            _MoreListTile(
              icon: Icons.bar_chart_outlined,
              title: 'Executive Reports',
              subtitle: 'ROI, spend velocity & audit logs',
              onTap: () {
                // TODO: navigate to executive reports.
              },
            ),
            const _TileDivider(),
            _MoreListTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Savings Insights',
              trailingBadge: _NewPill(count: loaded.savingsInsightsNewCount),
              onTap: () {
                // TODO: navigate to savings insights.
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        const _SectionLabel('Preferences'),
        _SectionCard(
          children: [
            _MoreListTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CfoSettingsScreen()),
                );
              },
            ),
            const _TileDivider(),
            _MoreListTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              trailingBadge: _CountBadge(count: loaded.notificationsCount),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CfoNotificationsScreen()),
                );
              },
            ),
            const _TileDivider(),
            _MoreListTile(
              icon: Icons.shield_outlined,
              title: 'Security & Compliance',
              subtitle: 'Audit logs & SSO',
              onTap: () {
                // TODO: navigate to security & compliance.
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        const _SectionLabel('Support'),
        _SectionCard(
          children: [
            _MoreListTile(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {
                // TODO: navigate to help center.
              },
            ),
            const _TileDivider(),
            _MoreListTile(
              icon: Icons.info_outline,
              title: 'About Runrate',
              subtitle: loaded.appVersion,
              onTap: () {
                // TODO: navigate to about.
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        _LogOutButton(
          isBusy: loaded.isLoggingOut,
          onTap: loaded.isLoggingOut ? null : () => _confirmLogOut(context),
        ),
      ],
    );
  }

  Future<void> _confirmLogOut(BuildContext context) async {
    final cubit = context.read<CfoMoreCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Log out?'),
          content: const Text('You\'ll need to sign in again to access the dashboard.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _Palette.gradientStart,
                shape: const StadiumBorder(),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      cubit.logOut();
    }
  }
}

/// ---------------------------------------------------------------------
/// Top bar — "More" heading + subtitle
/// ---------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Profile, preferences & settings',
            style: TextStyle(fontSize: 14, color: _Palette.subtitleGray, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Gradient profile hero card
/// ---------------------------------------------------------------------
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final CfoProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_Palette.gradientStart, _Palette.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _Palette.gradientEnd.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _Palette.gradientEnd.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 12, color: _Palette.gradientStart),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _HeroChip(label: profile.roleLabel),
                    const SizedBox(width: 8),
                    Flexible(child: _HeroChip(label: profile.department)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(100)),
            child: TextButton(
              onPressed: () {
                // TODO: navigate to edit profile.
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Shared building blocks
/// ---------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 0, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _Palette.titleDark,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _Palette.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.cardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
    );
  }
}

class _MoreListTile extends StatelessWidget {
  const _MoreListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingBadge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailingBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _Palette.iconTileBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _Palette.iconPurple, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _Palette.titleDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 12.5, color: _Palette.subtitleGray),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              trailingBadge!,
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}

class _NewPill extends StatelessWidget {
  const _NewPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _Palette.badgeNewBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count new',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _Palette.badgeNewText,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _Palette.badgeCountBg,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.isBusy, required this.onTap});

  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _Palette.logoutBg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _Palette.logoutText),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, color: _Palette.logoutText, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _Palette.logoutText,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Error state
/// ---------------------------------------------------------------------
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _Palette.subtitleGray)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_Palette.gradientStart, _Palette.gradientEnd]),
                borderRadius: BorderRadius.circular(100),
              ),
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}