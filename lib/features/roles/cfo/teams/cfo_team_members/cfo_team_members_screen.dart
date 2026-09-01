import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/features/roles/cfo/teams/cfo_teams_screen.dart';
import 'package:runrate/features/roles/cfo/teams/cfo_teams_state.dart';

import 'cfo_team_members_cubit.dart';
import 'cfo_team_members_state.dart';

// ---------------------------------------------------------------------------
// Palette — same gradient language used across the CFO surface (Approvals,
// Teams) so the app reads as one cohesive, modern system.
// ---------------------------------------------------------------------------
const _kGradientStart = Color(0xFF6C5CE7);
const _kGradientEnd = Color(0xFF4C6FEF);
const _kNeedsAttention = Color(0xFFF5A524);
const _kNeedsAttentionBg = Color(0xFFFCEDD3);
const _kOverloaded = Color(0xFFE5484D);
const _kOverloadedBg = Color(0xFFFBE3E4);
const _kTopPerformer = Color(0xFF17A673);
const _kTopPerformerBg = Color(0xFFDDF4EA);

const _kAvatarPalette = <Color>[
  Color(0xFFE5484D),
  Color(0xFFF29A2E),
  Color(0xFF6C5CE7),
  Color(0xFF17A673),
  Color(0xFF3B82F6),
  Color(0xFFD6409F),
];

/// CFO · Teams · Department Detail · Team Members
/// Full-screen member roster: gradient performance hero, live search,
/// filter chips, and a scannable card list with derived status/AI
/// signals. Pushed from the "View Team Members" button on
/// [CfoDepartmentDetailScreen].
class CfoTeamMembersScreen extends StatelessWidget {
  const CfoTeamMembersScreen({super.key, required this.department});

  final DepartmentRoi department;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CfoTeamMembersCubit(department),
      child: const _CfoTeamMembersView(),
    );
  }
}

