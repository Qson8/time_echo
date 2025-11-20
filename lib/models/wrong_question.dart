/// 错题数据模型
class WrongQuestion {
  final int id;
  final int questionId; // 关联的题目ID
  final int wrongCount; // 错误次数
  final DateTime firstWrongTime; // 首次错误时间
  final DateTime lastWrongTime; // 最后错误时间
  final DateTime? lastReviewTime; // 最后复习时间
  final DateTime? nextReviewTime; // 下次复习时间（基于遗忘曲线）
  final String? wrongReason; // 错误原因（记忆模糊、理解错误等）
  final bool isMastered; // 是否已掌握
  final DateTime? masteredTime; // 掌握时间

  WrongQuestion({
    required this.id,
    required this.questionId,
    this.wrongCount = 1,
    required this.firstWrongTime,
    required this.lastWrongTime,
    this.lastReviewTime,
    this.nextReviewTime,
    this.wrongReason,
    this.isMastered = false,
    this.masteredTime,
  });

  factory WrongQuestion.fromMap(Map<String, dynamic> map) {
    return WrongQuestion(
      id: map['id'] ?? 0,
      questionId: map['question_id'] ?? 0,
      wrongCount: map['wrong_count'] ?? 1,
      firstWrongTime: DateTime.parse(map['first_wrong_time']),
      lastWrongTime: DateTime.parse(map['last_wrong_time']),
      lastReviewTime: map['last_review_time'] != null
          ? DateTime.parse(map['last_review_time'])
          : null,
      nextReviewTime: map['next_review_time'] != null
          ? DateTime.parse(map['next_review_time'])
          : null,
      wrongReason: map['wrong_reason'],
      isMastered: map['is_mastered'] == 1,
      masteredTime: map['mastered_time'] != null
          ? DateTime.parse(map['mastered_time'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'wrong_count': wrongCount,
      'first_wrong_time': firstWrongTime.toIso8601String(),
      'last_wrong_time': lastWrongTime.toIso8601String(),
      'last_review_time': lastReviewTime?.toIso8601String(),
      'next_review_time': nextReviewTime?.toIso8601String(),
      'wrong_reason': wrongReason,
      'is_mastered': isMastered ? 1 : 0,
      'mastered_time': masteredTime?.toIso8601String(),
    };
  }

  WrongQuestion copyWith({
    int? id,
    int? questionId,
    int? wrongCount,
    DateTime? firstWrongTime,
    DateTime? lastWrongTime,
    DateTime? lastReviewTime,
    DateTime? nextReviewTime,
    String? wrongReason,
    bool? isMastered,
    DateTime? masteredTime,
  }) {
    return WrongQuestion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      wrongCount: wrongCount ?? this.wrongCount,
      firstWrongTime: firstWrongTime ?? this.firstWrongTime,
      lastWrongTime: lastWrongTime ?? this.lastWrongTime,
      lastReviewTime: lastReviewTime ?? this.lastReviewTime,
      nextReviewTime: nextReviewTime ?? this.nextReviewTime,
      wrongReason: wrongReason ?? this.wrongReason,
      isMastered: isMastered ?? this.isMastered,
      masteredTime: masteredTime ?? this.masteredTime,
    );
  }

  /// 检查是否需要复习（基于遗忘曲线）
  bool get needsReview {
    if (isMastered) return false;
    if (nextReviewTime == null) return true;
    return DateTime.now().isAfter(nextReviewTime!);
  }

  /// 计算掌握度（0-100）
  int get masteryLevel {
    if (isMastered) return 100;
    // 基于错误次数和复习次数计算
    // 错误次数越少，掌握度越高
    // 如果已经复习过，掌握度提升
    int baseLevel = 100 - (wrongCount * 10);
    if (lastReviewTime != null) {
      baseLevel += 20; // 复习过提升20%
    }
    return baseLevel.clamp(0, 100);
  }
}

