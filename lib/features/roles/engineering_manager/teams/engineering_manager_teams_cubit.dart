// ASSUMPTIONS MADE IN THIS FILE (verify / find-replace against your real code):
//   - No Engineering Manager "Home" cubit/repository was supplied, so this file
//     EXTENDS the EngineeringManagerTeamsCubit you uploaded (same class name,
//     same public API: loadTeams / refresh / search / applyFilter) rather than
//     inventing a second, disconnected data source. If Home already sources
//     team data from somewhere else, point that source at this same
//     TeamMember/EngineeringTeamOverview shape and delete the mock fetcher.
//   - ADDITIVE ONLY vs. the version you uploaded: nothing existing was renamed
//     or removed. New fields/enums/classes are appended so any other screen
//     (e.g. Home) that already reads this cubit keeps compiling unchanged.
//   - New team-level fields (teamName, managerName, productivityScore,
//     budgetAllocated, budgetRemaining, pendingApprovalsCount,
//     activeAiToolsCount, healthBreakdown, toolUsage, hasUnreadNotifications)
//     are mocked with numbers derived from the member list so the UI stays
//     internally consistent — swap for real aggregates once the backend
//     provides them.
//   - New member-level fields (productivityScore, capacityPercent,
//     currentTasks, completedTasks, overdueTasks, allocatedBudget) are mocked
//     per-member. `capacityPercent` is an explicit workload % and is
//     deliberately distinct from the existing sprintPointsAssigned/
//     sprintCapacity pair — engagementStatus computation is untouched and
//     still derives only from sprint points / adoption / stale blockers, per
//     spec ("keep MemberEngagementStatus computation logic as-is").

import 'package:flutter_bloc/flutter_bloc.dart';

enum PresenceStatus { active, away, offline }

/// Filters exposed on the Engineering Manager Team screen.
///
/// `presenceActive` / `presenceAway` are ADDITIVE: they let the screen filter
/// by the same PresenceStatus taxonomy the member cards already show
/// ("Active"/"Away"/"Offline"), alongside the pre-existing AI-adoption-based
/// taxonomy (`highAdoption` / `needsAttention` / `blocked`). Both taxonomies
/// stay available side by side, per spec.
enum MemberFilter {
  all,
  highAdoption,
  needsAttention,
  blocked,
  presenceActive,
  presenceAway,
}

/// Computed engagement status per member — drives the status badge color.
enum MemberEngagementStatus { onTrack, needsAttention, overloaded }

/// Team-level health status for the hero card's status pill.
enum TeamHealthStatus { healthy, warning, critical }

/// One AI tool's usage/spend for a given member.
class ToolUsage {
  const ToolUsage({
    required this.toolName,
    required this.adoptionPercent,
    required this.monthlySpend,
  });

  final String toolName;
  final int adoptionPercent;
  final double monthlySpend;
}

/// Team-wide (not per-member) usage/spend for a single AI tool. Backs the
/// new "Top AI Tools" section and the Tool Detail screen.
class TeamToolUsage {
  const TeamToolUsage({
    required this.toolName,
    required this.activeUsers,
    required this.totalUsers,
    required this.monthlySpend,
    required this.trendPercent,
    this.licenseSeats,
    this.unusedLicenseCount = 0,
  });

  final String toolName;
  final int activeUsers;
  final int totalUsers;
  final double monthlySpend;

  /// Positive = usage trending up, negative = trending down.
  final double trendPercent;

  /// Total purchased seats, if different from totalUsers (i.e. some seats
  /// were bought but never assigned). Falls back to totalUsers when null.
  final int? licenseSeats;
  final int unusedLicenseCount;

  int get seats => licenseSeats ?? totalUsers;
  int get adoptionPercent =>
      totalUsers == 0 ? 0 : ((activeUsers / totalUsers) * 100).round();
  double get costPerActiveUser =>
      activeUsers == 0 ? 0 : monthlySpend / activeUsers;
  double get licenseUtilizationPercent =>
      seats == 0 ? 0 : ((seats - unusedLicenseCount) / seats) * 100;
}

/// One named category score (0-100) contributing to overall team health.
class HealthCategoryScore {
  const HealthCategoryScore({required this.name, required this.score});
  final String name;
  final int score;
}

/// A single recent PR / sprint activity entry.
enum ActivityStatus { success, warning, danger }

