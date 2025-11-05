import '../models/memory_record.dart';
import 'json_storage_service.dart';

/// 时光回忆服务类（使用JSON文件存储）
class MemoryService {
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal();
  
  final _storage = JsonStorageService();

  /// 获取所有回忆
  Future<List<MemoryRecord>> getAllMemories() async {
    return await _storage.getAllMemories();
  }

  /// 添加回忆
  Future<void> addMemory(MemoryRecord memory) async {
    await _storage.addMemory(memory);
  }

  /// 删除回忆
  Future<void> removeMemory(int memoryId) async {
    await _storage.removeMemory(memoryId);
  }

  /// 根据ID获取回忆
  Future<MemoryRecord?> getMemoryById(int id) async {
    final memories = await getAllMemories();
    try {
      return memories.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据年代获取回忆
  Future<List<MemoryRecord>> getMemoriesByEra(String era) async {
    final memories = await getAllMemories();
    return memories.where((m) => m.era == era).toList();
  }

  /// 根据分类获取回忆
  Future<List<MemoryRecord>> getMemoriesByCategory(String category) async {
    final memories = await getAllMemories();
    return memories.where((m) => m.category == category).toList();
  }

  /// 根据标签获取回忆
  Future<List<MemoryRecord>> getMemoriesByTag(String tag) async {
    final memories = await getAllMemories();
    return memories.where((m) => m.hasTag(tag)).toList();
  }

  /// 根据关联题目ID获取回忆
  Future<List<MemoryRecord>> getMemoriesByQuestionId(int questionId) async {
    final memories = await getAllMemories();
    return memories.where((m) => m.relatedQuestionId == questionId).toList();
  }

  /// 获取按时间排序的回忆（最新在前）
  Future<List<MemoryRecord>> getMemoriesSortedByTime({bool ascending = false}) async {
    final memories = await getAllMemories();
    memories.sort((a, b) {
      if (ascending) {
        return a.createTime.compareTo(b.createTime);
      } else {
        return b.createTime.compareTo(a.createTime);
      }
    });
    return memories;
  }

  /// 获取按回忆时间排序的回忆（回忆时间最新在前）
  Future<List<MemoryRecord>> getMemoriesSortedByMemoryDate({bool ascending = false}) async {
    final memories = await getAllMemories();
    memories.sort((a, b) {
      if (ascending) {
        return a.memoryDate.compareTo(b.memoryDate);
      } else {
        return b.memoryDate.compareTo(a.memoryDate);
      }
    });
    return memories;
  }

  /// 搜索回忆（按内容关键词）
  Future<List<MemoryRecord>> searchMemories(String keyword) async {
    final memories = await getAllMemories();
    final lowerKeyword = keyword.toLowerCase();
    return memories.where((m) {
      return m.content.toLowerCase().contains(lowerKeyword) ||
          m.tags.any((tag) => tag.toLowerCase().contains(lowerKeyword)) ||
          (m.location?.toLowerCase().contains(lowerKeyword) ?? false);
    }).toList();
  }

  /// 获取所有标签（去重）
  Future<List<String>> getAllTags() async {
    final memories = await getAllMemories();
    final tagSet = <String>{};
    for (final memory in memories) {
      tagSet.addAll(memory.tags);
    }
    return tagSet.toList()..sort();
  }

  /// 获取回忆统计信息
  Future<Map<String, dynamic>> getMemoryStatistics() async {
    final memories = await getAllMemories();
    
    // 按年代统计
    final eraCounts = <String, int>{};
    for (final memory in memories) {
      eraCounts[memory.era] = (eraCounts[memory.era] ?? 0) + 1;
    }
    
    // 按分类统计
    final categoryCounts = <String, int>{};
    for (final memory in memories) {
      categoryCounts[memory.category] = (categoryCounts[memory.category] ?? 0) + 1;
    }
    
    // 按心情统计
    final moodCounts = <String, int>{};
    for (final memory in memories) {
      moodCounts[memory.mood] = (moodCounts[memory.mood] ?? 0) + 1;
    }
    
    // 标签统计（前10个最常见的标签）
    final tagCounts = <String, int>{};
    for (final memory in memories) {
      for (final tag in memory.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'total': memories.length,
      'eraCounts': eraCounts,
      'categoryCounts': categoryCounts,
      'moodCounts': moodCounts,
      'topTags': topTags.take(10).map((e) => {'tag': e.key, 'count': e.value}).toList(),
    };
  }

  /// 创建新回忆（自动生成ID）
  Future<MemoryRecord> createMemory({
    required String content,
    int? relatedQuestionId,
    required String era,
    required String category,
    List<String> tags = const [],
    DateTime? memoryDate,
    String mood = '怀念',
    String? location,
  }) async {
    // 获取最大ID
    final memories = await getAllMemories();
    int newId = 1;
    if (memories.isNotEmpty) {
      final maxId = memories.map((m) => m.id).reduce((a, b) => a > b ? a : b);
      newId = maxId + 1;
    }
    
    final memory = MemoryRecord(
      id: newId,
      content: content,
      relatedQuestionId: relatedQuestionId,
      era: era,
      category: category,
      tags: tags,
      memoryDate: memoryDate ?? DateTime.now(),
      createTime: DateTime.now(),
      mood: mood,
      location: location,
    );
    
    await addMemory(memory);
    return memory;
  }

  /// 更新回忆
  Future<void> updateMemory(MemoryRecord memory) async {
    await _storage.addMemory(memory);
  }
}

