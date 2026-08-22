import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_colors_data.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import '../em_shared_widget.dart';
import 'package:runrate/shared/widgets/scale_on_tap.dart';
import 'package:runrate/shared/widgets/staggered.dart';

class _ToolUsage {
  const _ToolUsage({
    required this.name,
    required this.icon,
    required this.activeUsers,
    required this.monthlySpend,
    required this.trendPercent,
    required this.unusedSeats,
  });

  final String name;
  final IconData icon;
  final int activeUsers;
  final double monthlySpend;
  final double trendPercent;
  final int unusedSeats;
}

class _MemberAdoption {
  const _MemberAdoption(this.name, this.initials, this.adoptionPercent);
  final String name;
  final String initials;
  final double adoptionPercent;
}

/// More → AI Activity & Usage (Premium / Futuristic rebuild)
///
/// Keeps `EmGradientHero`, `ScaleOnTap`, `RupeeAmount` from
/// `em_shared_widget.dart`. The two data cards and the underused-license
/// callout are rebuilt local to this file with the glass / neon-accent
/// treatment used on Notifications, Budget & Forecast, and Team Reports.
///

/// the build spec, this must reuse the same "Top AI Tools" data source
/// already built for EM Home/Teams so figures never drift out of sync.
/// Tool cards and member rows below are wired to navigate to a detail
/// screen only if you already have `ToolDetailScreen` /
/// `EmployeeDetailScreen` — for now they show a snackbar so nothing is
/// a silently-dead tap; swap in the real `Navigator.push` once you
/// confirm those screens' constructors.
class AiActivityUsageScreen extends StatefulWidget {
  const AiActivityUsageScreen({super.key});

  @override
  State<AiActivityUsageScreen> createState() => _AiActivityUsageScreenState();
}