class ActivityItem {
  const ActivityItem({
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.relativeTime,
  });

  final String title;
  final ActivityStatus status;
  final String statusLabel;
  final String relativeTime;
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.subTeam,
    required this.status,
    required this.lastActiveLabel,
    required this.aiAdoptionPercent,
    required this.monthlyAiSpend,
    required this.primaryTool,
    required this.tools,
    required this.sprintPointsAssigned,
    required this.sprintCapacity,
    required this.prsOpen,
    required this.prsReviewed,
    required this.hasStaleBlockers,
    this.toolBreakdown = const [],
    this.recentActivity = const [],
    this.needsAttention = false,
    this.attentionReason,
    this.joinedLabel,
    this.usageTrendPercent,
    this.usageTrendIsUp,
    // --- additive fields ---
    this.productivityScore = 0,
    this.capacityPercent = 0,
    this.currentTasks = 0,
    this.completedTasks = 0,
    this.overdueTasks = 0,
    this.allocatedBudget = 0,
  });

  final String id;
  final String name;
  final String role;
  final String subTeam;
  final PresenceStatus status;
  final String lastActiveLabel;
  final int aiAdoptionPercent;
  final double monthlyAiSpend;
  final String primaryTool;
  final List<String> tools;

  final int sprintPointsAssigned;
  final int sprintCapacity;
  final int prsOpen;
  final int prsReviewed;
  final bool hasStaleBlockers;
  final List<ToolUsage> toolBreakdown;
  final List<ActivityItem> recentActivity;

  final bool needsAttention;
  final String? attentionReason;
  final String? joinedLabel;
  final double? usageTrendPercent;
  final bool? usageTrendIsUp;

  /// 0-100 productivity score shown on the upgraded member card and in the
  /// Employee Detail "Productivity" block.
  final int productivityScore;

  /// Explicit workload %, distinct from sprintPointsAssigned/sprintCapacity.
  /// Can exceed 100 (over capacity) — the UI colors the bar accordingly.
  final int capacityPercent;

  final int currentTasks;
  final int completedTasks;
  final int overdueTasks;
  final double allocatedBudget;

  /// Centralized status computation — UI should always read this, never
  /// re-derive "on track" logic from raw fields itself. UNCHANGED per spec.
  MemberEngagementStatus get engagementStatus {
    final overCapacity =
        sprintCapacity > 0 && sprintPointsAssigned > sprintCapacity;
    if (overCapacity) return MemberEngagementStatus.overloaded;
    if (aiAdoptionPercent < 50 || hasStaleBlockers) {
      return MemberEngagementStatus.needsAttention;
    }
    return MemberEngagementStatus.onTrack;
  }

  double get sprintLoadRatio => sprintCapacity == 0
      ? 0
      : (sprintPointsAssigned / sprintCapacity).clamp(0, 2).toDouble();

  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return name.toLowerCase().contains(q) ||
        role.toLowerCase().contains(q) ||
        subTeam.toLowerCase().contains(q) ||
        tools.any((t) => t.toLowerCase().contains(q)) ||
        primaryTool.toLowerCase().contains(q);
  }

  bool matchesFilter(MemberFilter filter) {
    switch (filter) {
      case MemberFilter.all:
        return true;
      case MemberFilter.highAdoption:
        return aiAdoptionPercent >= 85;
      case MemberFilter.needsAttention:
        return engagementStatus == MemberEngagementStatus.needsAttention ||
            engagementStatus == MemberEngagementStatus.overloaded;
      case MemberFilter.blocked:
        return hasStaleBlockers;
      case MemberFilter.presenceActive:
        return status == PresenceStatus.active;
      case MemberFilter.presenceAway:
        return status == PresenceStatus.away;
    }
  }
}

/// Team-wide summary used by the gradient hero card.
class EngineeringTeamOverview {
  const EngineeringTeamOverview({
    required this.totalMembers,
    required this.onTrackMembers,
    required this.totalMonthlyAiSpend,
    required this.avgAiAdoptionPercent,
    required this.sprintVelocityPercent,
    required this.openPrCount,
    // --- additive fields ---
    this.teamName = 'Engineering Team',
    this.managerName = 'Manager',
    this.hasUnreadNotifications = false,
    this.productivityScore = 0,
    this.budgetAllocated = 0,
    this.budgetRemaining = 0,
    this.pendingApprovalsCount = 0,
    this.activeAiToolsCount = 0,
    this.healthBreakdown = const [],
    this.toolUsage = const [],
  });

