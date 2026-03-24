// lib/models/analytics_model.dart

class FrequentQuery {
  final String message;
  final int count;

  FrequentQuery({required this.message, required this.count});

  factory FrequentQuery.fromJson(Map<String, dynamic> json) {
    return FrequentQuery(
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class QueryCategories {
  final int recommendation;
  final int medicine;
  final int food;
  final int emergency;
  final int general;

  QueryCategories({
    required this.recommendation,
    required this.medicine,
    required this.food,
    required this.emergency,
    required this.general,
  });

  factory QueryCategories.fromJson(Map<String, dynamic> json) {
    return QueryCategories(
      recommendation: json['recommendation'] ?? 0,
      medicine: json['medicine'] ?? 0,
      food: json['food'] ?? 0,
      emergency: json['emergency'] ?? 0,
      general: json['general'] ?? 0,
    );
  }

  int get total => recommendation + medicine + food + emergency + general;
}

class UserAnalytics {
  final int totalQueries;
  final int totalSessions;
  final int helpfulCount;
  final double feedbackRate;
  final List<FrequentQuery> topQueries;

  UserAnalytics({
    required this.totalQueries,
    required this.totalSessions,
    required this.helpfulCount,
    required this.feedbackRate,
    required this.topQueries,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      totalQueries: json['total_queries'] ?? 0,
      totalSessions: json['total_sessions'] ?? 0,
      helpfulCount: json['helpful_count'] ?? 0,
      feedbackRate: (json['feedback_rate'] ?? 0).toDouble(),
      topQueries: (json['top_queries'] as List? ?? [])
          .map((q) => FrequentQuery.fromJson(q))
          .toList(),
    );
  }
}