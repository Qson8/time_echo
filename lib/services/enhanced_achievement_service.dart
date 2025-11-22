import 'package:flutter/material.dart';
import '../models/echo_achievement.dart';
import '../models/test_record.dart';
import '../constants/app_constants.dart';
import '../widgets/animated_widgets.dart';

/// 增强的成就系统
class EnhancedAchievementSystem {
  static final EnhancedAchievementSystem _instance = EnhancedAchievementSystem._internal();
  factory EnhancedAchievementSystem() => _instance;
  EnhancedAchievementSystem._internal();

  /// 检查并解锁成就
  Future<List<EchoAchievement>> checkAndUnlockAchievements(
    List<TestRecord> testRecords,
    List<EchoAchievement> currentAchievements,
  ) async {
    final unlockedAchievements = <EchoAchievement>[];
    
    // 基础成就检查
    unlockedAchievements.addAll(await _checkBasicAchievements(testRecords, currentAchievements));
    
    // 高级成就检查
    unlockedAchievements.addAll(await _checkAdvancedAchievements(testRecords, currentAchievements));
    
    // 特殊成就检查
    unlockedAchievements.addAll(await _checkSpecialAchievements(testRecords, currentAchievements));
    
    // 连续成就检查
    unlockedAchievements.addAll(await _checkStreakAchievements(testRecords, currentAchievements));
    
    return unlockedAchievements;
  }

  /// 检查基础成就
  Future<List<EchoAchievement>> _checkBasicAchievements(
    List<TestRecord> testRecords,
    List<EchoAchievement> currentAchievements,
  ) async {
    final unlockedAchievements = <EchoAchievement>[];
    
    // 拾光初遇
    if (testRecords.isNotEmpty && !_isAchievementUnlocked('拾光初遇', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光初遇',
        '完成首次拾光',
        '解锁拾光徽章・初遇',
        '完成你的第一次拾光',
        Icons.star,
      ));
    }
    
