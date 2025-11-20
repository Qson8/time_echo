/// 时光记忆胶囊数据模型
class MemoryCapsule {
  final int id;
  final int? questionId; // 关联的题目ID（可选）
  final String title; // 记忆标题
  final String content; // 记忆内容
  final String? imagePath; // 图片路径（本地存储）
  final String? audioPath; // 音频路径（本地存储）
  final DateTime createdAt; // 创建时间
  final DateTime? memoryDate; // 记忆的时间（用户设置的，比如"1985年的夏天"）
  final List<String> tags; // 标签
  final String era; // 年代（80年代/90年代/00年代）
  final String category; // 分类（影视/音乐/事件）
  final String mood; // 心情（怀念/感动/开心/感慨等）
  final String? location; // 地点（可选）

  MemoryCapsule({
    required this.id,
    this.questionId,
    required this.title,
    required this.content,
    this.imagePath,
    this.audioPath,
    required this.createdAt,
    this.memoryDate,
    this.tags = const [],
    required this.era,
    required this.category,
    this.mood = '怀念',
    this.location,
  });

  factory MemoryCapsule.fromMap(Map<String, dynamic> map) {
    // 安全地解析创建时间
    DateTime createdAt;
    final createdAtStr = map['created_at'];
    if (createdAtStr != null && createdAtStr.toString().isNotEmpty) {
      try {
        createdAt = DateTime.parse(createdAtStr.toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    // 安全地解析记忆时间
    DateTime? memoryDate;
    final memoryDateStr = map['memory_date'];
    if (memoryDateStr != null && memoryDateStr.toString().isNotEmpty) {
      try {
        memoryDate = DateTime.parse(memoryDateStr.toString());
      } catch (e) {
        memoryDate = null;
      }
    }

    // 安全地解析标签
    List<String> tagsList = [];
    final tagsStr = map['tags'];
    if (tagsStr != null && tagsStr.toString().isNotEmpty) {
      try {
        if (tagsStr is List) {
          // 安全地转换列表，过滤掉null值
          tagsList = (tagsStr as List)
              .where((e) => e != null)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        } else if (tagsStr is String) {
          tagsList = tagsStr.split(',').where((e) => e.isNotEmpty && e.trim().isNotEmpty).map((e) => e.trim()).toList();
        }
      } catch (e) {
        print('⚠️ 解析标签失败: $e');
        tagsList = [];
      }
    }
    
    // 确保tagsList不为null
    if (tagsList.isEmpty) {
      tagsList = [];
    }

    return MemoryCapsule(
      id: map['id'] ?? 0,
      questionId: map['question_id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imagePath: map['image_path'],
      audioPath: map['audio_path'],
      createdAt: createdAt,
      memoryDate: memoryDate,
      tags: tagsList,
      era: map['era'] ?? '80年代',
      category: map['category'] ?? '影视',
      mood: map['mood'] ?? '怀念',
      location: map['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'title': title,
      'content': content,
      'image_path': imagePath,
      'audio_path': audioPath,
      'created_at': createdAt.toIso8601String(),
      'memory_date': memoryDate?.toIso8601String(),
      'tags': tags.join(','),
      'era': era,
      'category': category,
      'mood': mood,
      'location': location,
    };
  }

  /// 创建副本（用于编辑）
  MemoryCapsule copyWith({
    int? id,
    int? questionId,
    String? title,
    String? content,
    String? imagePath,
    String? audioPath,
    DateTime? createdAt,
    DateTime? memoryDate,
    List<String>? tags,
    String? era,
    String? category,
    String? mood,
    String? location,
  }) {
    return MemoryCapsule(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      memoryDate: memoryDate ?? this.memoryDate,
      tags: tags ?? this.tags,
      era: era ?? this.era,
      category: category ?? this.category,
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

  /// 检查是否有图片
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// 检查是否有音频
  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;
}

