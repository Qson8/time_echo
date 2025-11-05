/// 题库更新日志数据模型
class QuestionUpdateLog {
  final int id;
  final String appName; // 应用名称
  final int newQuestionCount; // 新增题目数量
  final String version; // 版本号
  final DateTime updateTime;
  final bool isUpdated; // 是否已更新

  QuestionUpdateLog({
    required this.id,
    required this.appName,
    required this.newQuestionCount,
    required this.version,
    required this.updateTime,
    this.isUpdated = false,
  });

  factory QuestionUpdateLog.fromMap(Map<String, dynamic> map) {
    // 安全地解析更新时间
    DateTime updateTime;
    final updateTimeStr = map['update_time'];
    if (updateTimeStr != null && updateTimeStr.toString().isNotEmpty) {
      try {
        updateTime = DateTime.parse(updateTimeStr.toString());
      } catch (e) {
        // 如果解析失败，使用当前时间
        updateTime = DateTime.now();
      }
    } else {
      updateTime = DateTime.now();
    }
    
    return QuestionUpdateLog(
      id: map['id'],
      appName: map['app_name'],
      newQuestionCount: map['new_question_count'],
      version: map['version'],
      updateTime: updateTime,
      isUpdated: map['is_updated'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'app_name': appName,
      'new_question_count': newQuestionCount,
      'version': version,
      'update_time': updateTime.toIso8601String(),
      'is_updated': isUpdated ? 1 : 0,
    };
  }
}
