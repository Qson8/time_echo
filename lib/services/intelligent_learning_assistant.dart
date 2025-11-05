import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../constants/app_constants.dart';
import '../services/offline_data_manager.dart';
import '../widgets/animated_widgets.dart';

/// 智能学习助手系统
class IntelligentLearningAssistant {
  static final IntelligentLearningAssistant _instance = IntelligentLearningAssistant._internal();
  factory IntelligentLearningAssistant() => _instance;
  IntelligentLearningAssistant._internal();

  final OfflineDataManager _dataManager = OfflineDataManager();
  final Random _random = Random();

  /// 生成个性化学习计划
  Future<PersonalizedLearningPlan> generateLearningPlan() async {
    final stats = await _dataManager.getStatistics();
    final testRecords = await _dataManager.getAllTestRecords();
    final achievements = await _dataManager.getAllAchievements();
    
    // 分析学习模式
    final learningPattern = _analyzeLearningPattern(testRecords);
    
    // 生成学习目标
    final learningGoals = _generateLearningGoals(stats, achievements);
    
    // 生成学习路径
    final learningPath = _generateLearningPath(stats, learningPattern);
    
    // 生成学习建议
    final suggestions = _generateLearningSuggestions(stats, learningPattern);
    
    return PersonalizedLearningPlan(
      goals: learningGoals,
      path: learningPath,
      suggestions: suggestions,
      pattern: learningPattern,
      estimatedCompletion: _estimateCompletion(stats, learningGoals),
    );
  }

  /// 分析学习模式
  LearningPattern _analyzeLearningPattern(List<dynamic> testRecords) {
    if (testRecords.isEmpty) {
      return LearningPattern(
        preferredTime: 'morning',
        averageSessionDuration: 0,
        difficultyPreference: 'medium',
        categoryStrength: {},
        learningStyle: 'visual',
        motivationLevel: 'high',
      );
    }

    // 分析时间偏好
    final timeCounts = <String, int>{};
    final sessionDurations = <int>[];
    final difficultyCounts = <String, int>{};
    final categoryScores = <String, List<double>>{};

    for (final record in testRecords) {
      final testTime = DateTime.parse(record['test_time']);
      final hour = testTime.hour;
      
      // 时间偏好分析
      String timeSlot;
      if (hour >= 6 && hour < 12) {
        timeSlot = 'morning';
      } else if (hour >= 12 && hour < 18) {
        timeSlot = 'afternoon';
      } else if (hour >= 18 && hour < 22) {
        timeSlot = 'evening';
      } else {
        timeSlot = 'night';
      }
      timeCounts[timeSlot] = (timeCounts[timeSlot] ?? 0) + 1;
      
      // 会话时长分析
      sessionDurations.add(record['total_time']);
      
      // 难度偏好分析（简化）
      difficultyCounts['medium'] = (difficultyCounts['medium'] ?? 0) + 1;
      
      // 分类表现分析
      final categoryScoresData = record['category_scores'] as Map<String, dynamic>;
      categoryScoresData.forEach((category, score) {
        categoryScores.putIfAbsent(category, () => []).add(score.toDouble());
      });
    }

    // 找到最偏好时间
    String preferredTime = 'morning';
    int maxCount = 0;
    timeCounts.forEach((time, count) {
      if (count > maxCount) {
        maxCount = count;
        preferredTime = time;
      }
    });

    // 计算平均会话时长
    final averageSessionDuration = sessionDurations.isNotEmpty
        ? sessionDurations.reduce((a, b) => a + b) / sessionDurations.length
        : 0;

    // 分析分类强度
    final categoryStrength = <String, double>{};
    categoryScores.forEach((category, scores) {
      if (scores.isNotEmpty) {
        categoryStrength[category] = scores.reduce((a, b) => a + b) / scores.length;
      }
    });

    return LearningPattern(
      preferredTime: preferredTime,
      averageSessionDuration: averageSessionDuration.round(),
      difficultyPreference: 'medium',
      categoryStrength: categoryStrength,
      learningStyle: _determineLearningStyle(testRecords),
      motivationLevel: _assessMotivationLevel(testRecords),
    );
  }

