import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import '../em_shared_widget.dart';
import 'package:runrate/shared/widgets/scale_on_tap.dart';
import 'package:runrate/shared/widgets/staggered.dart';

class _ToolUsage {
  const _ToolUsage({
    required this.name,
    required this.activeUsers,
    required this.monthlySpend,
    required this.trendPercent,
    required this.unusedSeats,
  });

  final String name;
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

/// More → AI Activity & Usage
///
/// TODO — IMPORTANT: `_tools` and `_members` are local mock data. Per
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
        activeUsers: 28,
        monthlySpend: 41000,
        trendPercent: 4.2,
        unusedSeats: 3),
    _ToolUsage(
        name: 'Claude',
        activeUsers: 22,
        monthlySpend: 48000,
        trendPercent: 9.1,
        unusedSeats: 0),
    _ToolUsage(
        name: 'Gemini',
        activeUsers: 11,
        monthlySpend: 19000,
        trendPercent: -2.4,
        unusedSeats: 5),
    _ToolUsage(
        name: 'GitHub Copilot',
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
    // TODO: replace with Navigator.push to your real Tool Detail screen.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tool.name} detail view coming soon.')),
    );
  }

  void _openMemberDetail(_MemberAdoption member) {
    // TODO: replace with Navigator.push to your real Employee Detail screen.
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
        ],
      ),
    );
  }
}

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

class _ToolUsageCard extends StatelessWidget {
  const _ToolUsageCard({required this.tools, required this.onTap});
  final List<_ToolUsage> tools;
  final void Function(_ToolUsage) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tool usage', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          for (final tool in tools) ...[
            ScaleOnTap(
              onTap: () => onTap(tool),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tool.name,
                              style:
                                  AppTypography.bodyLarge(colors.textPrimary)),
                          Text('${tool.activeUsers} active users',
                              style:
                                  AppTypography.caption(colors.textSecondary)),
                        ],
                      ),
                    ),
                    RupeeAmount(
                        amount: tool.monthlySpend,
                        compact: true,
                        style: AppTypography.body(colors.textPrimary)),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      tool.trendPercent >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16,
                      color: tool.trendPercent >= 0
                          ? colors.success
                          : colors.danger,
                    ),
                    Icon(Icons.chevron_right,
                        size: 18, color: colors.textSecondary),
                  ],
                ),
              ),
            ),
            if (tool != tools.last)
              Divider(color: colors.border, height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Most active', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          for (final member in mostActive)
            _MemberRow(member: member, onTap: () => onTap(member)),
          const SizedBox(height: AppSpacing.md),
          Text('Needs a nudge', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          for (final member in leastActive)
            _MemberRow(member: member, onTap: () => onTap(member)),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onTap});
  final _MemberAdoption member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ScaleOnTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary.withValues(alpha: 0.15),
              child: Text(member.initials,
                  style: AppTypography.caption(colors.primary)
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(member.name,
                    style: AppTypography.body(colors.textPrimary))),
            Text('${member.adoptionPercent.toStringAsFixed(0)}%',
                style: AppTypography.bodyLarge(colors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

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
        color: colors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_off_outlined, size: 18, color: colors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text('$totalUnused unused seats found',
                  style: AppTypography.h3(colors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final tool in tools)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${tool.name} — ${tool.unusedSeats} seat${tool.unusedSeats == 1 ? '' : 's'} unused this month',
                style: AppTypography.body(colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
