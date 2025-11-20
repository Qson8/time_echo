/// 每日挑战数据模型
class DailyChallenge {
  final int id;
  final String title; // 挑战标题
  final String description; // 挑战描述
  final ChallengeType type; // 挑战类型
  final int targetValue; // 目标值
  final int currentValue; // 当前值
  final DateTime date; // 挑战日期
  final bool isCompleted; // 是否完成
  final DateTime? completedAt; // 完成时间
  final int rewardPoints; // 奖励积分
  final String? rewardBadge; // 奖励徽章

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.date,
    this.isCompleted = false,
    this.completedAt,
    this.rewardPoints = 10,
    this.rewardBadge,
  });

  factory DailyChallenge.fromMap(Map<String, dynamic> map) {
    DateTime date;
    final dateStr = map['date'];
    if (dateStr != null && dateStr.toString().isNotEmpty) {
      try {
        date = DateTime.parse(dateStr.toString());
      } catch (e) {
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

    DateTime? completedAt;
    final completedAtStr = map['completed_at'];
    if (completedAtStr != null && completedAtStr.toString().isNotEmpty) {
      try {
        completedAt = DateTime.parse(completedAtStr.toString());
      } catch (e) {
        completedAt = null;
      }
    }

    return DailyChallenge(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: _parseChallengeType(map['type'] ?? 'accuracy'),
      targetValue: map['target_value'] ?? 0,
      currentValue: map['current_value'] ?? 0,
      date: date,
      isCompleted: map['is_completed'] ?? false,
      completedAt: completedAt,
      rewardPoints: map['reward_points'] ?? 10,
      rewardBadge: map['reward_badge'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'target_value': targetValue,
      'current_value': currentValue,
      'date': date.toIso8601String(),
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'reward_points': rewardPoints,
      'reward_badge': rewardBadge,
    };
  }

  /// 创建副本
  DailyChallenge copyWith({
    int? id,
    String? title,
    String? description,
    ChallengeType? type,
    int? targetValue,
    int? currentValue,
    DateTime? date,
    bool? isCompleted,
    DateTime? completedAt,
    int? rewardPoints,
    String? rewardBadge,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      rewardBadge: rewardBadge ?? this.rewardBadge,
    );
  }

  /// 获取进度百分比
  double get progress {
    if (targetValue == 0) return 0.0;
    final progress = currentValue / targetValue;
    return progress > 1.0 ? 1.0 : progress;
  }

  /// 检查是否完成
  bool get isTargetReached => currentValue >= targetValue;
}

/// 挑战类型枚举
enum ChallengeType {
  accuracy, // 准确率挑战
  speed, // 速度挑战
  category, // 分类专精
  streak, // 连击挑战
  total, // 总题数挑战
}

/// 解析挑战类型
ChallengeType _parseChallengeType(String value) {
  switch (value) {
    case 'accuracy':
      return ChallengeType.accuracy;
    case 'speed':
      return ChallengeType.speed;
    case 'category':
      return ChallengeType.category;
    case 'streak':
      return ChallengeType.streak;
    case 'total':
      return ChallengeType.total;
    default:
      return ChallengeType.accuracy;
  }
}

/// ChallengeType 扩展方法
extension ChallengeTypeExtension on ChallengeType {
  String get displayName {
    switch (this) {
      case ChallengeType.accuracy:
        return '准确率挑战';
      case ChallengeType.speed:
        return '速度挑战';
      case ChallengeType.category:
        return '分类专精';
      case ChallengeType.streak:
        return '连击挑战';
      case ChallengeType.total:
        return '总题数挑战';
    }
  }
}