  final int totalMembers;
  final int onTrackMembers;
  final double totalMonthlyAiSpend;
  final int avgAiAdoptionPercent;
  final int sprintVelocityPercent;
  final int openPrCount;

  final String teamName;
  final String managerName;
  final bool hasUnreadNotifications;

  final int productivityScore;
  final double budgetAllocated;
  final double budgetRemaining;
  final int pendingApprovalsCount;
  final int activeAiToolsCount;

  /// Exactly 4 named categories, per spec: Delivery, AI Adoption,
  /// Productivity, Budget.
  final List<HealthCategoryScore> healthBreakdown;

  /// Team-level (not per-member) AI tool usage, backing "Top AI Tools" and
  /// the Tool Detail screen.
  final List<TeamToolUsage> toolUsage;

  /// Never exceeds 100, never negative — always derived as a ratio of
  /// onTrackMembers to totalMembers.
  int get onTrackPercent => totalMembers == 0
      ? 0
      : ((onTrackMembers / totalMembers) * 100).round().clamp(0, 100);

  double get budgetUtilizationPercent {
    if (budgetAllocated == 0) return 0;
    final raw = ((budgetAllocated - budgetRemaining) / budgetAllocated) * 100;
    // `.clamp()` returns `num` even on a `double` receiver — `.toDouble()`
    // keeps this genuinely double-typed to match the getter's return type.
    return raw.clamp(0, 999).toDouble();
  }

  double get budgetForecast => totalMonthlyAiSpend * 1.06;

  /// Overall team health, derived from the average of the 4 category
  /// scores. Drives the hero card's status pill.
  TeamHealthStatus get healthStatus {
    if (healthBreakdown.isEmpty) return TeamHealthStatus.healthy;
    final avg = healthBreakdown.map((h) => h.score).reduce((a, b) => a + b) /
        healthBreakdown.length;
    if (avg >= 75) return TeamHealthStatus.healthy;
    if (avg >= 55) return TeamHealthStatus.warning;
    return TeamHealthStatus.critical;
  }
}

class EngineeringManagerTeamsData {
  const EngineeringManagerTeamsData({
    required this.overview,
    required this.allMembers,
    required this.searchQuery,
    required this.activeFilter,
  });

  final EngineeringTeamOverview overview;
  final List<TeamMember> allMembers;
  final String searchQuery;
  final MemberFilter activeFilter;

  int get highAdoptionCount => allMembers
      .where((m) => m.matchesFilter(MemberFilter.highAdoption))
      .length;
  int get needsAttentionCount => allMembers
      .where((m) => m.matchesFilter(MemberFilter.needsAttention))
      .length;
  int get blockedCount =>
      allMembers.where((m) => m.matchesFilter(MemberFilter.blocked)).length;
  int get presenceActiveCount => allMembers
      .where((m) => m.matchesFilter(MemberFilter.presenceActive))
      .length;
  int get presenceAwayCount => allMembers
      .where((m) => m.matchesFilter(MemberFilter.presenceAway))
      .length;

  List<TeamMember> get filteredMembers {
    return allMembers.where((m) {
      if (!m.matchesQuery(searchQuery)) return false;
      return m.matchesFilter(activeFilter);
    }).toList();
  }

