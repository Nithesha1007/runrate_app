class SpendModel {
  final String label;
  final double amount;
  final double budget;
  final double trendPercent; // positive = up, negative = down

  const SpendModel({
    required this.label,
    required this.amount,
    required this.budget,
    this.trendPercent = 0,
  });

  double get percentUsed => budget == 0 ? 0 : (amount / budget * 100).clamp(0, 999);
}