  /// 确定学习风格
  String _determineLearningStyle(List<dynamic> testRecords) {
    if (testRecords.isEmpty) return 'visual';
    
    // 基于测试记录分析学习风格
    // 简化实现
    return 'visual';
  }

  /// 评估动机水平
  String _assessMotivationLevel(List<dynamic> testRecords) {
    if (testRecords.isEmpty) return 'high';
    
    final recentTests = testRecords.take(7).toList();
    if (recentTests.length >= 5) return 'high';
    if (recentTests.length >= 3) return 'medium';
    return 'low';
  }

  /// 生成学习目标
  List<LearningGoal> _generateLearningGoals(
    Map<String, dynamic> stats,
    List<dynamic> achievements,
  ) {
    final goals = <LearningGoal>[];
    
    final totalTests = stats['total_tests'] ?? 0;
    final bestAccuracy = stats['best_accuracy'] ?? 0.0;
    final unlockedAchievements = stats['unlocked_achievements'] ?? 0;
    
    // 短期目标（1-2周）
    if (totalTests < 10) {
      goals.add(LearningGoal(
        title: '完成10次测试',
        description: '建立学习习惯',
        target: 10,
        current: totalTests,
        deadline: DateTime.now().add(const Duration(days: 14)),
        priority: 'high',
        category: 'consistency',
      ));
    }
    
    if (bestAccuracy < 0.8) {
      goals.add(LearningGoal(
        title: '达到80%准确率',
        description: '提升答题准确率',
        target: 80,
        current: (bestAccuracy * 100).toInt(),
        deadline: DateTime.now().add(const Duration(days: 21)),
        priority: 'high',
        category: 'accuracy',
      ));
    }
    
    // 中期目标（1个月）
    if (unlockedAchievements < 5) {
      goals.add(LearningGoal(
        title: '解锁5个成就',
        description: '完成更多挑战',
        target: 5,
        current: unlockedAchievements,
        deadline: DateTime.now().add(const Duration(days: 30)),
        priority: 'medium',
        category: 'achievement',
      ));
    }
    
    // 长期目标（3个月）
    goals.add(LearningGoal(
      title: '成为时光大师',
      description: '掌握所有分类知识',
      target: 100,
      current: (bestAccuracy * 100).toInt(),
      deadline: DateTime.now().add(const Duration(days: 90)),
      priority: 'low',
      category: 'mastery',
    ));
    
    return goals;
  }

  /// 生成学习路径
  LearningPath _generateLearningPath(
    Map<String, dynamic> stats,
    LearningPattern pattern,
  ) {
    final totalTests = stats['total_tests'] ?? 0;
    final bestAccuracy = stats['best_accuracy'] ?? 0.0;
    
    List<LearningStep> steps = [];
    
    if (totalTests < 5) {
      steps.add(LearningStep(
        title: '基础学习',
        description: '熟悉不同分类的题目',
        duration: '1-2周',
        difficulty: 'easy',
        category: 'foundation',
      ));
    }
    
    if (bestAccuracy < 0.7) {
      steps.add(LearningStep(
        title: '技能提升',
        description: '提高答题准确率',
        duration: '2-3周',
        difficulty: 'medium',
        category: 'skill',
      ));
    }
    
    if (bestAccuracy >= 0.7) {
      steps.add(LearningStep(
        title: '高级挑战',
        description: '挑战困难题目',
        duration: '3-4周',
        difficulty: 'hard',
        category: 'challenge',
      ));
    }
    
    steps.add(LearningStep(
      title: '大师之路',
      description: '成为真正的时光专家',
      duration: '持续',
      difficulty: 'expert',
      category: 'mastery',
    ));
    
    return LearningPath(
      steps: steps,
      currentStep: _getCurrentStepIndex(stats),
      totalSteps: steps.length,
    );
  }