    // 影视拾光者
    if (_checkCategoryMastery(testRecords, '影视', 0.9) && 
        !_isAchievementUnlocked('影视拾光者', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '影视拾光者',
        '影视分类正确率≥90%',
        '解锁影视徽章+收藏夹容量+5题',
        '你对80-90年代影视作品了如指掌',
        Icons.movie,
      ));
    }
    
    // 音乐回响者
    if (_checkCategoryMastery(testRecords, '音乐', 0.9) && 
        !_isAchievementUnlocked('音乐回响者', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '音乐回响者',
        '音乐分类正确率≥90%',
        '解锁音乐徽章+收藏夹容量+5题',
        '经典旋律在你心中回响',
        Icons.music_note,
      ));
    }
    
    // 时代见证者
    if (_checkCategoryMastery(testRecords, '事件', 0.9) && 
        !_isAchievementUnlocked('时代见证者', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '时代见证者',
        '事件分类正确率≥90%',
        '解锁事件徽章+收藏夹容量+5题',
        '你是那个时代的见证者',
        Icons.history,
      ));
    }
    
    return unlockedAchievements;
  }

  /// 检查高级成就
  Future<List<EchoAchievement>> _checkAdvancedAchievements(
    List<TestRecord> testRecords,
    List<EchoAchievement> currentAchievements,
  ) async {
    final unlockedAchievements = <EchoAchievement>[];
    
    // 拾光速答手
    if (_checkSpeedMastery(testRecords, 15) && 
        !_isAchievementUnlocked('拾光速答手', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光速答手',
        '单题平均耗时≤15秒',
        '解锁速答徽章+拾光年龄-1岁',
        '你的反应速度令人惊叹',
        Icons.speed,
      ));
    }
    
    // 拾光挑战者
    if (_checkDifficultyMastery(testRecords, '困难', 1.0) && 
        !_isAchievementUnlocked('拾光挑战者', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光挑战者',
        '困难题正确率100%',
        '解锁挑战徽章+拾光年龄-2岁',
        '你征服了最困难的挑战',
        Icons.emoji_events,
      ));
    }
    
    // 拾光收藏家
    if (_checkCollectionMastery(20) && 
        !_isAchievementUnlocked('拾光收藏家', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光收藏家',
        '收藏题目≥20道',
        '解锁收藏徽章+收藏夹容量+10题',
        '你是一个真正的收藏家',
        Icons.favorite,
      ));
    }
    
    // 拾光全勤人
    if (_checkStreakMastery(testRecords, 7) && 
        !_isAchievementUnlocked('拾光全勤人', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光全勤人',
        '连续7天每天拾光',
        '解锁全勤徽章+随机语录',
        '你的坚持令人敬佩',
        Icons.calendar_today,
      ));
    }
    
    return unlockedAchievements;
  }

  /// 检查特殊成就
  Future<List<EchoAchievement>> _checkSpecialAchievements(
    List<TestRecord> testRecords,
    List<EchoAchievement> currentAchievements,
  ) async {
    final unlockedAchievements = <EchoAchievement>[];
    
    // 拾光大师
    if (_checkOverallMastery(testRecords, 0.95) && 
        !_isAchievementUnlocked('拾光大师', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光大师',
        '总体正确率≥95%',
        '解锁大师徽章+特殊主题',
        '你是真正的拾光大师',
        Icons.school,
      ));
    }
    
    // 拾光夜猫子
    if (_checkNightOwl(testRecords) && 
        !_isAchievementUnlocked('拾光夜猫子', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光夜猫子',
        '在深夜时段完成拾光',
        '解锁夜猫子徽章+夜间主题',
        '夜晚的拾光者',
        Icons.nightlight_round,
      ));
    }
    
    // 拾光早起鸟
    if (_checkEarlyBird(testRecords) && 
        !_isAchievementUnlocked('拾光早起鸟', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光早起鸟',
        '在早晨时段完成拾光',
        '解锁早起鸟徽章+晨间主题',
        '清晨的拾光者',
        Icons.wb_sunny,
      ));
    }
    
    // 拾光完美主义者
    if (_checkPerfectScore(testRecords) && 
        !_isAchievementUnlocked('拾光完美主义者', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光完美主义者',
        '获得满分拾光',
        '解锁完美徽章+金色主题',
        '追求完美的拾光者',
        Icons.diamond,
      ));
    }
    
    return unlockedAchievements;
  }

  /// 检查连续成就
  Future<List<EchoAchievement>> _checkStreakAchievements(
    List<TestRecord> testRecords,
    List<EchoAchievement> currentAchievements,
  ) async {
    final unlockedAchievements = <EchoAchievement>[];
    
    // 拾光坚持者
    if (_checkStreakMastery(testRecords, 30) && 
        !_isAchievementUnlocked('拾光坚持者', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光坚持者',
        '连续30天每天拾光',
        '解锁坚持徽章+永久VIP',
        '你的坚持感动了时光',
        Icons.trending_up,
      ));
    }
    
    // 拾光马拉松
    if (_checkStreakMastery(testRecords, 100) && 
        !_isAchievementUnlocked('拾光马拉松', currentAchievements)) {
      unlockedAchievements.add(_createAchievement(
        '拾光马拉松',
        '连续100天每天拾光',
        '解锁马拉松徽章+传奇称号',
        '你是拾光界的传奇',
        Icons.flag,
      ));
    }
    
    return unlockedAchievements;
  }

  /// 检查分类精通
  bool _checkCategoryMastery(List<TestRecord> testRecords, String category, double threshold) {
    final categoryRecords = testRecords.where((record) => 
      record.categoryScores.containsKey(category)).toList();
    
    if (categoryRecords.isEmpty) return false;
    
    // categoryScores存储的是题目数量，不是百分比
    final totalQuestions = categoryRecords.fold<int>(0, (sum, record) => 
      sum + record.categoryScores[category]!);
    // 根据整体准确率估算该分类的正确数（accuracy是百分比格式，需要除以100）
    final correctAnswers = categoryRecords.fold<int>(0, (sum, record) {
      final accuracyRatio = (record.accuracy / 100).clamp(0.0, 1.0);
      return sum + (record.categoryScores[category]! * accuracyRatio).round();
    });
    
    return totalQuestions > 0 && (correctAnswers / totalQuestions) >= threshold;
  }

  /// 检查速度精通
  bool _checkSpeedMastery(List<TestRecord> testRecords, int maxSecondsPerQuestion) {
    if (testRecords.isEmpty) return false;
    
    final recentRecords = testRecords.take(5).toList();
    final totalTime = recentRecords.fold<int>(0, (sum, record) => sum + record.totalTime);
    final totalQuestions = recentRecords.fold<int>(0, (sum, record) => sum + record.totalQuestions);
    
    return totalQuestions > 0 && (totalTime / totalQuestions) <= maxSecondsPerQuestion;
  }

  /// 检查难度精通
  bool _checkDifficultyMastery(List<TestRecord> testRecords, String difficulty, double threshold) {
    // 这里需要根据实际的难度分类逻辑来实现
    return false; // 简化实现
  }

  /// 检查收藏精通
  bool _checkCollectionMastery(int minCount) {
    // 这里需要根据实际的收藏数据来实现
    return false; // 简化实现
  }

  /// 检查连续精通
  bool _checkStreakMastery(List<TestRecord> testRecords, int minDays) {
    if (testRecords.length < minDays) return false;
    
    // 检查连续天数
    final sortedRecords = testRecords.toList()
      ..sort((a, b) => b.testTime.compareTo(a.testTime));
    
    int currentStreak = 0;
    DateTime? lastDate;
    
    for (final record in sortedRecords) {
      final recordDate = DateTime(record.testTime.year, record.testTime.month, record.testTime.day);
      
      if (lastDate == null) {
        lastDate = recordDate;
        currentStreak = 1;
      } else if (recordDate.difference(lastDate).inDays == 1) {
        currentStreak++;
        lastDate = recordDate;
      } else if (recordDate.difference(lastDate).inDays > 1) {
        break;
      }
    }
    
    return currentStreak >= minDays;
  }

  /// 检查总体精通
  bool _checkOverallMastery(List<TestRecord> testRecords, double threshold) {
    if (testRecords.isEmpty) return false;
    
    final recentRecords = testRecords.take(10).toList();
    final averageAccuracy = recentRecords.fold<double>(0, (sum, record) => sum + record.accuracy) / recentRecords.length;
    
    return averageAccuracy >= threshold;
  }

  /// 检查夜猫子
  bool _checkNightOwl(List<TestRecord> testRecords) {
    return testRecords.any((record) => 
      record.testTime.hour >= 22 || record.testTime.hour <= 2);
  }

  /// 检查早起鸟
  bool _checkEarlyBird(List<TestRecord> testRecords) {
    return testRecords.any((record) => 
      record.testTime.hour >= 5 && record.testTime.hour <= 8);
  }

  /// 检查完美分数
  bool _checkPerfectScore(List<TestRecord> testRecords) {
    return testRecords.any((record) => record.accuracy == 1.0);
  }

  /// 检查成就是否已解锁
  bool _isAchievementUnlocked(String achievementName, List<EchoAchievement> achievements) {
    return achievements.any((achievement) => 
      achievement.achievementName == achievementName && achievement.isUnlocked);
  }

  /// 创建成就
  EchoAchievement _createAchievement(
    String name,
    String condition,
    String reward,
    String description,
    IconData icon,
  ) {
    return EchoAchievement(
      id: DateTime.now().millisecondsSinceEpoch,
      achievementName: name,
      achievementIcon: icon.codePoint.toString(),
      reward: reward,
      condition: condition,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
  }

  /// 获取成就进度
  Map<String, double> getAchievementProgress(
    List<TestRecord> testRecords,
    List<EchoAchievement> achievements,
  ) {
    final progress = <String, double>{};
    
    // 计算各种成就的进度
    progress['拾光初遇'] = testRecords.isNotEmpty ? 1.0 : 0.0;
    progress['影视拾光者'] = _getCategoryProgress(testRecords, '影视');
    progress['音乐回响者'] = _getCategoryProgress(testRecords, '音乐');
    progress['时代见证者'] = _getCategoryProgress(testRecords, '事件');
    progress['拾光速答手'] = _getSpeedProgress(testRecords);
    progress['拾光挑战者'] = _getDifficultyProgress(testRecords, '困难');
    progress['拾光收藏家'] = _getCollectionProgress();
    progress['拾光全勤人'] = _getStreakProgress(testRecords, 7);
    
    return progress;
  }

  /// 获取分类进度
  double _getCategoryProgress(List<TestRecord> testRecords, String category) {
    final categoryRecords = testRecords.where((record) => 
      record.categoryScores.containsKey(category)).toList();
    
    if (categoryRecords.isEmpty) return 0.0;
    
    // categoryScores存储的是题目数量，不是百分比
    final totalQuestions = categoryRecords.fold<int>(0, (sum, record) => 
      sum + record.categoryScores[category]!);
    // 根据整体准确率估算该分类的正确数（accuracy是百分比格式，需要除以100）
    final correctAnswers = categoryRecords.fold<int>(0, (sum, record) {
      final accuracyRatio = (record.accuracy / 100).clamp(0.0, 1.0);
      return sum + (record.categoryScores[category]! * accuracyRatio).round();
    });
    
    final progress = totalQuestions > 0 ? (correctAnswers / totalQuestions) / 0.9 : 0.0;
    return progress.clamp(0.0, 1.0);
  }

  /// 获取速度进度
  double _getSpeedProgress(List<TestRecord> testRecords) {
    if (testRecords.isEmpty) return 0.0;
    
    final recentRecords = testRecords.take(5).toList();
    final totalTime = recentRecords.fold<int>(0, (sum, record) => sum + record.totalTime);
    final totalQuestions = recentRecords.fold<int>(0, (sum, record) => sum + record.totalQuestions);
    
    if (totalQuestions == 0) return 0.0;
    
    final averageTime = totalTime / totalQuestions;
    return (15.0 / averageTime).clamp(0.0, 1.0);
  }

  /// 获取难度进度
  double _getDifficultyProgress(List<TestRecord> testRecords, String difficulty) {
    // 简化实现
    return 0.0;
  }

  /// 获取收藏进度
  double _getCollectionProgress() {
    // 简化实现
    return 0.0;
  }

  /// 获取连续进度
  double _getStreakProgress(List<TestRecord> testRecords, int targetDays) {
    if (testRecords.length < targetDays) return 0.0;
    
    final sortedRecords = testRecords.toList()
      ..sort((a, b) => b.testTime.compareTo(a.testTime));
    
    int currentStreak = 0;
    DateTime? lastDate;
    
    for (final record in sortedRecords) {
      final recordDate = DateTime(record.testTime.year, record.testTime.month, record.testTime.day);
      
      if (lastDate == null) {
        lastDate = recordDate;
        currentStreak = 1;
      } else if (recordDate.difference(lastDate).inDays == 1) {
        currentStreak++;
        lastDate = recordDate;
      } else if (recordDate.difference(lastDate).inDays > 1) {
        break;
      }
    }
    
    return (currentStreak / targetDays).clamp(0.0, 1.0);
  }
}
