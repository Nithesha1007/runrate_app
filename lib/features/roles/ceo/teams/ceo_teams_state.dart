import 'package:equatable/equatable.dart';
import 'package:runrate/features/roles/ceo/shared/models/home_models.dart';

class CeoTeamsState extends Equatable {
  final List<DepartmentSummary> allDepartments;
  final String query;
  final bool loading;

  const CeoTeamsState(
      {this.allDepartments = const [], this.query = '', this.loading = true});

  List<DepartmentSummary> get filtered {
    if (query.isEmpty) return allDepartments;
    final q = query.toLowerCase();
    return allDepartments
        .where((d) =>
            d.team.name.toLowerCase().contains(q) ||
            d.leadName.toLowerCase().contains(q))
        .toList();
  }

  int get totalEmployees =>
      allDepartments.fold(0, (sum, d) => sum + d.team.memberCount);

  int get departmentCount => allDepartments.length;

  CeoTeamsState copyWith({
    List<DepartmentSummary>? allDepartments,
    String? query,
    bool? loading,
  }) {
    return CeoTeamsState(
      allDepartments: allDepartments ?? this.allDepartments,
      query: query ?? this.query,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [allDepartments, query, loading];
}