  EngineeringManagerTeamsData copyWith({
    EngineeringTeamOverview? overview,
    List<TeamMember>? allMembers,
    String? searchQuery,
    MemberFilter? activeFilter,
  }) {
    return EngineeringManagerTeamsData(
      overview: overview ?? this.overview,
      allMembers: allMembers ?? this.allMembers,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

sealed class EngineeringManagerTeamsState {
  const EngineeringManagerTeamsState();
}

class EngineeringManagerTeamsInitial extends EngineeringManagerTeamsState {
  const EngineeringManagerTeamsInitial();
}

class EngineeringManagerTeamsLoading extends EngineeringManagerTeamsState {
  const EngineeringManagerTeamsLoading();
}

class EngineeringManagerTeamsLoaded extends EngineeringManagerTeamsState {
  const EngineeringManagerTeamsLoaded(this.data);
  final EngineeringManagerTeamsData data;
}

class EngineeringManagerTeamsError extends EngineeringManagerTeamsState {
  const EngineeringManagerTeamsError(this.message);
  final String message;
}

/// Cubit for Engineering Manager · Team.
///
/// PUBLIC API UNCHANGED: loadTeams() / refresh() / search() / applyFilter()
/// keep the exact same signatures as the version you uploaded, so Home (or
/// any other screen) that already depends on this cubit keeps compiling.
///
/// `loadTeams()` calls a mock data source with an artificial delay.
/// Swap `_fetchMockMembers()` for your real repository call (ideally the
/// SAME repository the EM Home screen uses) once available — keep the shape
/// of [TeamMember] / [EngineeringTeamOverview] the same so this screen and
/// Home/AI stay numerically consistent.
class EngineeringManagerTeamsCubit extends Cubit<EngineeringManagerTeamsState> {
  EngineeringManagerTeamsCubit()
      : super(const EngineeringManagerTeamsInitial());

  Future<void> loadTeams() async {
    emit(const EngineeringManagerTeamsLoading());
    try {
      final members = await _fetchMockMembers();
      final overview = _buildOverview(members);
      emit(EngineeringManagerTeamsLoaded(
        EngineeringManagerTeamsData(
          overview: overview,
          allMembers: members,
          searchQuery: '',
          activeFilter: MemberFilter.all,
        ),
      ));
    } catch (e) {
      emit(EngineeringManagerTeamsError(e.toString()));
    }
  }

  Future<void> refresh() => loadTeams();

  void search(String query) {
    final state = this.state;
    if (state is EngineeringManagerTeamsLoaded) {
      emit(EngineeringManagerTeamsLoaded(
          state.data.copyWith(searchQuery: query)));
    }
  }

  void applyFilter(MemberFilter filter) {
    final state = this.state;
    if (state is EngineeringManagerTeamsLoaded) {
      emit(EngineeringManagerTeamsLoaded(
          state.data.copyWith(activeFilter: filter)));
    }
  }

  EngineeringTeamOverview _buildOverview(List<TeamMember> members) {
    if (members.isEmpty) {
      return const EngineeringTeamOverview(
        totalMembers: 0,
        onTrackMembers: 0,
        totalMonthlyAiSpend: 0,
        avgAiAdoptionPercent: 0,
        sprintVelocityPercent: 0,
        openPrCount: 0,
      );
    }
    final onTrack = members
        .where((m) => m.engagementStatus == MemberEngagementStatus.onTrack)
        .length;
    final totalSpend =
        members.fold<double>(0, (sum, m) => sum + m.monthlyAiSpend);
    final avgAdoption =
        (members.map((m) => m.aiAdoptionPercent).reduce((a, b) => a + b) /
                members.length)
            .round();
    final totalAssigned =
        members.fold<int>(0, (sum, m) => sum + m.sprintPointsAssigned);
    final totalCapacity =
        members.fold<int>(0, (sum, m) => sum + m.sprintCapacity);
    final velocity = totalCapacity == 0
        ? 0
        : ((totalAssigned / totalCapacity) * 100).round().clamp(0, 999);
    final openPrs = members.fold<int>(0, (sum, m) => sum + m.prsOpen);

    final avgProductivity =
        (members.map((m) => m.productivityScore).reduce((a, b) => a + b) /
                members.length)
            .round();
    final totalAllocatedBudget =
        members.fold<double>(0, (sum, m) => sum + m.allocatedBudget) +
            1200; // + team-level tools
    final budgetRemaining = ((totalAllocatedBudget - totalSpend)
        .clamp(0, double.infinity)) as double;

    final toolUsage = _buildTeamToolUsage(members);
    // NOTE: `num.clamp()` returns `num`, not `int`, even when called on an
    // `int` receiver — `.toInt()` keeps these genuinely int-typed so they
    // can be assigned to the int-typed `score`/`sprintVelocityPercent`
    // fields without a compile error.
    final int budgetScore = totalAllocatedBudget == 0
        ? 100
        : (((budgetRemaining / totalAllocatedBudget) * 100)
                .round()
                .clamp(0, 100))
            .toInt();

    return EngineeringTeamOverview(
      totalMembers: members.length,
      onTrackMembers: onTrack,
      totalMonthlyAiSpend: totalSpend,
      avgAiAdoptionPercent: avgAdoption,
      sprintVelocityPercent: velocity,
      openPrCount: openPrs,
      teamName: 'Platform Engineering',
      managerName: 'Aditya Rao',
      hasUnreadNotifications: true,
      productivityScore: avgProductivity,
      budgetAllocated: totalAllocatedBudget,
      budgetRemaining: budgetRemaining,
      pendingApprovalsCount: 5,
      activeAiToolsCount: toolUsage.length,
      healthBreakdown: [
        HealthCategoryScore(
            name: 'Delivery', score: velocity.clamp(0, 100).toInt()),
        HealthCategoryScore(
            name: 'AI Adoption', score: avgAdoption.clamp(0, 100).toInt()),
        HealthCategoryScore(
            name: 'Productivity', score: avgProductivity.clamp(0, 100).toInt()),
        HealthCategoryScore(name: 'Budget', score: budgetScore),
      ],
      toolUsage: toolUsage,
    );
  }

  List<TeamToolUsage> _buildTeamToolUsage(List<TeamMember> members) {
    final Map<String, List<TeamMember>> byTool = {};
    for (final m in members) {
      for (final t in m.tools) {
        byTool.putIfAbsent(t, () => []).add(m);
      }
    }
    const trendByTool = {
      'GitHub Copilot': 8.5,
      'Claude': 12.0,
      'ChatGPT': -3.2,
    };
    const unusedByTool = {
      'GitHub Copilot': 2,
      'Claude': 0,
      'ChatGPT': 1,
    };
    return byTool.entries.map((e) {
      final toolMembers = e.value;
      final spend = toolMembers.fold<double>(
        0,
        (sum, m) =>
            sum +
            (m.toolBreakdown
                .where((tb) => tb.toolName == e.key)
                .fold<double>(0, (s, tb) => s + tb.monthlySpend)),
      );
      return TeamToolUsage(
        toolName: e.key,
        activeUsers: toolMembers.length,
        totalUsers: members.length,
        monthlySpend: spend,
        trendPercent: trendByTool[e.key] ?? 0,
        licenseSeats: toolMembers.length + (unusedByTool[e.key] ?? 0),
        unusedLicenseCount: unusedByTool[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.monthlySpend.compareTo(a.monthlySpend));
  }

  Future<List<TeamMember>> _fetchMockMembers() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const [
      TeamMember(
        id: 'm1',
        name: 'Arun Kumar',
        role: 'Senior Software Engineer',
        subTeam: 'Backend',
        status: PresenceStatus.active,
        lastActiveLabel: 'Last active 8 min ago',
        aiAdoptionPercent: 92,
        monthlyAiSpend: 420,
        primaryTool: 'GitHub Copilot',
        tools: ['GitHub Copilot', 'ChatGPT'],
        sprintPointsAssigned: 11,
        sprintCapacity: 13,
        prsOpen: 2,
        prsReviewed: 14,
        hasStaleBlockers: false,
        joinedLabel: 'Joined Jan 2023',
        usageTrendPercent: 6.4,
        usageTrendIsUp: true,
        productivityScore: 88,
        capacityPercent: 85,
        currentTasks: 6,
        completedTasks: 42,
        overdueTasks: 0,
        allocatedBudget: 500,
        toolBreakdown: [
          ToolUsage(
              toolName: 'GitHub Copilot',
              adoptionPercent: 92,
              monthlySpend: 300),
          ToolUsage(
              toolName: 'ChatGPT', adoptionPercent: 48, monthlySpend: 120),
        ],
        recentActivity: [
          ActivityItem(
            title: 'Merged: Fix payment retry race condition',
            status: ActivityStatus.success,
            statusLabel: 'Merged',
            relativeTime: '2h ago',
          ),
          ActivityItem(
            title: 'Opened: Add idempotency keys to billing API',
            status: ActivityStatus.warning,
            statusLabel: 'In review',
            relativeTime: '1d ago',
          ),
        ],
      ),
      TeamMember(
        id: 'm2',
        name: 'Priya Nair',
        role: 'Flutter Developer',
        subTeam: 'Mobile',
        status: PresenceStatus.away,
        lastActiveLabel: 'Last active 2h ago',
        aiAdoptionPercent: 64,
        monthlyAiSpend: 210,
        primaryTool: 'Claude',
        tools: ['Claude'],
        sprintPointsAssigned: 9,
        sprintCapacity: 13,
        prsOpen: 1,
        prsReviewed: 6,
        hasStaleBlockers: false,
        joinedLabel: 'Joined Jun 2023',
        usageTrendPercent: 3.1,
        usageTrendIsUp: true,
        productivityScore: 74,
        capacityPercent: 69,
        currentTasks: 4,
        completedTasks: 21,
        overdueTasks: 1,
        allocatedBudget: 300,
        toolBreakdown: [
          ToolUsage(toolName: 'Claude', adoptionPercent: 64, monthlySpend: 210),
        ],
        recentActivity: [
          ActivityItem(
            title: 'Opened: Animate CEO copilot sidebar transitions',
            status: ActivityStatus.warning,
            statusLabel: 'In review',
            relativeTime: '5h ago',
          ),
        ],
      ),
      TeamMember(
        id: 'm3',
        name: 'Karthik Subramaniam',
        role: 'Backend Engineer',
        subTeam: 'Backend',
        status: PresenceStatus.offline,
        lastActiveLabel: 'Last active yesterday',
        aiAdoptionPercent: 38,
        monthlyAiSpend: 90,
        primaryTool: 'GitHub Copilot',
        tools: ['GitHub Copilot'],
        sprintPointsAssigned: 8,
        sprintCapacity: 13,
        prsOpen: 3,
        prsReviewed: 2,
        hasStaleBlockers: true,
        needsAttention: true,
        attentionReason: 'Assigned Copilot license has not been used recently.',
        joinedLabel: 'Joined Nov 2022',
        usageTrendPercent: 4.2,
        usageTrendIsUp: false,
        productivityScore: 52,
        capacityPercent: 62,
        currentTasks: 5,
        completedTasks: 9,
        overdueTasks: 3,
        allocatedBudget: 200,
        toolBreakdown: [
          ToolUsage(
              toolName: 'GitHub Copilot',
              adoptionPercent: 38,
              monthlySpend: 90),
        ],
        recentActivity: [
          ActivityItem(
            title: 'Blocked: Migrate ledger writes to async queue',
            status: ActivityStatus.danger,
            statusLabel: 'Blocked 4d',
            relativeTime: '4d ago',
          ),
        ],
      ),
      TeamMember(
        id: 'm4',
        name: 'Divya Raghavan',
        role: 'QA Engineer',
        subTeam: 'QA',
        status: PresenceStatus.active,
        lastActiveLabel: 'Last active 15 min ago',
        aiAdoptionPercent: 71,
        monthlyAiSpend: 150,
        primaryTool: 'ChatGPT',
        tools: ['ChatGPT'],
        sprintPointsAssigned: 10,
        sprintCapacity: 13,
        prsOpen: 0,
        prsReviewed: 9,
        hasStaleBlockers: false,
        joinedLabel: 'Joined Mar 2024',
        productivityScore: 79,
        capacityPercent: 77,
        currentTasks: 5,
        completedTasks: 30,
        overdueTasks: 0,
        allocatedBudget: 250,
        toolBreakdown: [
          ToolUsage(
              toolName: 'ChatGPT', adoptionPercent: 71, monthlySpend: 150),
        ],
        recentActivity: [
          ActivityItem(
            title: 'Merged: Regression suite for checkout flow',
            status: ActivityStatus.success,
            statusLabel: 'Merged',
            relativeTime: '1d ago',
          ),
        ],
      ),
      TeamMember(
        id: 'm5',
        name: 'Rahul Verma',
        role: 'DevOps Engineer',
        subTeam: 'DevOps',
        status: PresenceStatus.active,
        lastActiveLabel: 'Last active 3 min ago',
        aiAdoptionPercent: 88,
        monthlyAiSpend: 260,
        primaryTool: 'Claude',
        tools: ['Claude', 'ChatGPT'],
        sprintPointsAssigned: 15,
        sprintCapacity: 13,
        prsOpen: 4,
        prsReviewed: 11,
        hasStaleBlockers: false,
        joinedLabel: 'Joined Sep 2022',
        usageTrendPercent: 9.0,
        usageTrendIsUp: true,
        productivityScore: 91,
        capacityPercent: 115,
        currentTasks: 8,
        completedTasks: 55,
        overdueTasks: 1,
        allocatedBudget: 400,
        toolBreakdown: [
          ToolUsage(toolName: 'Claude', adoptionPercent: 70, monthlySpend: 170),
          ToolUsage(toolName: 'ChatGPT', adoptionPercent: 18, monthlySpend: 90),
        ],
        recentActivity: [
          ActivityItem(
            title: 'Opened: Autoscale worker pool for nightly jobs',
            status: ActivityStatus.warning,
            statusLabel: 'In review',
            relativeTime: '3h ago',
          ),
          ActivityItem(
            title: 'Merged: Rotate staging credentials',
            status: ActivityStatus.success,
            statusLabel: 'Merged',
            relativeTime: '2d ago',
          ),
        ],
      ),
      TeamMember(
        id: 'm6',
        name: 'Sneha Iyer',
        role: 'Frontend Engineer',
        subTeam: 'Frontend',
        status: PresenceStatus.active,
        lastActiveLabel: 'Last active 20 min ago',
        aiAdoptionPercent: 95,
        monthlyAiSpend: 310,
        primaryTool: 'GitHub Copilot',
        tools: ['GitHub Copilot', 'Claude'],
        sprintPointsAssigned: 12,
        sprintCapacity: 13,
        prsOpen: 1,
        prsReviewed: 18,
        hasStaleBlockers: false,
        joinedLabel: 'Joined Feb 2023',
        usageTrendPercent: 2.6,
        usageTrendIsUp: true,
        productivityScore: 95,
        capacityPercent: 92,
        currentTasks: 7,
        completedTasks: 61,
        overdueTasks: 0,
        allocatedBudget: 450,
        toolBreakdown: [
          ToolUsage(
              toolName: 'GitHub Copilot',
              adoptionPercent: 65,
              monthlySpend: 190),
          ToolUsage(toolName: 'Claude', adoptionPercent: 30, monthlySpend: 120),
        ],
        recentActivity: [
          ActivityItem(
            title: 'Merged: Glassmorphism login polish',
            status: ActivityStatus.success,
            statusLabel: 'Merged',
            relativeTime: '6h ago',
          ),
        ],
      ),
      TeamMember(
        id: 'm7',
        name: 'Vikram Chauhan',
        role: 'Mobile Developer',
        subTeam: 'Mobile',
        status: PresenceStatus.offline,
        lastActiveLabel: 'Last active 2 days ago',
        aiAdoptionPercent: 0,
        monthlyAiSpend: 0,
        primaryTool: 'Not assigned',
        tools: [],
        sprintPointsAssigned: 5,
        sprintCapacity: 13,
        prsOpen: 2,
        prsReviewed: 0,
        hasStaleBlockers: true,
        needsAttention: true,
        attentionReason: 'No AI tool usage recorded this month.',
        joinedLabel: 'Joined Jul 2024',
        productivityScore: 22,
        capacityPercent: 38,
        currentTasks: 2,
        completedTasks: 3,
        overdueTasks: 2,
        allocatedBudget: 0,
        toolBreakdown: const [],
        recentActivity: [
          ActivityItem(
            title: 'Blocked: Push notification token refresh',
            status: ActivityStatus.danger,
            statusLabel: 'Blocked 6d',
            relativeTime: '6d ago',
          ),
        ],
      ),
      TeamMember(
        id: 'm8',
        name: 'Meera Pillai',
        role: 'Backend Engineer',
        subTeam: 'Backend',
        status: PresenceStatus.away,
        lastActiveLabel: 'Last active 1h ago',
        aiAdoptionPercent: 55,
        monthlyAiSpend: 130,
        primaryTool: 'ChatGPT',
        tools: ['ChatGPT'],
        sprintPointsAssigned: 14,
        sprintCapacity: 13,
        prsOpen: 2,
        prsReviewed: 7,
        hasStaleBlockers: false,
        joinedLabel: 'Joined Apr 2023',
        productivityScore: 68,
        capacityPercent: 108,
        currentTasks: 6,
        completedTasks: 24,
        overdueTasks: 1,
        allocatedBudget: 220,
        toolBreakdown: [
          ToolUsage(
              toolName: 'ChatGPT', adoptionPercent: 55, monthlySpend: 130),
        ],
        recentActivity: [
          ActivityItem(
            title: 'Opened: Partition transaction table by month',
            status: ActivityStatus.warning,
            statusLabel: 'In review',
            relativeTime: '9h ago',
          ),
        ],
      ),
    ];
  }
}