  /// 获取当前步骤索引
  int _getCurrentStepIndex(Map<String, dynamic> stats) {
    final totalTests = stats['total_tests'] ?? 0;
    final bestAccuracy = stats['best_accuracy'] ?? 0.0;
    
    if (totalTests < 5) return 0;
    if (bestAccuracy < 0.7) return 1;
    if (bestAccuracy < 0.9) return 2;
    return 3;
  }

  /// 生成学习建议
  List<LearningSuggestion> _generateLearningSuggestions(
    Map<String, dynamic> stats,
    LearningPattern pattern,
  ) {
    final suggestions = <LearningSuggestion>[];
    
    // 基于学习模式生成建议
    if (pattern.preferredTime == 'morning') {
      suggestions.add(LearningSuggestion(
        title: '晨间学习',
        description: '利用早晨的黄金时间进行学习',
        type: 'schedule',
        priority: 'high',
        icon: Icons.wb_sunny,
      ));
    }
    
    if (pattern.averageSessionDuration < 300) {
      suggestions.add(LearningSuggestion(
        title: '延长学习时间',
        description: '适当延长每次学习时间，提高学习效果',
        type: 'duration',
        priority: 'medium',
        icon: Icons.timer,
      ));
    }
    
    // 基于分类强度生成建议
    pattern.categoryStrength.forEach((category, strength) {
      if (strength < 0.6) {
        suggestions.add(LearningSuggestion(
          title: '加强$category分类',
          description: '在$category分类上多下功夫',
          type: 'category',
          priority: 'high',
          icon: Icons.school,
        ));
      }
    });
    
    // 通用建议
    suggestions.add(LearningSuggestion(
      title: '定期复习',
      description: '定期回顾错题，巩固知识点',
      type: 'review',
      priority: 'medium',
      icon: Icons.refresh,
    ));
    
    return suggestions;
  }

  /// 估算完成时间
  Duration _estimateCompletion(
    Map<String, dynamic> stats,
    List<LearningGoal> goals,
  ) {
    final totalTests = stats['total_tests'] ?? 0;
    final bestAccuracy = stats['best_accuracy'] ?? 0.0;
    
    // 基于当前进度估算
    int estimatedDays = 30; // 默认30天
    
    if (totalTests < 5) {
      estimatedDays = 45;
    } else if (bestAccuracy < 0.7) {
      estimatedDays = 30;
    } else if (bestAccuracy < 0.9) {
      estimatedDays = 20;
    } else {
      estimatedDays = 10;
    }
    
    return Duration(days: estimatedDays);
  }

  /// 生成每日学习提醒
  Future<DailyLearningReminder> generateDailyReminder() async {
    final stats = await _dataManager.getStatistics();
    final testRecords = await _dataManager.getAllTestRecords();
    
    final pattern = _analyzeLearningPattern(testRecords);
    final today = DateTime.now();
    
    // 生成今日学习任务
    final tasks = _generateDailyTasks(stats, pattern);
    
    // 生成激励语句
    final motivation = _generateMotivation(stats);
    
    // 生成学习提示
    final tips = _generateLearningTips(pattern);
    
    return DailyLearningReminder(
      date: today,
      tasks: tasks,
      motivation: motivation,
      tips: tips,
      estimatedDuration: pattern.averageSessionDuration,
      bestTime: pattern.preferredTime,
    );
  }

  /// 生成每日任务
  List<DailyTask> _generateDailyTasks(
    Map<String, dynamic> stats,
    LearningPattern pattern,
  ) {
    final tasks = <DailyTask>[];
    
    final totalTests = stats['total_tests'] ?? 0;
    final bestAccuracy = stats['best_accuracy'] ?? 0.0;
    
    if (totalTests < 10) {
      tasks.add(DailyTask(
        title: '完成1次测试',
        description: '保持学习习惯',
        estimatedTime: 5,
        priority: 'high',
        category: 'test',
      ));
    }
    
    if (bestAccuracy < 0.8) {
      tasks.add(DailyTask(
        title: '复习错题',
        description: '回顾之前的错误答案',
        estimatedTime: 10,
        priority: 'medium',
        category: 'review',
      ));
    }
    
    tasks.add(DailyTask(
      title: '探索新题目',
      description: '发现更多怀旧内容',
      estimatedTime: 15,
      priority: 'low',
      category: 'explore',
    ));
    
    return tasks;
  }

