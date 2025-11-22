import 'dart:math';
import '../models/question.dart';
import '../models/test_record.dart';
import '../services/personalization_service.dart';

/// 智能推荐系统
class IntelligentRecommendationSystem {
  static final IntelligentRecommendationSystem _instance = IntelligentRecommendationSystem._internal();
  factory IntelligentRecommendationSystem() => _instance;
  IntelligentRecommendationSystem._internal();

  final PersonalizationService _personalizationService = PersonalizationService();
  final Random _random = Random();

  /// 根据用户历史表现推荐题目
  List<Question> recommendQuestionsByPerformance(
    List<Question> availableQuestions,
    List<TestRecord> testRecords,
    int count,
  ) {
    if (availableQuestions.isEmpty) return [];

    // 分析用户表现
    final performanceAnalysis = _analyzeUserPerformance(testRecords);
    
    // 根据表现推荐题目
    final recommendedQuestions = <Question>[];
    
    // 1. 推荐薄弱分类的题目
    final weakCategories = performanceAnalysis['weakCategories'] as List<String>;
    for (final category in weakCategories) {
      final categoryQuestions = availableQuestions
          .where((q) => q.category == category)
          .toList();
      recommendedQuestions.addAll(categoryQuestions.take(2));
    }
    
    // 2. 推荐中等难度的题目
    final mediumDifficultyQuestions = availableQuestions
        .where((q) => q.difficulty == '中等')
        .toList();
    recommendedQuestions.addAll(mediumDifficultyQuestions.take(3));
    
    // 3. 推荐用户偏好的题目类型
    final userTags = _personalizationService.getUserTags();
    for (final tag in userTags) {
      final tagQuestions = availableQuestions
          .where((q) => q.echoTheme.contains(tag))
          .toList();
      recommendedQuestions.addAll(tagQuestions.take(1));
    }
    
    // 4. 智能难度调节
    final difficultyLevel = _calculateOptimalDifficulty(testRecords);
    final difficultyQuestions = availableQuestions
        .where((q) => q.difficulty == difficultyLevel)
        .toList();
    recommendedQuestions.addAll(difficultyQuestions.take(2));
    
    // 5. 时间偏好推荐
    final timePreference = _analyzeTimePreference(testRecords);
    if (timePreference != null) {
      final timeBasedQuestions = availableQuestions
          .where((q) => _matchesTimePreference(q, timePreference))
          .toList();
      recommendedQuestions.addAll(timeBasedQuestions.take(1));
    }
    
    // 6. 如果推荐题目不足，随机补充
    if (recommendedQuestions.length < count) {
      final remainingQuestions = availableQuestions
          .where((q) => !recommendedQuestions.contains(q))
          .toList();
      recommendedQuestions.addAll(remainingQuestions.take(count - recommendedQuestions.length));
    }
    
    // 打乱顺序并返回指定数量
    recommendedQuestions.shuffle(_random);
    return recommendedQuestions.take(count).toList();
  }

  /// 计算最优难度级别
  String _calculateOptimalDifficulty(List<TestRecord> testRecords) {
    if (testRecords.isEmpty) return '中等';
    
    // 计算最近5次拾光的平均准确率
    final recentRecords = testRecords.take(5).toList();
    final averageAccuracy = recentRecords.map((r) => r.accuracy).reduce((a, b) => a + b) / recentRecords.length;
    
    if (averageAccuracy >= 0.9) {
      return '困难';
    } else if (averageAccuracy >= 0.7) {
      return '中等';
    } else {
      return '简单';
    }
  }

  /// 分析时间偏好
  String? _analyzeTimePreference(List<TestRecord> testRecords) {
    if (testRecords.isEmpty) return null;
    
    // 分析用户在不同时间段的表现
    final Map<String, List<double>> timePerformance = {};
    
    for (final record in testRecords) {
      final hour = record.testTime.hour;
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
      
      timePerformance.putIfAbsent(timeSlot, () => []).add(record.accuracy);
    }
    
    // 找到表现最好的时间段
    String? bestTimeSlot;
    double bestPerformance = 0.0;
    
    timePerformance.forEach((slot, performances) {
      final averagePerformance = performances.reduce((a, b) => a + b) / performances.length;
      if (averagePerformance > bestPerformance) {
        bestPerformance = averagePerformance;
        bestTimeSlot = slot;
      }
    });
    
    return bestTimeSlot;
  }

  /// 检查题目是否匹配时间偏好
  bool _matchesTimePreference(Question question, String timePreference) {
    // 根据题目的echoTheme和时间偏好进行匹配
    // 这里可以根据具体的业务逻辑来实现
    return true; // 简化实现
  }

