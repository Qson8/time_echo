import '../models/nostalgic_story.dart';
import 'json_storage_service.dart';

/// 怀旧故事服务类（使用JSON文件存储）
class StoryService {
  static final StoryService _instance = StoryService._internal();
  factory StoryService() => _instance;
  StoryService._internal();
  
  final _storage = JsonStorageService();

  /// 获取所有故事
  Future<List<NostalgicStory>> getAllStories() async {
    return await _storage.getAllStories();
  }

  /// 添加故事
  Future<void> addStory(NostalgicStory story) async {
    await _storage.addStory(story);
  }

  /// 删除故事
  Future<void> removeStory(int storyId) async {
    await _storage.removeStory(storyId);
  }

  /// 根据ID获取故事
  Future<NostalgicStory?> getStoryById(int id) async {
    final stories = await getAllStories();
    try {
      return stories.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据年代获取故事
  Future<List<NostalgicStory>> getStoriesByEra(String era) async {
    final stories = await getAllStories();
    return stories.where((s) => s.era == era).toList();
  }

  /// 根据分类获取故事
  Future<List<NostalgicStory>> getStoriesByCategory(String category) async {
    final stories = await getAllStories();
    return stories.where((s) => s.category == category).toList();
  }

  /// 根据标签获取故事
  Future<List<NostalgicStory>> getStoriesByTag(String tag) async {
    final stories = await getAllStories();
    return stories.where((s) => s.tags.contains(tag)).toList();
  }

  /// 根据关联题目ID获取故事
  Future<List<NostalgicStory>> getStoriesByQuestionId(int questionId) async {
    final stories = await getAllStories();
    return stories.where((s) => s.relatedQuestionIds.contains(questionId)).toList();
  }

  /// 获取收藏的故事
  Future<List<NostalgicStory>> getFavoriteStories() async {
    final stories = await getAllStories();
    return stories.where((s) => s.isFavorite).toList();
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(int storyId) async {
    final story = await getStoryById(storyId);
    if (story != null) {
      await addStory(story.copyWith(isFavorite: !story.isFavorite));
    }
  }

  /// 搜索故事（按标题和内容）
  Future<List<NostalgicStory>> searchStories(String keyword) async {
    final stories = await getAllStories();
    final lowerKeyword = keyword.toLowerCase();
    return stories.where((s) {
      return s.title.toLowerCase().contains(lowerKeyword) ||
          s.content.toLowerCase().contains(lowerKeyword) ||
          s.tags.any((tag) => tag.toLowerCase().contains(lowerKeyword));
    }).toList();
  }

  /// 获取故事统计信息
  Future<Map<String, dynamic>> getStoryStatistics() async {
    final stories = await getAllStories();
    
    // 按年代统计
    final eraCounts = <String, int>{};
    for (final story in stories) {
      eraCounts[story.era] = (eraCounts[story.era] ?? 0) + 1;
    }
    
    // 按分类统计
    final categoryCounts = <String, int>{};
    for (final story in stories) {
      categoryCounts[story.category] = (categoryCounts[story.category] ?? 0) + 1;
    }
    
    // 收藏数量
    final favoriteCount = stories.where((s) => s.isFavorite).length;
    
    return {
      'total': stories.length,
      'eraCounts': eraCounts,
      'categoryCounts': categoryCounts,
      'favoriteCount': favoriteCount,
    };
  }
}

