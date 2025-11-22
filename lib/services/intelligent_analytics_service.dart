import 'dart:math';
import '../models/test_record.dart';
import '../models/question.dart';
import '../services/cache_service.dart';

/// 智能数据分析服务
class IntelligentAnalyticsService {
  static final IntelligentAnalyticsService _instance = IntelligentAnalyticsService._internal();
  factory IntelligentAnalyticsService() => _instance;
  IntelligentAnalyticsService._internal();

  final CacheService _cacheService = CacheService();
  final Random _random = Random();

  /// 分析用户学习模式
  Future<UserLearningPattern> analyzeUserLearningPattern(
    List<TestRecord> testRecords,
    List<Question> answeredQuestions,
  ) async {
    final pattern = UserLearningPattern();
    
    // 分析答题时间模式
    pattern.timePattern = _analyzeTimePattern(testRecords);
    
    // 分析难度偏好
    pattern.difficultyPreference = _analyzeDifficultyPreference(testRecords, answeredQuestions);
    
    // 分析分类表现
    pattern.categoryPerformance = _analyzeCategoryPerformance(testRecords);
    
    // 分析学习曲线
    pattern.learningCurve = _analyzeLearningCurve(testRecords);
    
    // 分析错误模式
    pattern.errorPatterns = _analyzeErrorPatterns(testRecords, answeredQuestions);
    
    // 分析进步趋势
    pattern.progressTrend = _analyzeProgressTrend(testRecords);
    
    return pattern;
  }