  /// 基于协同过滤的推荐
  List<Question> recommendByCollaborativeFiltering(
    List<Question> availableQuestions,
    List<TestRecord> userRecords,
    List<TestRecord> allUsersRecords,
    int count,
  ) {
    if (availableQuestions.isEmpty || userRecords.isEmpty) return [];

    // 找到相似用户
    final similarUsers = _findSimilarUsers(userRecords, allUsersRecords);
    
    // 基于相似用户的偏好推荐题目
    final recommendedQuestions = <Question>[];
    
    for (final similarUser in similarUsers) {
      final userQuestions = _getUserPreferredQuestions(similarUser, availableQuestions);
      recommendedQuestions.addAll(userQuestions.take(2));
    }
    
    return recommendedQuestions.take(count).toList();
  }

  /// 找到相似用户
  List<Map<String, dynamic>> _findSimilarUsers(
    List<TestRecord> userRecords,
    List<TestRecord> allUsersRecords,
  ) {
    // 简化的相似度计算
    final similarUsers = <Map<String, dynamic>>[];
    
    // 这里应该实现更复杂的相似度算法
    // 比如基于答题模式、准确率、时间偏好等
    
    return similarUsers;
  }

  /// 获取用户偏好的题目
  List<Question> _getUserPreferredQuestions(
    Map<String, dynamic> user,
    List<Question> availableQuestions,
  ) {
    // 根据用户历史表现返回偏好题目
    return availableQuestions.take(3).toList();
  }

  /// 实时推荐更新
  void updateRecommendationsInRealTime(
    Question currentQuestion,
    int userAnswer,
    int answerTime,
  ) {
    // 实时更新推荐算法
    _personalizationService.updateUserBehavior(currentQuestion, userAnswer.toString(), answerTime.toString());
  }

  /// 分析用户表现
  Map<String, dynamic> _analyzeUserPerformance(List<TestRecord> testRecords) {
    if (testRecords.isEmpty) {
      return {
        'weakCategories': <String>[],
        'strongCategories': <String>[],
        'averageAccuracy': 0.0,
        'averageTime': 0.0,
      };
    }

    final categoryScores = <String, List<double>>{};
    double totalAccuracy = 0.0;
    double totalTime = 0.0;

    for (final record in testRecords) {
      totalAccuracy += record.accuracy;
      totalTime += record.totalTime;

      if (record.categoryScores != null) {
        for (final entry in record.categoryScores!.entries) {
          categoryScores.putIfAbsent(entry.key, () => []).add(entry.value.toDouble());
        }
      }
    }

    final averageAccuracy = totalAccuracy / testRecords.length;
    final averageTime = totalTime / testRecords.length;

    // 找出薄弱和强势分类
    final weakCategories = <String>[];
    final strongCategories = <String>[];

    for (final entry in categoryScores.entries) {
      final categoryAverage = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (categoryAverage < averageAccuracy - 10) {
        weakCategories.add(entry.key);
      } else if (categoryAverage > averageAccuracy + 10) {
        strongCategories.add(entry.key);
      }
    }

    return {
      'weakCategories': weakCategories,
      'strongCategories': strongCategories,
      'averageAccuracy': averageAccuracy,
      'averageTime': averageTime,
    };
  }

  /// 根据学习目标推荐学习计划
  Map<String, dynamic> recommendLearningPlan() {
    final learningGoal = _personalizationService.getLearningGoal();
    if (learningGoal == null) {
      return _getDefaultLearningPlan();
    }

    final goalType = learningGoal['period'] as String;
    final target = learningGoal['target'] as int;

    switch (goalType) {
      case 'daily':
        return _getDailyPlan(target);
      case 'weekly':
        return _getWeeklyPlan(target);
      case 'monthly':
        return _getMonthlyPlan(target);
      case 'continuous':
        return _getContinuousPlan(target);
      default:
        return _getDefaultLearningPlan();
    }
  }

  /// 获取每日学习计划
  Map<String, dynamic> _getDailyPlan(int target) {
    return {
      'type': 'daily',
      'target': target,
      'schedule': [
        {'time': '09:00', 'activity': '晨练答题', 'questions': (target * 0.3).round()},
        {'time': '14:00', 'activity': '午后复习', 'questions': (target * 0.4).round()},
        {'time': '19:00', 'activity': '晚间巩固', 'questions': (target * 0.3).round()},
      ],
      'tips': [
        '建议在精神状态最佳时进行答题',
        '保持专注，避免外界干扰',
        '及时复习错题，加深印象',
      ],
    };
  }

  /// 获取每周学习计划
  Map<String, dynamic> _getWeeklyPlan(int target) {
    final dailyTarget = (target / 7).round();
    return {
      'type': 'weekly',
      'target': target,
      'dailyTarget': dailyTarget,
      'schedule': [
        {'day': '周一', 'focus': '影视类题目', 'questions': dailyTarget},
        {'day': '周二', 'focus': '音乐类题目', 'questions': dailyTarget},
        {'day': '周三', 'focus': '事件类题目', 'questions': dailyTarget},
        {'day': '周四', 'focus': '综合复习', 'questions': dailyTarget},
        {'day': '周五', 'focus': '难点突破', 'questions': dailyTarget},
        {'day': '周六', 'focus': '轻松练习', 'questions': dailyTarget},
        {'day': '周日', 'focus': '总结回顾', 'questions': dailyTarget},
      ],
      'tips': [
        '合理安排每日学习时间',
        '注意劳逸结合，避免疲劳',
        '定期总结学习成果',
      ],
    };
  }

