import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../constants/app_constants.dart';
import '../services/offline_data_manager.dart';

/// 怀旧时光机体验服务
class NostalgicTimeMachineService {
  static final NostalgicTimeMachineService _instance = NostalgicTimeMachineService._internal();
  factory NostalgicTimeMachineService() => _instance;
  NostalgicTimeMachineService._internal();

  final OfflineDataManager _dataManager = OfflineDataManager();
  final Random _random = Random();

  /// 时光机主题
  static const Map<String, Map<String, dynamic>> timeMachineThemes = {
    '80s': {
      'name': '80年代',
      'color': 0xFF8B4513,
      'icon': Icons.music_note,
      'description': '回到那个充满活力的80年代',
      'background': 'assets/images/80s_bg.jpg',
      'music': 'assets/audio/80s_theme.mp3',
    },
    '90s': {
      'name': '90年代',
      'color': 0xFF4169E1,
      'icon': Icons.tv,
      'description': '重温90年代的经典时光',
      'background': 'assets/images/90s_bg.jpg',
      'music': 'assets/audio/90s_theme.mp3',
    },
    'retro': {
      'name': '复古风',
      'color': 0xFFDC143C,
      'icon': Icons.star,
      'description': '体验纯正的复古情怀',
      'background': 'assets/images/retro_bg.jpg',
      'music': 'assets/audio/retro_theme.mp3',
    },
  };

  /// 获取时光机主题
  Map<String, dynamic> getTimeMachineTheme(String themeId) {
    return timeMachineThemes[themeId] ?? timeMachineThemes['80s']!;
  }

  /// 获取所有主题
  List<Map<String, dynamic>> getAllThemes() {
    return timeMachineThemes.entries.map((entry) {
      final theme = entry.value;
      theme['id'] = entry.key;
      return theme;
    }).toList();
  }

  /// 生成时光机体验
  Future<TimeMachineExperience> generateTimeMachineExperience() async {
    final stats = await _dataManager.getStatistics();
    final testRecords = await _dataManager.getAllTestRecords();
    
    // 分析用户的时间偏好
    final timePreference = _analyzeTimePreference(testRecords);
    
    // 生成个性化体验
    final experience = TimeMachineExperience(
      theme: timePreference,
      personalizedContent: await _generatePersonalizedContent(stats, testRecords),
      timeJourney: await _generateTimeJourney(testRecords),
      nostalgicMoments: await _generateNostalgicMoments(stats),
      achievements: await _generateAchievementStory(testRecords),
    );
    
    return experience;
  }

  /// 分析时间偏好
  String _analyzeTimePreference(List<dynamic> testRecords) {
    if (testRecords.isEmpty) return '80s';
    
    // 分析用户答题的年份分布
    final yearCounts = <String, int>{};
    for (final record in testRecords) {
      // 这里应该根据实际数据结构来分析
      // 简化实现
      yearCounts['80s'] = (yearCounts['80s'] ?? 0) + 1;
    }
    
    // 找到最偏好的年代
    String preferredEra = '80s';
    int maxCount = 0;
    yearCounts.forEach((era, count) {
      if (count > maxCount) {
        maxCount = count;
        preferredEra = era;
      }
    });
    
    return preferredEra;
  }

  /// 生成个性化内容
  Future<PersonalizedContent> _generatePersonalizedContent(
    Map<String, dynamic> stats,
    List<dynamic> testRecords,
  ) async {
    final totalTests = stats['total_tests'] ?? 0;
    final bestAccuracy = stats['best_accuracy'] ?? 0.0;
    final unlockedAchievements = stats['unlocked_achievements'] ?? 0;
    
    // 生成个性化评语
    String personalizedComment;
    if (totalTests == 0) {
      personalizedComment = '欢迎来到拾光机！让我们一起踏上时光之旅。';
    } else if (bestAccuracy >= 0.9) {
      personalizedComment = '你是真正的时光大师！对那个年代了如指掌。';
    } else if (bestAccuracy >= 0.7) {
      personalizedComment = '你对那个年代有着深刻的理解，继续探索吧！';
    } else {
      personalizedComment = '每一次拾光都是时光的重新发现，加油！';
    }
    
    // 生成学习建议
    final suggestions = _generateLearningSuggestions(stats, testRecords);
    
    // 生成推荐内容
    final recommendations = await _generateRecommendations(stats);
    
    return PersonalizedContent(
      comment: personalizedComment,
      suggestions: suggestions,
      recommendations: recommendations,
      learningPath: _generateLearningPath(stats),
    );
  }

