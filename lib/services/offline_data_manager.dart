import '../models/question.dart';
import '../models/test_record.dart';
import '../models/echo_achievement.dart';
import '../models/echo_collection.dart';
import 'json_storage_service.dart';

/// 离线数据管理服务（使用JSON文件存储）
class OfflineDataManager {
  static final OfflineDataManager _instance = OfflineDataManager._internal();
  factory OfflineDataManager() => _instance;
  OfflineDataManager._internal();

  final _storage = JsonStorageService();
  bool _isInitialized = false;

  /// 初始化离线数据管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('📁 初始化离线数据管理器（使用JSON存储）...');
      await _storage.initialize();
      _isInitialized = true;
      print('✅ 离线数据管理器初始化完成');
    } catch (e, stackTrace) {
      print('❌ 离线数据管理器初始化失败: $e');
      print('❌ 错误堆栈: $stackTrace');
      // 不抛出异常，允许应用继续运行
      _isInitialized = true; // 标记为已初始化，避免重复尝试
    }
  }

  /// 获取所有题目
  Future<List<Question>> getAllQuestions() async {
    await _ensureInitialized();
    return await _storage.getAllQuestions();
  }

  /// 获取随机题目
  Future<List<Question>> getRandomQuestions(int count) async {
    final allQuestions = await getAllQuestions();
    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }

  /// 根据分类获取题目
  Future<List<Question>> getQuestionsByCategory(String category) async {
    final allQuestions = await getAllQuestions();
    return allQuestions.where((q) => q.category == category).toList();
  }

  /// 根据难度获取题目
  Future<List<Question>> getQuestionsByDifficulty(String difficulty) async {
    final allQuestions = await getAllQuestions();
    return allQuestions.where((q) => q.difficulty == difficulty).toList();
  }

  /// 保存拾光记录
  Future<void> saveTestRecord(TestRecord record) async {
    await _ensureInitialized();
    await _storage.addTestRecord(record);
  }

  /// 获取所有拾光记录
  Future<List<TestRecord>> getAllTestRecords() async {
    await _ensureInitialized();
    return await _storage.getAllTestRecords();
  }

  /// 获取所有成就
  Future<List<EchoAchievement>> getAllAchievements() async {
    await _ensureInitialized();
    return await _storage.getAllAchievements();
  }

  /// 更新成就状态
  Future<void> updateAchievement(int achievementId, bool isUnlocked) async {
    await _ensureInitialized();
    final achievement = await _storage.getAchievementById(achievementId);
    if (achievement != null) {
      final updatedAchievement = EchoAchievement(
        id: achievement.id,
        achievementName: achievement.achievementName,
        achievementIcon: achievement.achievementIcon,
        reward: achievement.reward,
        condition: achievement.condition,
        isUnlocked: isUnlocked,
        unlockedAt: isUnlocked ? DateTime.now() : achievement.unlockedAt,
      );
      await _storage.updateAchievement(updatedAchievement);
    }
  }

  /// 保存收藏
  Future<void> saveCollection(EchoCollection collection) async {
    await _ensureInitialized();
    await _storage.addCollection(collection);
  }

  /// 获取所有收藏
  Future<List<EchoCollection>> getAllCollections() async {
    await _ensureInitialized();
    return await _storage.getAllCollections();
  }

  /// 删除收藏
  Future<void> removeCollection(int collectionId) async {
    await _ensureInitialized();
    await _storage.removeCollection(collectionId);
  }

  /// 获取设置
  Future<T?> getSetting<T>(String key) async {
    await _ensureInitialized();
    return await _storage.getSetting<T>(key);
  }

  /// 设置设置
  Future<void> setSetting(String key, dynamic value) async {
    await _ensureInitialized();
    await _storage.updateSetting(key, value);
  }

  /// 获取统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    await _ensureInitialized();
    final questions = await getAllQuestions();
    final achievements = await getAllAchievements();
    final collections = await getAllCollections();
    final testRecords = await getAllTestRecords();
    
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).length;
    
    return {
      'total_questions': questions.length,
      'total_achievements': achievements.length,
      'unlocked_achievements': unlockedAchievements,
      'total_collections': collections.length,
      'total_tests': testRecords.length,
      'total_correct': testRecords.fold<int>(0, (sum, r) => sum + r.correctAnswers),
      'best_accuracy': testRecords.isEmpty ? 0.0 : testRecords.map((r) => r.accuracy).reduce((a, b) => a > b ? a : b),
      'current_streak': 0, // 可以从拾光记录中计算
      'longest_streak': 0, // 可以从拾光记录中计算
    };
  }

  /// 导出数据
  Future<Map<String, dynamic>> exportData() async {
    await _ensureInitialized();
    return await _storage.exportAllData();
  }

  /// 导入数据
  Future<void> importData(Map<String, dynamic> data) async {
    await _ensureInitialized();
    await _storage.importAllData(data);
  }

  /// 清理数据
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _storage.clearAllData();
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 关闭数据管理器（JSON存储不需要显式关闭，但保留接口兼容性）
  Future<void> close() async {
    // JSON文件存储不需要显式关闭，但保留接口以兼容现有代码
    print('📁 离线数据管理器关闭（JSON存储无需显式关闭）');
    _isInitialized = false;
  }
}