  /// 生成激励语句
  String _generateMotivation(Map<String, dynamic> stats) {
    final totalTests = stats['total_tests'] ?? 0;
    final bestAccuracy = stats['best_accuracy'] ?? 0.0;
    
    if (totalTests == 0) {
      return '开始你的时光之旅，每一份记忆都值得珍藏！';
    } else if (bestAccuracy >= 0.9) {
      return '你是真正的时光大师！继续保持这份热情！';
    } else if (bestAccuracy >= 0.7) {
      return '你的进步令人印象深刻，继续加油！';
    } else {
      return '每一次学习都是成长，坚持下去！';
    }
  }

  /// 生成学习提示
  List<String> _generateLearningTips(LearningPattern pattern) {
    final tips = <String>[];
    
    tips.add('选择安静的环境进行学习');
    tips.add('保持专注，避免分心');
    
    if (pattern.preferredTime == 'morning') {
      tips.add('早晨是学习的黄金时间');
    } else if (pattern.preferredTime == 'evening') {
      tips.add('晚上学习时注意休息');
    }
    
    tips.add('定期回顾学习内容');
    tips.add('保持积极的学习态度');
    
    return tips;
  }
}

/// 个性化学习计划
class PersonalizedLearningPlan {
  final List<LearningGoal> goals;
  final LearningPath path;
  final List<LearningSuggestion> suggestions;
  final LearningPattern pattern;
  final Duration estimatedCompletion;

  PersonalizedLearningPlan({
    required this.goals,
    required this.path,
    required this.suggestions,
    required this.pattern,
    required this.estimatedCompletion,
  });
}

/// 学习模式
class LearningPattern {
  final String preferredTime;
  final int averageSessionDuration;
  final String difficultyPreference;
  final Map<String, double> categoryStrength;
  final String learningStyle;
  final String motivationLevel;

  LearningPattern({
    required this.preferredTime,
    required this.averageSessionDuration,
    required this.difficultyPreference,
    required this.categoryStrength,
    required this.learningStyle,
    required this.motivationLevel,
  });
}

/// 学习目标
class LearningGoal {
  final String title;
  final String description;
  final int target;
  final int current;
  final DateTime deadline;
  final String priority;
  final String category;

  LearningGoal({
    required this.title,
    required this.description,
    required this.target,
    required this.current,
    required this.deadline,
    required this.priority,
    required this.category,
  });
}

/// 学习路径
class LearningPath {
  final List<LearningStep> steps;
  final int currentStep;
  final int totalSteps;

  LearningPath({
    required this.steps,
    required this.currentStep,
    required this.totalSteps,
  });
}

/// 学习步骤
class LearningStep {
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final String category;

  LearningStep({
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.category,
  });
}

/// 学习建议
class LearningSuggestion {
  final String title;
  final String description;
  final String type;
  final String priority;
  final IconData icon;

  LearningSuggestion({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.icon,
  });
}

/// 每日学习提醒
class DailyLearningReminder {
  final DateTime date;
  final List<DailyTask> tasks;
  final String motivation;
  final List<String> tips;
  final int estimatedDuration;
  final String bestTime;

  DailyLearningReminder({
    required this.date,
    required this.tasks,
    required this.motivation,
    required this.tips,
    required this.estimatedDuration,
    required this.bestTime,
  });
}

/// 每日任务
class DailyTask {
  final String title;
  final String description;
  final int estimatedTime;
  final String priority;
  final String category;

  DailyTask({
    required this.title,
    required this.description,
    required this.estimatedTime,
    required this.priority,
    required this.category,
  });
}
