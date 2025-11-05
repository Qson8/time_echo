/// 怀旧故事数据模型
class NostalgicStory {
  final int id;
  final String title;              // 故事标题
  final String content;            // 故事内容
  final String era;                // 年代（80年代/90年代）
  final String category;           // 分类（影视/音乐/事件）
  final List<int> relatedQuestionIds; // 关联的题目IDs
  final List<String> tags;          // 标签
  final String thumbnail;         // 缩略图描述（文字，如"经典电影海报"）
  final String? author;            // 作者（可选）
  final DateTime publishTime;       // 发布时间
  final bool isFavorite;           // 是否收藏
  
  NostalgicStory({
    required this.id,
    required this.title,
    required this.content,
    required this.era,
    required this.category,
    this.relatedQuestionIds = const [],
    this.tags = const [],
    this.thumbnail = '',
    this.author,
    required this.publishTime,
    this.isFavorite = false,
  });

  factory NostalgicStory.fromMap(Map<String, dynamic> map) {
    // 安全地解析关联题目IDs
    List<int> relatedQuestionIds = [];
    final questionIdsStr = map['related_question_ids'];
    if (questionIdsStr != null && questionIdsStr.toString().isNotEmpty) {
      try {
        if (questionIdsStr is List) {
          relatedQuestionIds = List<int>.from(questionIdsStr.map((e) => int.parse(e.toString())));
        } else if (questionIdsStr is String) {
          relatedQuestionIds = questionIdsStr
              .split(',')
              .where((e) => e.isNotEmpty)
              .map((e) => int.parse(e.trim()))
              .toList();
        }
      } catch (e) {
        relatedQuestionIds = [];
      }
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
    
    // 安全地解析发布时间
    DateTime publishTime;
    final publishTimeStr = map['publish_time'];
    if (publishTimeStr != null && publishTimeStr.toString().isNotEmpty) {
      try {
        publishTime = DateTime.parse(publishTimeStr.toString());
      } catch (e) {
        publishTime = DateTime.now();
      }
    } else {
      publishTime = DateTime.now();
    }
    
    return NostalgicStory(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      era: map['era'] ?? '80年代',
      category: map['category'] ?? '影视',
      relatedQuestionIds: relatedQuestionIds,
      tags: tagsList,
      thumbnail: map['thumbnail'] ?? '',
      author: map['author'],
      publishTime: publishTime,
      isFavorite: map['is_favorite'] == true || map['is_favorite'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'era': era,
      'category': category,
      'related_question_ids': relatedQuestionIds.join(','),
      'tags': tags.join(','),
      'thumbnail': thumbnail,
      'author': author,
      'publish_time': publishTime.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  /// 创建副本（用于更新）
  NostalgicStory copyWith({
    int? id,
    String? title,
    String? content,
    String? era,
    String? category,
    List<int>? relatedQuestionIds,
    List<String>? tags,
    String? thumbnail,
    String? author,
    DateTime? publishTime,
    bool? isFavorite,
  }) {
    return NostalgicStory(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      era: era ?? this.era,
      category: category ?? this.category,
      relatedQuestionIds: relatedQuestionIds ?? this.relatedQuestionIds,
      tags: tags ?? this.tags,
      thumbnail: thumbnail ?? this.thumbnail,
      author: author ?? this.author,
      publishTime: publishTime ?? this.publishTime,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// 获取故事预览文本
  String getPreviewText({int maxLength = 100}) {
    if (content.length <= maxLength) {
      return content;
    }
    return '${content.substring(0, maxLength)}...';
  }
}

