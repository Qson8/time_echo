/// 拾光收藏夹数据模型
class EchoCollection {
  final int id;
  final int questionId;
  final String echoNote; // 拾光笔记
  final DateTime collectionTime;

  EchoCollection({
    required this.id,
    required this.questionId,
    this.echoNote = '',
    required this.collectionTime,
  });

  factory EchoCollection.fromMap(Map<String, dynamic> map) {
    // 安全地解析收藏时间
    DateTime collectionTime;
    final collectionTimeStr = map['collection_time'];
    if (collectionTimeStr != null && collectionTimeStr.toString().isNotEmpty) {
      try {
        collectionTime = DateTime.parse(collectionTimeStr.toString());
      } catch (e) {
        // 如果解析失败，使用当前时间
        collectionTime = DateTime.now();
      }
    } else {
      collectionTime = DateTime.now();
    }
    
    return EchoCollection(
      id: map['id'],
      questionId: map['question_id'],
      echoNote: map['echo_note'] ?? '',
      collectionTime: collectionTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'echo_note': echoNote,
      'collection_time': collectionTime.toIso8601String(),
    };
  }
}