class _AiActivityUsageScreenState extends State<AiActivityUsageScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  static const _blockCount = 4;

  final int _activeUsers = 34;
  final int _totalUsers = 42;
  final double _monthOverMonthChange = 6.5;

  final List<_ToolUsage> _tools = const [
    _ToolUsage(
        name: 'ChatGPT',
        icon: Icons.chat_bubble_rounded,
        activeUsers: 28,
        monthlySpend: 41000,
        trendPercent: 4.2,
        unusedSeats: 3),
    _ToolUsage(
        name: 'Claude',
        icon: Icons.auto_awesome_rounded,
        activeUsers: 22,
        monthlySpend: 48000,
        trendPercent: 9.1,
        unusedSeats: 0),
    _ToolUsage(
        name: 'Gemini',
        icon: Icons.diamond_rounded,
        activeUsers: 11,
        monthlySpend: 19000,
        trendPercent: -2.4,
        unusedSeats: 5),
    _ToolUsage(
        name: 'GitHub Copilot',
        icon: Icons.code_rounded,
        activeUsers: 34,
        monthlySpend: 62000,
        trendPercent: 1.8,
        unusedSeats: 2),
  ];

  final List<_MemberAdoption> _members = const [
    _MemberAdoption('Arjun Mehta', 'AM', 96),
    _MemberAdoption('Sneha Rao', 'SR', 91),
    _MemberAdoption('Kabir Singh', 'KS', 88),
    _MemberAdoption('Divya Iyer', 'DI', 22),
    _MemberAdoption('Rohan Das', 'RD', 18),
  ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    WidgetsBinding.instance.addPostFrameCallback((_) => _entrance.forward());
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _openToolDetail(_ToolUsage tool) {
   
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tool.name} detail view coming soon.')),
    );
  }

  void _openMemberDetail(_MemberAdoption member) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${member.name}\'s detail view coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adoptionPercent = (_activeUsers / _totalUsers * 100);
    final sortedByAdoption = [..._members]
      ..sort((a, b) => b.adoptionPercent.compareTo(a.adoptionPercent));
    final mostActive = sortedByAdoption.take(3).toList();
    final leastActive = sortedByAdoption.reversed.take(2).toList();
    final underused = _tools.where((t) => t.unusedSeats > 0).toList();

    return EmScreenScaffold(
      title: 'AI Activity & Usage',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredFade(
            index: 0,
            total: _blockCount,
            controller: _entrance,
            child: _AdoptionHero(
              adoptionPercent: adoptionPercent,
              activeUsers: _activeUsers,
              totalUsers: _totalUsers,
              activeTools: _tools.length,
              momChange: _monthOverMonthChange,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 1,
            total: _blockCount,
            controller: _entrance,
            child: _ToolUsageCard(tools: _tools, onTap: _openToolDetail),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 2,
            total: _blockCount,
            controller: _entrance,
            child: _MemberAdoptionCard(
              mostActive: mostActive,
              leastActive: leastActive,
              onTap: _openMemberDetail,
            ),
          ),
          if (underused.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            StaggeredFade(
              index: 3,
              total: _blockCount,
              controller: _entrance,
              child: _UnderusedLicenseCallout(tools: underused),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Hero — unchanged shared widget
// ─────────────────────────────────────────────────────────────────────────

class _AdoptionHero extends StatelessWidget {
  const _AdoptionHero({
    required this.adoptionPercent,
    required this.activeUsers,
    required this.totalUsers,
    required this.activeTools,
    required this.momChange,
  });

  final double adoptionPercent;
  final int activeUsers;
  final int totalUsers;
  final int activeTools;
  final double momChange;

  @override
  Widget build(BuildContext context) {
    final isUp = momChange >= 0;
    return EmGradientHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${adoptionPercent.toStringAsFixed(0)}%',
                  style: AppTypography.h1(Colors.white)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(isUp ? Icons.trending_up : Icons.trending_down,
                        size: 16, color: Colors.white),
                    Text(
                      '${momChange.abs().toStringAsFixed(1)}% MoM',
                      style: AppTypography.caption(
                          Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text('team AI adoption',
              style:
                  AppTypography.caption(Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _HeroStatText(
                  label: 'Active users', value: '$activeUsers / $totalUsers'),
              _HeroStatText(label: 'Active tools', value: '$activeTools'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatText extends StatelessWidget {
  const _HeroStatText({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppTypography.caption(Colors.white.withValues(alpha: 0.8))),
          Text(value,
              style: AppTypography.bodyLarge(Colors.white)
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared glass-card shell, matching Notifications / Budget / Reports
// ─────────────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.colors,
    required this.title,
    required this.accent,
    required this.child,
  });

  final AppColorsData colors;
  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.7),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.textPrimary.withValues(alpha: 0.05),
                colors.textPrimary.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(color: colors.textSecondary.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tool usage — gradient icon badge + glowing trend pill per row
// ─────────────────────────────────────────────────────────────────────────

class _ToolUsageCard extends StatelessWidget {
  const _ToolUsageCard({required this.tools, required this.onTap});
  final List<_ToolUsage> tools;
  final void Function(_ToolUsage) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _GlassCard(
      colors: colors,
      title: 'Tool usage',
      accent: colors.primary,
      child: Column(
        children: [
          for (var i = 0; i < tools.length; i++) ...[
            _ToolUsageRow(
                tool: tools[i], colors: colors, onTap: () => onTap(tools[i])),
            if (i != tools.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Divider(
                  height: 1,
                  color: colors.textSecondary.withValues(alpha: 0.08),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ToolUsageRow extends StatelessWidget {
  const _ToolUsageRow(
      {required this.tool, required this.colors, required this.onTap});
  final _ToolUsage tool;
  final AppColorsData colors;
  final VoidCallback onTap;

  static const _palette = [
    Color(0xFF7C6CF6),
    Color(0xFF37C6D9),
    Color(0xFFF2A93B),
    Color(0xFF54D18B),
  ];

  Color get _accent => _palette[tool.name.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) {
    final up = tool.trendPercent >= 0;
    final trendColor = up ? colors.success : colors.danger;

    return ScaleOnTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accent.withValues(alpha: 0.30),
                    _accent.withValues(alpha: 0.10)
                  ],
                ),
                border: Border.all(color: _accent.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.25),
                    blurRadius: 9,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Icon(tool.icon, size: 18, color: _accent),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                  Text('${tool.activeUsers} active users',
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 11.5)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RupeeAmount(
                    amount: tool.monthlySpend,
                    compact: true,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        up
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 10,
                        color: trendColor,
                      ),
                      Text(
                        '${tool.trendPercent.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: colors.textSecondary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Member adoption — gradient avatar ring colored by adoption tier
// ─────────────────────────────────────────────────────────────────────────

class _MemberAdoptionCard extends StatelessWidget {
  const _MemberAdoptionCard({
    required this.mostActive,
    required this.leastActive,
    required this.onTap,
  });

  final List<_MemberAdoption> mostActive;
  final List<_MemberAdoption> leastActive;
  final void Function(_MemberAdoption) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _GlassCard(
      colors: colors,
      title: 'Team adoption',
      accent: colors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 15, color: colors.success),
              const SizedBox(width: 6),
              Text('Most active',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          for (final member in mostActive)
            _MemberRow(
                member: member, colors: colors, onTap: () => onTap(member)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  size: 15, color: colors.warning),
              const SizedBox(width: 6),
              Text('Needs a nudge',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          for (final member in leastActive)
            _MemberRow(
                member: member, colors: colors, onTap: () => onTap(member)),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow(
      {required this.member, required this.colors, required this.onTap});
  final _MemberAdoption member;
  final AppColorsData colors;
  final VoidCallback onTap;

  Color get _tierColor {
    if (member.adoptionPercent >= 70) return colors.success;
    if (member.adoptionPercent >= 40) return colors.warning;
    return colors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tierColor;
    return ScaleOnTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tier.withValues(alpha: 0.32), tier.withValues(alpha: 0.12)],
                ),
                border: Border.all(color: tier.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(
                    color: tier.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Text(
                member.initials,
                style: TextStyle(
                  color: tier,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 4,
                      color: colors.textSecondary.withValues(alpha: 0.08),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (member.adoptionPercent / 100).clamp(0, 1),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [tier, tier.withValues(alpha: 0.6)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('${member.adoptionPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: tier,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Underused license callout — warning-tinted glass
// ─────────────────────────────────────────────────────────────────────────

class _UnderusedLicenseCallout extends StatelessWidget {
  const _UnderusedLicenseCallout({required this.tools});
  final List<_ToolUsage> tools;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final totalUnused = tools.fold<int>(0, (sum, t) => sum + t.unusedSeats);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.warning.withValues(alpha: 0.14),
            colors.warning.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colors.warning.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.warning.withValues(alpha: 0.18),
                  boxShadow: [
                    BoxShadow(
                      color: colors.warning.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Icon(Icons.key_off_rounded,
                    size: 17, color: colors.warning),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('$totalUnused unused seats found',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final tool in tools)
            Padding(
              padding: const EdgeInsets.only(bottom: 5, left: 2),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.warning.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tool.name} — ${tool.unusedSeats} seat${tool.unusedSeats == 1 ? '' : 's'} unused this month',
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 12.5),
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
