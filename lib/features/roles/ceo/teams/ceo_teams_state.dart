import 'package:equatable/equatable.dart';
import '../../../../shared/models/team_model.dart';

class CeoTeamsState extends Equatable {
  final List<TeamModel> allDepartments;
  final String query;
  final bool loading;

  const CeoTeamsState({this.allDepartments = const [], this.query = '', this.loading = true});

  List<TeamModel> get filtered => query.isEmpty
      ? allDepartments
      : allDepartments.where((d) => d.name.toLowerCase().contains(query.toLowerCase())).toList();

  CeoTeamsState copyWith({List<TeamModel>? allDepartments, String? query, bool? loading}) {
    return CeoTeamsState(
      allDepartments: allDepartments ?? this.allDepartments,
      query: query ?? this.query,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [allDepartments, query, loading];
}
