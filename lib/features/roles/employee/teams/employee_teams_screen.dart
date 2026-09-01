import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

import 'employee_teams_cubit.dart';

// Status badge colors
const _onTrackBg = Color(0xFFDCFCE7);
const _onTrackFg = Color(0xFF15803D);
const _needsAttentionBg = Color(0xFFFDECD1);
const _needsAttentionFg = Color(0xFFB4740E);

// Gradient colors for hero card
const _gradientStart = Color(0xFF6C5CE7);
const _gradientEnd = Color(0xFF4C6EF5);

TextStyle appFontStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

final _currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '\u20b9',
  decimalDigits: 0,
);

const _kAvatarPalette = <Color>[
  Color(0xFFE5484D),
  Color(0xFF3B82F6),
  Color(0xFF9333EA),
  Color(0xFFF29A2E),
  Color(0xFF17A673),
  Color(0xFFD6409F),
];

Color _avatarColorFor(String name) {
  final index = name.codeUnits.fold<int>(0, (a, b) => a + b) % _kAvatarPalette.length;
  return _kAvatarPalette[index];
}

/// Which members are visible in the roster below.
enum _MemberFilter { all, highAdoption, needsAttention }

/// Employee · Teams ("My Team")
///
/// Read-only view of the single team the employee belongs to: overall
/// health (on-track %, adoption, velocity, open PRs) and the member
/// roster with each person's status and AI tool usage. Employees only
/// ever see their own team here — there is no way to browse into other
/// teams; that visibility belongs to managers/CFO views, not this screen.
class EmployeeTeamsScreen extends StatelessWidget {
  const EmployeeTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeTeamsCubit(),
      child: const _EmployeeTeamsView(),
    );
  }
}

class _EmployeeTeamsView extends StatefulWidget {
  const _EmployeeTeamsView();

  @override
  State<_EmployeeTeamsView> createState() => _EmployeeTeamsViewState();
}