  /// 分析时间模式
  TimePattern _analyzeTimePattern(List<TestRecord> testRecords) {
    if (testRecords.isEmpty) {
      return TimePattern(
        preferredHour: 12,
        averageSessionDuration: 0,
        mostActiveDays: [],
        timeConsistency: 0.0,
      );
    }

    // 分析偏好时间
    final hourCounts = <int, int>{};
    final sessionDurations = <int>[];
    final dayCounts = <int, int>{};

    for (final record in testRecords) {
      final hour = record.testTime.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      
      sessionDurations.add(record.totalTime);
      
      final weekday = record.testTime.weekday;
      dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
    }

    // 找到最活跃的小时
    int preferredHour = 12;
    int maxCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        preferredHour = hour;
      }
    });

    // 计算平均会话时长
    final averageSessionDuration = sessionDurations.isNotEmpty
        ? sessionDurations.reduce((a, b) => a + b) / sessionDurations.length
        : 0;

    // 找到最活跃的星期
    final mostActiveDays = <int>[];
    int maxDayCount = 0;
    dayCounts.forEach((day, count) {
      if (count > maxDayCount) {
        maxDayCount = count;
        mostActiveDays.clear();
        mostActiveDays.add(day);
      } else if (count == maxDayCount) {
        mostActiveDays.add(day);
      }
    });

    // 计算时间一致性
    final timeConsistency = _calculateTimeConsistency(testRecords);

    return TimePattern(
      preferredHour: preferredHour,
      averageSessionDuration: averageSessionDuration.round(),
      mostActiveDays: mostActiveDays,
      timeConsistency: timeConsistency,
    );
  }

  /// 分析难度偏好
  DifficultyPreference _analyzeDifficultyPreference(
    List<TestRecord> testRecords,
    List<Question> answeredQuestions,
  ) {
    if (testRecords.isEmpty) {
      return DifficultyPreference(
        preferredDifficulty: '中',
        difficultyProgress: 0.0,
        challengeAcceptance: 0.0,
      );
    }

    // 分析难度分布
    final difficultyCounts = <String, int>{};
    final difficultyAccuracy = <String, List<double>>{};

    for (final record in testRecords) {
      // 这里需要根据实际的难度分类逻辑来实现
      // 简化实现
      difficultyCounts['中'] = (difficultyCounts['中'] ?? 0) + 1;
      difficultyAccuracy.putIfAbsent('中', () => []).add(record.accuracy);
    }

    // 找到偏好难度
    String preferredDifficulty = '中';
    int maxCount = 0;
    difficultyCounts.forEach((difficulty, count) {
      if (count > maxCount) {
        maxCount = count;
        preferredDifficulty = difficulty;
      }
    });

    // 计算难度进度
    final difficultyProgress = _calculateDifficultyProgress(testRecords);

    // 计算挑战接受度
    final challengeAcceptance = _calculateChallengeAcceptance(testRecords);

    return DifficultyPreference(
      preferredDifficulty: preferredDifficulty,
      difficultyProgress: difficultyProgress,
      challengeAcceptance: challengeAcceptance,
    );
  }

  /// 分析分类表现
  Map<String, CategoryPerformance> _analyzeCategoryPerformance(List<TestRecord> testRecords) {
    final categoryPerformance = <String, CategoryPerformance>{};

    if (testRecords.isEmpty) {
      return categoryPerformance;
    }

    // 分析各分类表现
    final categories = ['影视', '音乐', '事件'];
    
    for (final category in categories) {
      final categoryRecords = testRecords.where((record) => 
        record.categoryScores.containsKey(category)).toList();
      
      if (categoryRecords.isNotEmpty) {
        // categoryScores存储的是题目数量，不是百分比
        final totalQuestions = categoryRecords.fold<int>(0, (sum, record) => 
          sum + record.categoryScores[category]!);
        // 根据整体准确率估算该分类的正确数（accuracy是百分比格式，需要除以100）
        final correctAnswers = categoryRecords.fold<int>(0, (sum, record) {
          final accuracyRatio = (record.accuracy / 100).clamp(0.0, 1.0);
          return sum + (record.categoryScores[category]! * accuracyRatio).round();
        });
        
        final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions) : 0.0;
        final improvement = _calculateCategoryImprovement(categoryRecords, category);
        final strength = _calculateCategoryStrength(accuracy, improvement);
        
        categoryPerformance[category] = CategoryPerformance(
          accuracy: accuracy,
          improvement: improvement,
          strength: strength,
          totalQuestions: totalQuestions,
        );
      }
    }

    return categoryPerformance;
  }

  /// 分析学习曲线
  LearningCurve _analyzeLearningCurve(List<TestRecord> testRecords) {
    if (testRecords.length < 3) {
      return LearningCurve(
        trend: 'stable',
        slope: 0.0,
        volatility: 0.0,
        learningRate: 0.0,
      );
    }

    // 按时间排序
    final sortedRecords = testRecords.toList()
      ..sort((a, b) => a.testTime.compareTo(b.testTime));

    // 计算趋势
    final accuracies = sortedRecords.map((r) => r.accuracy).toList();
    final trend = _calculateTrend(accuracies);
    final slope = _calculateSlope(accuracies);
    final volatility = _calculateVolatility(accuracies);
    final learningRate = _calculateLearningRate(accuracies);

    return LearningCurve(
      trend: trend,
      slope: slope,
      volatility: volatility,
      learningRate: learningRate,
    );
  }

  /// 分析错误模式
  List<ErrorPattern> _analyzeErrorPatterns(
    List<TestRecord> testRecords,
    List<Question> answeredQuestions,
  ) {
    final errorPatterns = <ErrorPattern>[];

    // 分析常见错误类型
    final commonErrors = _identifyCommonErrors(testRecords, answeredQuestions);
    
    for (final error in commonErrors) {
      errorPatterns.add(ErrorPattern(
        errorType: error['type'] as String,
        frequency: error['frequency'] as double,
        impact: error['impact'] as double,
        suggestions: error['suggestions'] as List<String>,
      ));
    }

    return errorPatterns;
  }

  /// 分析进步趋势
  ProgressTrend _analyzeProgressTrend(List<TestRecord> testRecords) {
    if (testRecords.length < 2) {
      return ProgressTrend(
        overallProgress: 0.0,
        recentProgress: 0.0,
        progressAcceleration: 0.0,
        predictedProgress: 0.0,
      );
    }

    // 计算总体进步
    final overallProgress = _calculateOverallProgress(testRecords);
    
    // 计算近期进步
    final recentProgress = _calculateRecentProgress(testRecords);
    
    // 计算进步加速度
    final progressAcceleration = _calculateProgressAcceleration(testRecords);
    
    // 预测未来进步
    final predictedProgress = _predictFutureProgress(testRecords);

    return ProgressTrend(
      overallProgress: overallProgress,
      recentProgress: recentProgress,
      progressAcceleration: progressAcceleration,
      predictedProgress: predictedProgress,
    );
  }

  /// 计算时间一致性
  double _calculateTimeConsistency(List<TestRecord> testRecords) {
    if (testRecords.length < 2) return 0.0;

    final hours = testRecords.map((r) => r.testTime.hour.toDouble()).toList();
    final mean = hours.reduce((a, b) => a + b) / hours.length;
    final variance = hours.map((h) => pow(h - mean, 2)).reduce((a, b) => a + b) / hours.length;
    
    return 1.0 / (1.0 + sqrt(variance)); // 方差越小，一致性越高
  }

  /// 计算难度进度
  double _calculateDifficultyProgress(List<TestRecord> testRecords) {
    if (testRecords.isEmpty) return 0.0;
    
    // 简化实现：基于准确率计算难度进度
    final recentRecords = testRecords.take(5).toList();
    final averageAccuracy = recentRecords.fold<double>(0, (sum, record) => sum + record.accuracy) / recentRecords.length;
    
    return averageAccuracy;
  }

  /// 计算挑战接受度
  double _calculateChallengeAcceptance(List<TestRecord> testRecords) {
    if (testRecords.isEmpty) return 0.0;
    
    // 简化实现：基于拾光频率计算挑战接受度
    final testFrequency = testRecords.length / 30.0; // 假设30天内的拾光频率
    return (testFrequency / 1.0).clamp(0.0, 1.0); // 每天一次为满分
  }

  /// 计算分类改进
  double _calculateCategoryImprovement(List<TestRecord> categoryRecords, String category) {
    if (categoryRecords.length < 2) return 0.0;
    
    final sortedRecords = categoryRecords.toList()
      ..sort((a, b) => a.testTime.compareTo(b.testTime));
    
    final firstHalf = sortedRecords.take(sortedRecords.length ~/ 2).toList();
    final secondHalf = sortedRecords.skip(sortedRecords.length ~/ 2).toList();
    
    final firstAccuracy = firstHalf.fold<double>(0, (sum, record) => sum + record.accuracy) / firstHalf.length;
    final secondAccuracy = secondHalf.fold<double>(0, (sum, record) => sum + record.accuracy) / secondHalf.length;
    
    return secondAccuracy - firstAccuracy;
  }

  /// 计算分类强度
  double _calculateCategoryStrength(double accuracy, double improvement) {
    return (accuracy * 0.7 + improvement * 0.3).clamp(0.0, 1.0);
  }

  /// 计算趋势
  String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'stable';
    
    final firstHalf = values.take(values.length ~/ 2).toList();
    final secondHalf = values.skip(values.length ~/ 2).toList();
    
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    final difference = secondAvg - firstAvg;
    
    if (difference > 0.05) return 'improving';
    if (difference < -0.05) return 'declining';
    return 'stable';
  }

  /// 计算斜率
  double _calculateSlope(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final n = values.length;
    final sumX = n * (n - 1) / 2;
    final sumY = values.reduce((a, b) => a + b);
    final sumXY = values.asMap().entries.fold<double>(0, (sum, entry) => sum + entry.key * entry.value);
    final sumXX = values.asMap().entries.fold<double>(0, (sum, entry) => sum + entry.key * entry.key);
    
    return (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  }

  /// 计算波动性
  double _calculateVolatility(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    
    return sqrt(variance);
  }

  /// 计算学习率
  double _calculateLearningRate(List<double> values) {
    if (values.length < 3) return 0.0;
    
    // 简化实现：基于最近几个值的改进
    final recentValues = values.take(3).toList();
    final improvement = recentValues.last - recentValues.first;
    
    return improvement.clamp(0.0, 1.0);
  }

  /// 识别常见错误
  List<Map<String, dynamic>> _identifyCommonErrors(
    List<TestRecord> testRecords,
    List<Question> answeredQuestions,
  ) {
    // 简化实现
    return [
      {
        'type': '时间概念错误',
        'frequency': 0.3,
        'impact': 0.7,
        'suggestions': ['加强时间线记忆', '多练习年代相关题目'],
      },
      {
        'type': '分类混淆',
        'frequency': 0.2,
        'impact': 0.5,
        'suggestions': ['明确分类标准', '练习分类题目'],
      },
    ];
  }

  /// 计算总体进步
  double _calculateOverallProgress(List<TestRecord> testRecords) {
    if (testRecords.length < 2) return 0.0;
    
    final sortedRecords = testRecords.toList()
      ..sort((a, b) => a.testTime.compareTo(b.testTime));
    
    final firstAccuracy = sortedRecords.first.accuracy;
    final lastAccuracy = sortedRecords.last.accuracy;
    
    return lastAccuracy - firstAccuracy;
  }

  /// 计算近期进步
  double _calculateRecentProgress(List<TestRecord> testRecords) {
    if (testRecords.length < 4) return 0.0;
    
    final recentRecords = testRecords.take(4).toList();
    final firstHalf = recentRecords.take(2).toList();
    final secondHalf = recentRecords.skip(2).toList();
    
    final firstAvg = firstHalf.fold<double>(0, (sum, record) => sum + record.accuracy) / firstHalf.length;
    final secondAvg = secondHalf.fold<double>(0, (sum, record) => sum + record.accuracy) / secondHalf.length;
    
    return secondAvg - firstAvg;
  }

  /// 计算进步加速度
  double _calculateProgressAcceleration(List<TestRecord> testRecords) {
    if (testRecords.length < 6) return 0.0;
    
    final recentRecords = testRecords.take(6).toList();
    final firstThird = recentRecords.take(2).toList();
    final middleThird = recentRecords.skip(2).take(2).toList();
    final lastThird = recentRecords.skip(4).toList();
    
    final firstAvg = firstThird.fold<double>(0, (sum, record) => sum + record.accuracy) / firstThird.length;
    final middleAvg = middleThird.fold<double>(0, (sum, record) => sum + record.accuracy) / middleThird.length;
    final lastAvg = lastThird.fold<double>(0, (sum, record) => sum + record.accuracy) / lastThird.length;
    
    final firstImprovement = middleAvg - firstAvg;
    final secondImprovement = lastAvg - middleAvg;
    
    return secondImprovement - firstImprovement;
  }

  /// 预测未来进步
  double _predictFutureProgress(List<TestRecord> testRecords) {
    if (testRecords.length < 3) return 0.0;
    
    final recentRecords = testRecords.take(5).toList();
    final trend = _calculateTrend(recentRecords.map((r) => r.accuracy).toList());
    final slope = _calculateSlope(recentRecords.map((r) => r.accuracy).toList());
    
    // 基于趋势和斜率预测
    if (trend == 'improving') {
      return slope * 0.1; // 预测未来改进
    } else if (trend == 'declining') {
      return slope * 0.05; // 预测未来下降
    } else {
      return 0.0; // 稳定趋势
    }
  }

  /// 生成个性化建议
  Future<List<String>> generatePersonalizedSuggestions(UserLearningPattern pattern) async {
    final suggestions = <String>[];

    // 基于时间模式的建议
    if (pattern.timePattern.timeConsistency < 0.5) {
      suggestions.add('建议在固定时间进行拾光，提高学习一致性');
    }

    // 基于难度偏好的建议
    if (pattern.difficultyPreference.challengeAcceptance < 0.3) {
      suggestions.add('可以尝试更多挑战性题目，提升学习效果');
    }

    // 基于分类表现的建议
    pattern.categoryPerformance.forEach((category, performance) {
      if (performance.accuracy < 0.7) {
        suggestions.add('在$category分类上需要加强练习');
      }
    });

    // 基于学习曲线的建议
    if (pattern.learningCurve.trend == 'declining') {
      suggestions.add('学习效果有所下降，建议调整学习策略');
    }

    // 基于错误模式的建议
    for (final errorPattern in pattern.errorPatterns) {
      if (errorPattern.frequency > 0.3) {
        suggestions.addAll(errorPattern.suggestions);
      }
    }

    return suggestions;
  }
}

