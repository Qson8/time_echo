/// 拾光记录数据模型
class TestRecord {
  final int id;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final int totalTime; // 总用时（秒）
  final int echoAge; // 拾光年龄
  final String comment; // 评语
  final DateTime testTime;
  final Map<String, int> categoryScores; // 各分类得分

  TestRecord({
    required this.id,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.totalTime,
    required this.echoAge,
    required this.comment,
    required this.testTime,
    required this.categoryScores,
  });

  factory TestRecord.fromMap(Map<String, dynamic> map) {
    // 安全地解析拾光时间
    DateTime testTime;
    final testTimeStr = map['test_time'];
    if (testTimeStr != null && testTimeStr.toString().isNotEmpty) {
      try {
        testTime = DateTime.parse(testTimeStr.toString());
      } catch (e) {
        // 如果解析失败，使用当前时间
        testTime = DateTime.now();
      }
    } else {
      testTime = DateTime.now();
    }
    
    // 安全地解析分类得分
    Map<String, int> categoryScoresMap;
    final categoryScoresStr = map['category_scores'];
    if (categoryScoresStr != null && categoryScoresStr.toString().isNotEmpty) {
      try {
        categoryScoresMap = Map<String, int>.from(
          Map.fromEntries(
            (categoryScoresStr as String).split(',').where((e) => e.isNotEmpty).map((e) {
              final parts = e.split(':');
              if (parts.length == 2) {
                return MapEntry(parts[0], int.parse(parts[1]));
              }
              return MapEntry('', 0);
            }).where((e) => e.key.isNotEmpty),
          ),
        );
      } catch (e) {
        categoryScoresMap = {};
      }
    } else {
      categoryScoresMap = {};
    }
    
    return TestRecord(
      id: map['id'],
      totalQuestions: map['total_questions'],
      correctAnswers: map['correct_answers'],
      accuracy: map['accuracy'],
      totalTime: map['total_time'],
      echoAge: map['echo_age'],
      comment: map['comment'],
      testTime: testTime,
      categoryScores: categoryScoresMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'accuracy': accuracy,
      'total_time': totalTime,
      'echo_age': echoAge,
      'comment': comment,
      'test_time': testTime.toIso8601String(),
      'category_scores': categoryScores.entries
          .map((e) => '${e.key}:${e.value}')
          .join(','),
    };
  }
}
