class ReportModel {
  final String id;
  final String title;
  final String period;
  final String summary;
  final List<double> chartValues;
  final List<String> chartLabels;

  const ReportModel({
    required this.id,
    required this.title,
    required this.period,
    required this.summary,
    required this.chartValues,
    required this.chartLabels,
  });
}