class _CfoTeamMembersView extends StatelessWidget {
  const _CfoTeamMembersView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CfoTeamMembersCubit, CfoTeamMembersState>(
          builder: (context, state) {
            if (state is CfoTeamMembersLoading ||
                state is CfoTeamMembersInitial) {
              return Column(
                children: [
                  _Header(title: '', subtitle: '', onBack: () => Navigator.of(context).pop()),
                  const Expanded(
                      child: Center(child: CircularProgressIndicator())),
                ],
              );
            }

            if (state is CfoTeamMembersError) {
              return Column(
                children: [
                  _Header(title: '', subtitle: '', onBack: () => Navigator.of(context).pop()),
                  Expanded(
                    child: _ErrorView(
                      message: state.message,
                      onRetry: () => context.read<CfoTeamMembersCubit>().load(),
                    ),
                  ),
                ],
              );
            }

            final data = (state as CfoTeamMembersLoaded).data;

            return RefreshIndicator(
              onRefresh: () => context.read<CfoTeamMembersCubit>().refresh(),
              child: _MembersBody(
                data: data,
                onBack: () => Navigator.of(context).pop(),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Owns the local search query so filtering the already-fetched
/// [TeamMembersLoaded.visibleMembers] list doesn't require cubit changes.
class _MembersBody extends StatefulWidget {
  const _MembersBody({required this.data, required this.onBack});

  // NOTE: typed as dynamic because the concrete "loaded" data class name
  // isn't defined in the files provided for this screen — swap this for
  // the real type (e.g. TeamMembersData) once wiring it up in the project.
  final dynamic data;
  final VoidCallback onBack;

  @override
  State<_MembersBody> createState() => _MembersBodyState();
}

class _MembersBodyState extends State<_MembersBody> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? data.visibleMembers
        : data.visibleMembers
            .where((m) =>
                m.name.toLowerCase().contains(q) ||
                m.role.toLowerCase().contains(q))
            .toList();

    return Column(
      children: [
        _Header(
          title: data.departmentName,
          subtitle: '${data.totalMemberCount} Members',
          onBack: widget.onBack,
        ),
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
            children: [
              _PerformanceHero(summary: data.summary),
              const SizedBox(height: AppSpacing.lg),
              _SearchField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: AppSpacing.md),
              _FilterTabs(
                selected: data.filterTab,
                resultCount: filtered.length,
                onChanged: (tab) =>
                    context.read<CfoTeamMembersCubit>().setFilterTab(tab),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                _EmptySearchState(query: _searchController.text)
              else
                for (var i = 0; i < filtered.length; i++) ...[
                  _MemberCard(member: filtered[i]),
                  if (i != filtered.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.md),
              if (filtered.isNotEmpty)
                Center(
                  child: Text(
                    'Showing ${filtered.length} of ${data.totalMemberCount} members',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kGradientStart, _kGradientEnd]),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: _kGradientEnd.withOpacity(0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: () => _showAddMemberDialog(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const StadiumBorder(),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_alt_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Invite Team Members', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(width: 12),
                      Icon(Icons.add_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final cubit = context.read<CfoTeamMembersCubit>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddMemberSheet(
        onSubmit: (name, role) => cubit.addMember(name: name, role: role),
      ),
    );
  }
}

/// Bottom sheet used to add a new team member. Pops once the cubit call
/// is made; validation happens inline instead of blocking via a dialog.
class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({required this.onSubmit});

  final void Function(String name, String role) onSubmit;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  String? _nameError;
  String? _roleError;

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final role = _roleController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Name is required' : null;
      _roleError = role.isEmpty ? 'Role is required' : null;
    });
    if (_nameError != null || _roleError != null) return;
    widget.onSubmit(name, role);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const Text(
              'Add Team Member',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Invite a new member to this department',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Text('Name', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter full name',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF6F5FB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            Text('Role', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _roleController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_roleError != null) setState(() => _roleError = null);
              },
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter team role',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF6F5FB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                errorText: _roleError,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kGradientStart, _kGradientEnd]),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
/// Header — back arrow, title + subtitle
/// ---------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, required this.onBack});

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Gradient performance hero — ring + inline metric strip.
/// ---------------------------------------------------------------------

class _PerformanceHero extends StatelessWidget {
  const _PerformanceHero({required this.summary});

  final TeamMembersSummary summary;

  static String _trimZero(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final ringPercent = summary.avgRoiPercent.clamp(0, 100) / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGradientStart, _kGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: _kGradientEnd.withOpacity(0.3), blurRadius: 22, offset: const Offset(0, 12)),
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
                      '${summary.avgRoiPercent.round()}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avg. Team ROI',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.groups_2_rounded, size: 15, color: Colors.white.withOpacity(0.85)),
                        const SizedBox(width: 4),
                        Text(
                          '${summary.totalTasksCompleted > 0 ? '' : ''}Team members',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  value: '${_trimZero(summary.totalTimeSavedHours)}h',
                  label: 'Time Saved',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  value: '${summary.totalTasksCompleted}',
                  label: 'Tasks Done',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  value: formatInrCompact(summary.totalValueGenerated),
                  label: 'Value Gen.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

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
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w600),
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search by name or role',
          hintStyle: TextStyle(color: Colors.grey.shade500),
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
/// Filter chips — All / High adoption / Needs attention, etc.
/// ---------------------------------------------------------------------

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selected,
    required this.resultCount,
    required this.onChanged,
  });

  final MemberFilterTab selected;
  final int resultCount;
  final ValueChanged<MemberFilterTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in MemberFilterTab.values) ...[
            _FilterTabChip(
              label: tab.label,
              isSelected: selected == tab,
              count: selected == tab ? resultCount : null,
              onTap: () => onChanged(tab),
            ),
            if (tab != MemberFilterTab.values.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _FilterTabChip extends StatelessWidget {
  const _FilterTabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool isSelected;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_kGradientStart, _kGradientEnd])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.25) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Member card
/// ---------------------------------------------------------------------

/// Derived status badge, since [TeamMember] doesn't carry an explicit
/// status field. Thresholds are placeholders — swap for a real backend
/// signal whenever one exists.
({String label, Color color, Color bg})? _statusFor(TeamMember member) {
  if (member.roiPercent < 30) {
    return (label: 'Needs Attention', color: _kNeedsAttention, bg: _kNeedsAttentionBg);
  }
  if (member.tasksCompleted >= 20) {
    return (label: 'Overloaded', color: _kOverloaded, bg: _kOverloadedBg);
  }
  if (member.roiPercent >= 70) {
    return (label: 'Top Performer', color: _kTopPerformer, bg: _kTopPerformerBg);
  }
  return null;
}

Color _avatarColorFor(String name) {
  final index = name.codeUnits.fold<int>(0, (a, b) => a + b) % _kAvatarPalette.length;
  return _kAvatarPalette[index];
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final TeamMember member;

  static String _trimZero(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(member);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // TODO: navigate to individual member detail.
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MemberAvatar(name: member.name, url: member.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.role,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: status.bg, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      status.label,
                      style: TextStyle(color: status.color, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MetricChip(
                  icon: Icons.schedule_rounded,
                  label: '${_trimZero(member.timeSavedHours)}h saved',
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  icon: Icons.bolt_rounded,
                  label: '${member.tasksCompleted} tasks',
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 2),
                    Text(
                      '+${member.roiPercent.toStringAsFixed(0)}% ROI',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF6F5FB), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kGradientStart),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.name, this.url});

  final String name;
  final String? url;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(url!));
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: _avatarColorFor(name),
      child: Text(
        _initials,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Empty search state + error state
/// ---------------------------------------------------------------------

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            query.isEmpty ? 'No members in this filter yet.' : 'No members match "$query".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}