  /// 获取每月学习计划
  Map<String, dynamic> _getMonthlyPlan(int target) {
    final weeklyTarget = (target / 4).round();
    final dailyTarget = (target / 30).round();
    return {
      'type': 'monthly',
      'target': target,
      'weeklyTarget': weeklyTarget,
      'dailyTarget': dailyTarget,
      'phases': [
        {'week': 1, 'focus': '基础巩固', 'description': '重点复习基础知识'},
        {'week': 2, 'focus': '能力提升', 'description': '挑战中等难度题目'},
        {'week': 3, 'focus': '综合应用', 'description': '综合运用所学知识'},
        {'week': 4, 'focus': '总结提升', 'description': '总结学习成果，查漏补缺'},
      ],
      'tips': [
        '制定详细的学习计划',
        '定期评估学习进度',
        '及时调整学习策略',
      ],
    };
  }

  /// 获取持续学习计划
  Map<String, dynamic> _getContinuousPlan(int target) {
    return {
      'type': 'continuous',
      'target': target,
      'strategy': '保持稳定学习节奏',
      'recommendations': [
        '每天保持一定的学习量',
        '重点关注薄弱环节',
        '定期进行自我拾光',
        '保持学习兴趣和动力',
      ],
      'tips': [
        '设定合理的学习目标',
        '保持学习的连续性',
        '及时调整学习计划',
      ],
    };
  }

  /// 获取默认学习计划
  Map<String, dynamic> _getDefaultLearningPlan() {
    return {
      'type': 'default',
      'target': 10,
      'schedule': [
        {'time': '任意时间', 'activity': '自由练习', 'questions': 10},
      ],
      'tips': [
        '建议每天至少练习10道题目',
        '保持学习的连续性',
        '及时复习错题',
      ],
    };
  }

  /// 推荐个性化功能
  List<String> recommendPersonalizedFeatures() {
    final userTags = _personalizationService.getUserTags();
    final learningGoal = _personalizationService.getLearningGoal();
    final quizPreferences = _personalizationService.getQuizPreference();

    final recommendedFeatures = <String>[];

    // 根据用户标签推荐
    if (userTags.contains('收藏爱好者')) {
      recommendedFeatures.add('智能收藏夹');
      recommendedFeatures.add('收藏夹分类管理');
    }

    if (userTags.contains('成就收集者')) {
      recommendedFeatures.add('成就进度追踪');
      recommendedFeatures.add('成就分享功能');
    }

    if (userTags.contains('社交达人')) {
      recommendedFeatures.add('学习成果分享');
      recommendedFeatures.add('好友排行榜');
    }

    // 根据学习目标推荐
    if (learningGoal != null) {
      final goalType = learningGoal['period'] as String;
      if (goalType == 'daily') {
        recommendedFeatures.add('每日学习提醒');
        recommendedFeatures.add('学习打卡功能');
      } else if (goalType == 'weekly') {
        recommendedFeatures.add('周度学习报告');
        recommendedFeatures.add('学习计划管理');
      }
    }

    // 根据答题偏好推荐
    if (quizPreferences['difficulty'] == 'hard') {
      recommendedFeatures.add('困难题目挑战');
      recommendedFeatures.add('解题技巧提示');
    }

    return recommendedFeatures;
  }

  /// 推荐学习时间
  List<Map<String, dynamic>> recommendStudyTimes() {
    final userTags = _personalizationService.getUserTags();
    final learningGoal = _personalizationService.getLearningGoal();

    final recommendedTimes = <Map<String, dynamic>>[];

    // 根据用户类型推荐
    if (userTags.contains('早起者')) {
      recommendedTimes.add({
        'time': '06:00-08:00',
        'description': '早晨精神最佳，适合学习新知识',
        'suggestion': '建议学习新题目类型',
      });
    }

    if (userTags.contains('夜猫子')) {
      recommendedTimes.add({
        'time': '20:00-22:00',
        'description': '晚上思维活跃，适合深度思考',
        'suggestion': '建议复习和巩固知识',
      });
    }

    // 默认推荐
    recommendedTimes.addAll([
      {
        'time': '09:00-11:00',
        'description': '上午精力充沛，学习效率高',
        'suggestion': '建议进行重点学习',
      },
      {
        'time': '14:00-16:00',
        'description': '午后状态良好，适合练习',
        'suggestion': '建议进行题目练习',
      },
      {
        'time': '19:00-21:00',
        'description': '晚间时间充裕，适合复习',
        'suggestion': '建议复习和总结',
      },
    ]);

    return recommendedTimes;
  }
}
