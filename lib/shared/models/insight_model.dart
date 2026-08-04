/// A single AI-generated insight surfaced on Home or the AI Insights view.
class InsightModel {
  final String id;
  final String title;
  final String description;
  final InsightSeverity severity;

  const InsightModel({
    required this.id,
    required this.title,
    required this.description,
    this.severity = InsightSeverity.info,
  });
}

enum InsightSeverity { positive, info, warning, danger }
