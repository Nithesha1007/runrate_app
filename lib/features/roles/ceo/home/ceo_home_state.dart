import 'package:equatable/equatable.dart';
import '../../../../shared/models/insight_model.dart';
import '../../../../shared/widgets/simple_bar_chart.dart';

abstract class CeoHomeState extends Equatable {
  const CeoHomeState();
  @override
  List<Object?> get props => [];
}

class CeoHomeLoading extends CeoHomeState {}

class CeoHomeLoaded extends CeoHomeState {
  final Map<String, double> kpis;
  final List<BarChartPoint> deptChart;
  final List<InsightModel> insights;

  const CeoHomeLoaded({required this.kpis, required this.deptChart, required this.insights});

  @override
  List<Object?> get props => [kpis, deptChart, insights];
}

class CeoHomeError extends CeoHomeState {
  final String message;
  const CeoHomeError(this.message);
  @override
  List<Object?> get props => [message];
}
