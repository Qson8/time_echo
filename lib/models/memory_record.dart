/// 时光回忆数据模型
class MemoryRecord {
  final int id;
  final String content;           // 回忆内容
  final int? relatedQuestionId;    // 关联的题目ID（可选）
  final String era;                // 年代（80年代/90年代/00年代）
  final String category;           // 分类（影视/音乐/事件）
  final List<String> tags;          // 标签（如"初恋"、"大学"、"青春"）
  final DateTime memoryDate;       // 回忆的时间（用户设置的，比如"1985年的夏天"）
  final DateTime createTime;        // 记录时间
  final String mood;               // 心情（怀念/感动/开心/感慨等）
  final String? location;          // 地点（可选，如"家乡"、"大学"）
  
  MemoryRecord({
    required this.id,
    required this.content,
    this.relatedQuestionId,
    required this.era,
    required this.category,
    this.tags = const [],
    required this.memoryDate,
    required this.createTime,
    this.mood = '怀念',
    this.location,
  });

  factory MemoryRecord.fromMap(Map<String, dynamic> map) {
    // 安全地解析回忆时间
    DateTime memoryDate;
    final memoryDateStr = map['memory_date'];
    if (memoryDateStr != null && memoryDateStr.toString().isNotEmpty) {
      try {
        memoryDate = DateTime.parse(memoryDateStr.toString());
      } catch (e) {
        memoryDate = DateTime.now();
      }
    } else {
      memoryDate = DateTime.now();
    }
    
    // 安全地解析创建时间
    DateTime createTime;
    final createTimeStr = map['create_time'];
    if (createTimeStr != null && createTimeStr.toString().isNotEmpty) {
      try {
        createTime = DateTime.parse(createTimeStr.toString());
      } catch (e) {
        createTime = DateTime.now();
      }
    } else {
      createTime = DateTime.now();
    }
    
    // 安全地解析标签
    List<String> tagsList = [];
    final tagsStr = map['tags'];
    if (tagsStr != null && tagsStr.toString().isNotEmpty) {
      try {
        if (tagsStr is List) {
          tagsList = List<String>.from(tagsStr);
        } else if (tagsStr is String) {
          tagsList = tagsStr.split(',').where((e) => e.isNotEmpty).toList();
        }
      } catch (e) {
        tagsList = [];
      }
    }
    
    return MemoryRecord(
      id: map['id'],
      content: map['content'],
      relatedQuestionId: map['related_question_id'],
      era: map['era'] ?? '80年代',
      category: map['category'] ?? '影视',
      tags: tagsList,
      memoryDate: memoryDate,
      createTime: createTime,
      mood: map['mood'] ?? '怀念',
      location: map['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'related_question_id': relatedQuestionId,
      'era': era,
      'category': category,
      'tags': tags.join(','),
      'memory_date': memoryDate.toIso8601String(),
      'create_time': createTime.toIso8601String(),
      'mood': mood,
      'location': location,
    };
  }

  /// 创建副本（用于编辑）
  MemoryRecord copyWith({
    int? id,
    String? content,
    int? relatedQuestionId,
    String? era,
    String? category,
    List<String>? tags,
    DateTime? memoryDate,
    DateTime? createTime,
    String? mood,
    String? location,
  }) {
    return MemoryRecord(
      id: id ?? this.id,
      content: content ?? this.content,
      relatedQuestionId: relatedQuestionId ?? this.relatedQuestionId,
      era: era ?? this.era,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      memoryDate: memoryDate ?? this.memoryDate,
      createTime: createTime ?? this.createTime,
      mood: mood ?? this.mood,
      location: location ?? this.location,
    );
  }

  /// 获取简短的预览文本（用于列表显示）
  String getPreviewText({int maxLength = 50}) {
    if (content.length <= maxLength) {
      return content;
    }
    return '${content.substring(0, maxLength)}...';
  }

  /// 检查是否包含某个标签
  bool hasTag(String tag) {
    return tags.contains(tag);
  }
}