/// 用户学习模式数据模型
class UserLearningPattern {
  TimePattern timePattern = TimePattern();
  DifficultyPreference difficultyPreference = DifficultyPreference();
  Map<String, CategoryPerformance> categoryPerformance = {};
  LearningCurve learningCurve = LearningCurve();
  List<ErrorPattern> errorPatterns = [];
  ProgressTrend progressTrend = ProgressTrend();
}

/// 时间模式
class TimePattern {
  final int preferredHour;
  final int averageSessionDuration;
  final List<int> mostActiveDays;
  final double timeConsistency;

  TimePattern({
    this.preferredHour = 14,
    this.averageSessionDuration = 15,
    this.mostActiveDays = const [1, 2, 3, 4, 5],
    this.timeConsistency = 0.7,
  });
}

/// 难度偏好
class DifficultyPreference {
  final String preferredDifficulty;
  final double difficultyProgress;
  final double challengeAcceptance;

  DifficultyPreference({
    this.preferredDifficulty = 'medium',
    this.difficultyProgress = 0.5,
    this.challengeAcceptance = 0.6,
  });
}

/// 分类表现
class CategoryPerformance {
  final double accuracy;
  final double improvement;
  final double strength;
  final int totalQuestions;

  CategoryPerformance({
    this.accuracy = 0.7,
    this.improvement = 0.1,
    this.strength = 0.5,
    this.totalQuestions = 0,
  });
}

/// 学习曲线
class LearningCurve {
  final String trend;
  final double slope;
  final double volatility;
  final double learningRate;

  LearningCurve({
    this.trend = 'stable',
    this.slope = 0.1,
    this.volatility = 0.2,
    this.learningRate = 0.05,
  });
}

/// 错误模式
class ErrorPattern {
  final String errorType;
  final double frequency;
  final double impact;
  final List<String> suggestions;

  ErrorPattern({
    required this.errorType,
    required this.frequency,
    required this.impact,
    required this.suggestions,
  });
}

/// 进步趋势
class ProgressTrend {
  final double overallProgress;
  final double recentProgress;
  final double progressAcceleration;
  final double predictedProgress;

  ProgressTrend({
    this.overallProgress = 0.3,
    this.recentProgress = 0.1,
    this.progressAcceleration = 0.05,
    this.predictedProgress = 0.4,
  });
}