  /// 生成学习建议
  List<String> _generateLearningSuggestions(
    Map<String, dynamic> stats,
    List<dynamic> testRecords,
  ) {
    final suggestions = <String>[];
    
    final totalTests = stats['total_tests'] ?? 0;
    final bestAccuracy = stats['best_accuracy'] ?? 0.0;
    
    if (totalTests < 5) {
      suggestions.add('多进行拾光，熟悉不同年代的题目');
      suggestions.add('尝试不同分类的题目，拓宽知识面');
    } else if (bestAccuracy < 0.6) {
      suggestions.add('重点关注薄弱分类，加强练习');
      suggestions.add('可以尝试简单难度的题目，建立信心');
    } else if (bestAccuracy < 0.8) {
      suggestions.add('挑战中等难度题目，提升技能');
      suggestions.add('关注题目解析，加深理解');
    } else {
      suggestions.add('挑战困难题目，成为真正的时光专家');
      suggestions.add('分享你的知识，帮助其他时光旅行者');
    }
    
    return suggestions;
  }

  /// 生成推荐内容
  Future<List<String>> _generateRecommendations(Map<String, dynamic> stats) async {
    final recommendations = <String>[];
    
    final unlockedAchievements = stats['unlocked_achievements'] ?? 0;
    final totalTests = stats['total_tests'] ?? 0;
    
    if (unlockedAchievements < 3) {
      recommendations.add('解锁更多成就，获得特殊奖励');
    }
    
    if (totalTests < 10) {
      recommendations.add('完成10次拾光，解锁连续成就');
    }
    
    recommendations.add('收藏喜欢的题目，建立个人时光收藏夹');
    recommendations.add('尝试挑战模式，拾光你的极限');
    
    return recommendations;
  }

  /// 生成学习路径
  LearningPath _generateLearningPath(Map<String, dynamic> stats) {
    final totalTests = stats['total_tests'] ?? 0;
    final bestAccuracy = stats['best_accuracy'] ?? 0.0;
    
    if (totalTests < 5) {
      return LearningPath(
        stage: '初学者',
        description: '开始你的时光之旅',
        nextGoal: '完成5次拾光',
        progress: totalTests / 5,
      );
    } else if (totalTests < 20) {
      return LearningPath(
        stage: '探索者',
        description: '深入探索不同年代',
        nextGoal: '完成20次拾光',
        progress: totalTests / 20,
      );
    } else if (bestAccuracy < 0.8) {
      return LearningPath(
        stage: '学习者',
        description: '提升你的时光知识',
        nextGoal: '达到80%准确率',
        progress: bestAccuracy / 0.8,
      );
    } else {
      return LearningPath(
        stage: '时光大师',
        description: '你已经掌握了时光的秘密',
        nextGoal: '解锁所有成就',
        progress: (stats['unlocked_achievements'] ?? 0) / 8,
      );
    }
  }

  /// 生成时光之旅
  Future<TimeJourney> _generateTimeJourney(List<dynamic> testRecords) async {
    final journey = <TimeJourneyStep>[];
    
    // 根据拾光记录生成时光之旅步骤
    for (int i = 0; i < testRecords.length && i < 10; i++) {
      final record = testRecords[i];
      final testTime = DateTime.parse(record['test_time']);
      // accuracy从数据库读取，是百分比格式（0-100）
      final accuracy = (record['accuracy'] as double).clamp(0.0, 100.0);
      final accuracyRatio = accuracy / 100.0; // 转换为小数格式用于比较
      
      journey.add(TimeJourneyStep(
        date: testTime,
        title: '时光拾光 ${i + 1}',
        description: '准确率: ${accuracy.toInt()}%',
        achievement: accuracyRatio >= 0.8 ? '优秀' : accuracyRatio >= 0.6 ? '良好' : '继续努力',
        icon: _getJourneyIcon(accuracyRatio),
        color: _getJourneyColor(accuracyRatio),
      ));
    }
    
    return TimeJourney(
      steps: journey,
      totalSteps: testRecords.length,
      completedSteps: journey.length,
    );
  }

