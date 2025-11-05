/// 题目数据模型
class Question {
  final int id;
  final String content;
  final String category; // 影视、音乐、事件
  final String difficulty; // 简单、中等、困难
  final String echoTheme; // 80年代影视、90年代音乐等
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final bool isNew; // 是否为新题
  final DateTime createdAt;

  Question({
    required this.id,
    required this.content,
    required this.category,
    required this.difficulty,
    required this.echoTheme,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.isNew = false,
    required this.createdAt,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    // 安全地解析创建时间
    DateTime createdAt;
    final createdAtStr = map['created_at'];
    if (createdAtStr != null && createdAtStr.toString().isNotEmpty) {
      try {
        createdAt = DateTime.parse(createdAtStr.toString());
      } catch (e) {
        // 如果解析失败，使用当前时间
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }
    
    // 安全地解析选项
    List<String> optionsList;
    final optionsStr = map['options'];
    if (optionsStr != null && optionsStr.toString().isNotEmpty) {
      try {
        optionsList = (optionsStr as String).split('|');
      } catch (e) {
        optionsList = [];
      }
    } else {
      optionsList = [];
    }
    
    return Question(
      id: map['id'],
      content: map['content'],
      category: map['category'],
      difficulty: map['difficulty'],
      echoTheme: map['echo_theme'],
      options: optionsList,
      correctAnswer: map['correct_answer'],
      explanation: map['explanation'],
      isNew: map['is_new'] == 1,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'category': category,
      'difficulty': difficulty,
      'echo_theme': echoTheme,
      'options': options.join('|'),
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'is_new': isNew ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
