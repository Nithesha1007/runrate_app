import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/cfo/teams/cfo_teams_state.dart';

import 'cfo_department_detail_state.dart';

export 'cfo_department_detail_state.dart';

/// ---------------------------------------------------------------------
/// Cubit
/// ---------------------------------------------------------------------

class CfoDepartmentDetailCubit extends Cubit<CfoDepartmentDetailState> {
  CfoDepartmentDetailCubit(this._department)
      : super(const CfoDepartmentDetailInitial()) {
    load();
  }

  final DepartmentRoi _department;

  DepartmentRoi get department => _department;

  Future<void> load() async {
    emit(const CfoDepartmentDetailLoading());
    try {
      final data = await _fetchDetail(_department);
      emit(CfoDepartmentDetailLoaded(data));
    } catch (_) {
      emit(const CfoDepartmentDetailError(
          'Could not load this department. Pull down to retry.'));
    }
  }

  Future<void> refresh() => load();

  void setTab(DepartmentDetailTab tab) {
    final current = state;
    if (current is! CfoDepartmentDetailLoaded) return;
    emit(current.copyWith(data: current.data.copyWith(selectedTab: tab)));
  }

  /// Mock repository call, seeded from the department tapped on the
  /// Teams Overview screen. Replace with a real API/repository call —
  /// keep the artificial delay pattern for now per spec section 12.
  Future<DepartmentDetailData> _fetchDetail(DepartmentRoi department) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    // Only Engineering has a fully-specified mock (matches the design);
    // other departments get a proportionally scaled mock so the screen
    // still renders something coherent.
    if (department.id == 'dept_engineering') {
      return DepartmentDetailData(
        departmentId: department.id,
        departmentName: department.name,
        summary: const DepartmentSummaryMetrics(
          timeSavedHours: 96,
          timeSavedTrendPercent: 18,
          tasksCompleted: 642,
          tasksCompletedTrendPercent: 16,
          valueGenerated: 385000, // ₹3.85L
          valueGeneratedTrendPercent: 20,
          avgRoiPercent: 18,
          avgRoiTrendPercent: 3,
        ),
        trend: const EfficiencyTrend(
          periodLabel: 'Last 4 Weeks',
          axisLabels: ['May 3', 'May 10', 'May 17', 'May 24', 'May 31'],
          values: [
            25, 30, 33, 29, 36, 42, 38, 45, 50, 47,
            55, 58, 53, 60, 65, 61, 68, 64, 70, 75,
          ],
        ),
        aiTools: const [
          AiToolUsage(
            id: 'tool_copilot',
            name: 'GitHub Copilot',
            usagePercent: 0.65,
            glyph: AiToolGlyph.copilot,
          ),
          AiToolUsage(
            id: 'tool_chatgpt',
            name: 'ChatGPT Enterprise',
            usagePercent: 0.25,
            glyph: AiToolGlyph.chatgpt,
          ),
          AiToolUsage(
            id: 'tool_notion',
            name: 'Notion AI',
            usagePercent: 0.10,
            glyph: AiToolGlyph.notion,
          ),
        ],
        insights: const [
          KeyInsight(
            text: 'Engineering team saved 18% more time this week.',
            highlight: '18%',
          ),
          KeyInsight(
            text: 'Value generated increased by 20%.',
            highlight: '20%',
          ),
          KeyInsight(
            text: 'GitHub Copilot usage is highest among all tools.',
          ),
        ],
      );
    }

    // Generic scaled mock for any other department.
    final scale = department.timeSavedHours / 96;
    return DepartmentDetailData(
      departmentId: department.id,
      departmentName: department.name,
      summary: DepartmentSummaryMetrics(
        timeSavedHours: department.timeSavedHours,
        timeSavedTrendPercent: department.roiPercent,
        tasksCompleted: (642 * scale).round(),
        tasksCompletedTrendPercent: 16,
        valueGenerated: 385000 * scale,
        valueGeneratedTrendPercent: 20,
        avgRoiPercent: department.roiPercent,
        avgRoiTrendPercent: 3,
      ),
      trend:const EfficiencyTrend(
        periodLabel: 'Last 4 Weeks',
        axisLabels:  ['May 3', 'May 10', 'May 17', 'May 24', 'May 31'],
        values:  [
          20, 24, 22, 28, 33, 30, 36, 40, 37, 44,
          48, 45, 52, 55, 50, 58, 60, 56, 62, 66,
        ],
      ),
      aiTools: const [
        AiToolUsage(
          id: 'tool_copilot',
          name: 'GitHub Copilot',
          usagePercent: 0.50,
          glyph: AiToolGlyph.copilot,
        ),
        AiToolUsage(
          id: 'tool_chatgpt',
          name: 'ChatGPT Enterprise',
          usagePercent: 0.35,
          glyph: AiToolGlyph.chatgpt,
        ),
        AiToolUsage(
          id: 'tool_notion',
          name: 'Notion AI',
          usagePercent: 0.15,
          glyph: AiToolGlyph.notion,
        ),
      ],
      insights: [
        KeyInsight(
          text:
              '${department.name} team saved ${department.roiPercent.toStringAsFixed(0)}% more time this week.',
          highlight: '${department.roiPercent.toStringAsFixed(0)}%',
        ),
        const KeyInsight(text: 'Value generated increased by 20%.',
            highlight: '20%'),
        const KeyInsight(
            text: 'GitHub Copilot usage is highest among all tools.'),
      ],
    );
  }
}