class _EmployeeTeamsViewState extends State<_EmployeeTeamsView> {
  _MemberFilter _filter = _MemberFilter.all;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeamMemberSummary> _visible(List<TeamMemberSummary> all) {
    Iterable<TeamMemberSummary> result = all;
    switch (_filter) {
      case _MemberFilter.all:
        break;
      case _MemberFilter.highAdoption:
        result = result.where((m) => m.highAdoption);
        break;
      case _MemberFilter.needsAttention:
        result = result.where((m) => m.status == MemberStatus.needsAttention);
        break;
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where(
        (m) => m.name.toLowerCase().contains(q) || m.role.toLowerCase().contains(q),
      );
    }
    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: BlocBuilder<EmployeeTeamsCubit, EmployeeTeamsState>(
          builder: (context, state) {
            if (state.isLoading && !state.hasTeam) {
              return Center(
                child: CircularProgressIndicator(color: context.appColors.primary),
              );
            }
            if (state.hasError && !state.hasTeam) {
              return EmptyState(
                title: 'Something went wrong',
                message: state.errorMessage ?? 'Please try again.',
                icon: Icons.error_outline,
              );
            }
            if (!state.hasTeam) {
              return const EmptyState(
                title: 'No team yet',
                message: 'Your team will show up here once you\'re assigned one.',
                icon: Icons.groups_outlined,
              );
            }

            final team = state.team!;
            final visible = _visible(team.members);

            return RefreshIndicator(
              color: context.appColors.primary,
              onRefresh: () => context.read<EmployeeTeamsCubit>().loadMyTeam(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                children: [
                  _TeamsHeader(teamTagline: team.tagline),
                  const SizedBox(height: AppSpacing.md),
                  _HeroSummaryCard(team: team),
                  const SizedBox(height: AppSpacing.md),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MemberFilterRow(
                    selected: _filter,
                    allCount: team.memberCount,
                    highAdoptionCount: team.highAdoptionCount,
                    needsAttentionCount: team.needsAttentionCount,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            _query.isEmpty
                                ? 'No teammates match this filter.'
                                : 'No teammates match "$_query".',
                            textAlign: TextAlign.center,
                            style: appFontStyle(color: context.appColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    for (var i = 0; i < visible.length; i++) ...[
                      _MemberCard(member: visible[i]),
                      if (i != visible.length - 1) const SizedBox(height: AppSpacing.sm),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Header — title, tagline, close/back affordance
/// ---------------------------------------------------------------------

class _TeamsHeader extends StatelessWidget {
  const _TeamsHeader({required this.teamTagline});

  final String teamTagline;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Team', style: appFontStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const SizedBox(height: 2),
              Text(
                teamTagline,
                style: appFontStyle(fontSize: 13.5, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(Icons.close_rounded, color: colors.textPrimary, size: 20),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Gradient hero — on-track ring, member/spend lines, 3-up stat tiles
/// ---------------------------------------------------------------------

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({required this.team});

  final MyTeamDetail team;

  @override
  Widget build(BuildContext context) {
    final ringPercent = team.onTrackPercent.clamp(0, 100) / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _gradientEnd.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: ringPercent.toDouble(),
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withOpacity(0.22),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    Text(
                      '${team.onTrackPercent}%',
                      style: appFontStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${team.onTrackPercent}% on track',
                      style: appFontStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.people_alt_rounded, size: 15, color: Colors.white.withOpacity(0.85)),
                        const SizedBox(width: 5),
                        Text(
                          '${team.memberCount} members',
                          style: appFontStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.currency_rupee_rounded, size: 14, color: Colors.white.withOpacity(0.85)),
                        Text(
                          '${team.monthlySpend.toStringAsFixed(0)}/mo spend',
                          style: appFontStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroStatTile(value: '${team.adoptionPercent}%', label: 'Adoption'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStatTile(value: '${team.velocityPercent}%', label: 'Velocity'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStatTile(value: '${team.openPrsCount}', label: 'Open PRs'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: appFontStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: appFontStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Search field
/// ---------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: appFontStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search by name or role',
          hintStyle: appFontStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Filter chips — All / High adoption / Needs attention
/// ---------------------------------------------------------------------

class _MemberFilterRow extends StatelessWidget {
  const _MemberFilterRow({
    required this.selected,
    required this.allCount,
    required this.highAdoptionCount,
    required this.needsAttentionCount,
    required this.onSelected,
  });

  final _MemberFilter selected;
  final int allCount;
  final int highAdoptionCount;
  final int needsAttentionCount;
  final ValueChanged<_MemberFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterPill(
            label: 'All',
            count: allCount,
            selected: selected == _MemberFilter.all,
            onTap: () => onSelected(_MemberFilter.all),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterPill(
            label: 'High adoption',
            count: highAdoptionCount,
            selected: selected == _MemberFilter.highAdoption,
            onTap: () => onSelected(_MemberFilter.highAdoption),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterPill(
            label: 'Needs attention',
            count: needsAttentionCount,
            selected: selected == _MemberFilter.needsAttention,
            onTap: () => onSelected(_MemberFilter.needsAttention),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: appFontStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : colors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.25) : colors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: appFontStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Member card
/// ---------------------------------------------------------------------

({String label, Color bg, Color fg}) _statusStyle(MemberStatus status) {
  switch (status) {
    case MemberStatus.onTrack:
      return (label: 'On Track', bg: _onTrackBg, fg: _onTrackFg);
    case MemberStatus.needsAttention:
      return (label: 'Needs Attention', bg: _needsAttentionBg, fg: _needsAttentionFg);
  }
}

({IconData icon, Color color, String label})? _toolStyle(AiToolUsed tool) {
  switch (tool) {
    case AiToolUsed.copilot:
      return (icon: Icons.integration_instructions_rounded, color: const Color(0xFF15161A), label: 'GitHub Copilot');
    case AiToolUsed.claude:
      return (icon: Icons.auto_awesome_rounded, color: _gradientStart, label: 'Claude');
    case AiToolUsed.none:
      return null;
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final TeamMemberSummary member;

  String get _initials {
    final parts = member.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final status = _statusStyle(member.status);
    final tool = _toolStyle(member.aiTool);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _avatarColorFor(member.name),
                child: Text(
                  _initials,
                  style: appFontStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: appFontStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      member.role,
                      style: appFontStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: status.bg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  status.label,
                  style: appFontStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: status.fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (tool != null) ...[
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: tool.color, shape: BoxShape.circle),
                  child: Icon(tool.icon, size: 11, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Text(
                  tool.label,
                  style: appFontStyle(fontSize: 12.5, color: colors.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 14),
              ],
              Icon(Icons.bolt_rounded, size: 14, color: colors.primary),
              const SizedBox(width: 3),
              Text(
                '${member.points} pts',
                style: appFontStyle(fontSize: 12.5, color: colors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}