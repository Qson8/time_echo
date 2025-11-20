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
  
  // 新增字段：知识点扩展
  final List<String> knowledgePoints; // 知识点标签
  final String? background; // 历史背景
  final String? detailedExplanation; // 详细解析
  final List<int> relatedQuestionIds; // 相关题目ID

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
    this.knowledgePoints = const [],
    this.background,
    this.detailedExplanation,
    this.relatedQuestionIds = const [],
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
        if (optionsStr is List) {
          optionsList = List<String>.from(optionsStr);
        } else {
          optionsList = (optionsStr as String).split('|');
        }
      } catch (e) {
        optionsList = [];
      }
    } else {
      optionsList = [];
    }
    
    // 解析知识点
    List<String> knowledgePoints = [];
    if (map['knowledge_points'] != null) {
      if (map['knowledge_points'] is List) {
        knowledgePoints = List<String>.from(map['knowledge_points']);
      } else if (map['knowledge_points'] is String) {
        knowledgePoints = (map['knowledge_points'] as String).split(',').where((s) => s.trim().isNotEmpty).toList();
      }
    }
    
    // 解析相关题目ID
    List<int> relatedQuestionIds = [];
    if (map['related_question_ids'] != null) {
      if (map['related_question_ids'] is List) {
        relatedQuestionIds = List<int>.from(map['related_question_ids']);
      } else if (map['related_question_ids'] is String) {
        relatedQuestionIds = (map['related_question_ids'] as String)
            .split(',')
            .where((s) => s.trim().isNotEmpty)
            .map((s) => int.tryParse(s.trim()) ?? 0)
            .where((id) => id > 0)
            .toList();
      }
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
      knowledgePoints: knowledgePoints,
      background: map['background'],
      detailedExplanation: map['detailed_explanation'] ?? map['explanation'],
      relatedQuestionIds: relatedQuestionIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'category': category,
      'difficulty': difficulty,
      'echo_theme': echoTheme,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'is_new': isNew ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'knowledge_points': knowledgePoints,
      'background': background,
      'detailed_explanation': detailedExplanation,
      'related_question_ids': relatedQuestionIds,
    };
  }
  
  Question copyWith({
    int? id,
    String? content,
    String? category,
    String? difficulty,
    String? echoTheme,
    List<String>? options,
    int? correctAnswer,
    String? explanation,
    bool? isNew,
    DateTime? createdAt,
    List<String>? knowledgePoints,
    String? background,
    String? detailedExplanation,
    List<int>? relatedQuestionIds,
  }) {
    return Question(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      echoTheme: echoTheme ?? this.echoTheme,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      isNew: isNew ?? this.isNew,
      createdAt: createdAt ?? this.createdAt,
      knowledgePoints: knowledgePoints ?? this.knowledgePoints,
      background: background ?? this.background,
      detailedExplanation: detailedExplanation ?? this.detailedExplanation,
      relatedQuestionIds: relatedQuestionIds ?? this.relatedQuestionIds,
    );
  }
}
