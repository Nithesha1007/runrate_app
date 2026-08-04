class TeamModel {
  final String name;
  final double spend;
  final double trendPercent;
  final int memberCount;

  const TeamModel({
    required this.name,
    required this.spend,
    this.trendPercent = 0,
    this.memberCount = 0,
  });
}