  /// 生成怀旧时刻
  Future<List<NostalgicMoment>> _generateNostalgicMoments(Map<String, dynamic> stats) async {
    final moments = <NostalgicMoment>[];
    
    // 基于统计数据生成怀旧时刻
    final totalTests = stats['total_tests'] ?? 0;
    final bestAccuracy = stats['best_accuracy'] ?? 0.0;
    final unlockedAchievements = stats['unlocked_achievements'] ?? 0;
    
    if (totalTests > 0) {
      moments.add(NostalgicMoment(
        title: '第一次时光拾光',
        description: '你开始了这段美妙的时光之旅',
        date: DateTime.now().subtract(Duration(days: totalTests)),
        icon: Icons.star,
        color: Colors.yellow,
      ));
    }
    
    if (bestAccuracy >= 0.9) {
      moments.add(NostalgicMoment(
        title: '时光大师时刻',
        description: '你展现了对那个年代的深刻理解',
        date: DateTime.now(),
        icon: Icons.emoji_events,
        color: Colors.orange,
      ));
    }
    
    if (unlockedAchievements > 0) {
      moments.add(NostalgicMoment(
        title: '成就解锁',
        description: '你解锁了 $unlockedAchievements 个成就',
        date: DateTime.now(),
        icon: Icons.celebration,
        color: Colors.purple,
      ));
    }
    
    return moments;
  }

  /// 生成成就故事
  Future<AchievementStory> _generateAchievementStory(List<dynamic> testRecords) async {
    final achievements = await _dataManager.getAllAchievements();
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
    
    return AchievementStory(
      totalAchievements: achievements.length,
      unlockedAchievements: unlockedAchievements.length,
      recentAchievements: unlockedAchievements.take(3).map((a) => a.toMap()).toList(),
      nextAchievements: achievements.where((a) => !a.isUnlocked).take(3).map((a) => a.toMap()).toList(),
    );
  }

  /// 获取旅程图标
  IconData _getJourneyIcon(double accuracy) {
    if (accuracy >= 0.8) return Icons.star;
    if (accuracy >= 0.6) return Icons.check_circle;
    return Icons.radio_button_unchecked;
  }

  /// 获取旅程颜色
  Color _getJourneyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.grey;
  }

  /// 生成时光机音效
  Future<void> playTimeMachineSound() async {
    // 播放时光机音效
    HapticFeedback.mediumImpact();
  }

  /// 生成怀旧氛围
  Future<Map<String, dynamic>> generateNostalgicAtmosphere() async {
    return {
      'backgroundMusic': 'assets/audio/nostalgic_bg.mp3',
      'ambientSounds': [
        'assets/audio/80s_ambient.mp3',
        'assets/audio/90s_ambient.mp3',
      ],
      'visualEffects': [
        'vintage_filter',
        'grain_texture',
        'retro_colors',
      ],
      'interactiveElements': [
        'time_travel_animation',
        'memory_flash',
        'nostalgic_transition',
      ],
    };
  }
}

/// 时光机体验数据模型
class TimeMachineExperience {
  final String theme;
  final PersonalizedContent personalizedContent;
  final TimeJourney timeJourney;
  final List<NostalgicMoment> nostalgicMoments;
  final AchievementStory achievements;

  TimeMachineExperience({
    required this.theme,
    required this.personalizedContent,
    required this.timeJourney,
    required this.nostalgicMoments,
    required this.achievements,
  });
}

/// 个性化内容
class PersonalizedContent {
  final String comment;
  final List<String> suggestions;
  final List<String> recommendations;
  final LearningPath learningPath;

  PersonalizedContent({
    required this.comment,
    required this.suggestions,
    required this.recommendations,
    required this.learningPath,
  });
}

/// 学习路径
class LearningPath {
  final String stage;
  final String description;
  final String nextGoal;
  final double progress;

  LearningPath({
    required this.stage,
    required this.description,
    required this.nextGoal,
    required this.progress,
  });
}

/// 时光之旅
class TimeJourney {
  final List<TimeJourneyStep> steps;
  final int totalSteps;
  final int completedSteps;

  TimeJourney({
    required this.steps,
    required this.totalSteps,
    required this.completedSteps,
  });
}

/// 时光之旅步骤
class TimeJourneyStep {
  final DateTime date;
  final String title;
  final String description;
  final String achievement;
  final IconData icon;
  final Color color;

  TimeJourneyStep({
    required this.date,
    required this.title,
    required this.description,
    required this.achievement,
    required this.icon,
    required this.color,
  });
}

/// 怀旧时刻
class NostalgicMoment {
  final String title;
  final String description;
  final DateTime date;
  final IconData icon;
  final Color color;

  NostalgicMoment({
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    required this.color,
  });
}

/// 成就故事
class AchievementStory {
  final int totalAchievements;
  final int unlockedAchievements;
  final List<Map<String, dynamic>> recentAchievements;
  final List<Map<String, dynamic>> nextAchievements;

  AchievementStory({
    required this.totalAchievements,
    required this.unlockedAchievements,
    required this.recentAchievements,
    required this.nextAchievements,
  });
}
