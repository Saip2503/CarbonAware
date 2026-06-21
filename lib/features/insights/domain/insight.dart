enum InsightPriority {
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case InsightPriority.high:
        return 'High Impact';
      case InsightPriority.medium:
        return 'Medium Impact';
      case InsightPriority.low:
        return 'Low Impact';
    }
  }
}

class Insight {
  final String title;
  final String description;
  final String category; // 'transport', 'diet', 'energy', 'general'
  final double potentialSavingsKg;
  final InsightPriority priority;

  Insight({
    required this.title,
    required this.description,
    required this.category,
    required this.potentialSavingsKg,
    required this.priority,
  });
}
