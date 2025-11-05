import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_record.dart';
import '../models/question.dart';

/// 数据分析服务
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _analytics = {};

  /// 初始化服务
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadAnalytics();
  }

  /// 加载分析数据
  Future<void> _loadAnalytics() async {
    if (_prefs == null) return;
    
    final analyticsJson = _prefs!.getString('analytics_data');
    if (analyticsJson != null) {
      try {
        final analytics = jsonDecode(analyticsJson) as Map<String, dynamic>;
        _analytics.addAll(analytics);
      } catch (e) {
        print('加载分析数据失败: $e');
      }
    }
  }

  /// 保存分析数据
  Future<void> _saveAnalytics() async {
    if (_prefs == null) return;
    
    try {
      final analyticsJson = jsonEncode(_analytics);
      await _prefs!.setString('analytics_data', analyticsJson);
    } catch (e) {
      print('保存分析数据失败: $e');
    }
  }

  /// 记录用户行为
  Future<void> trackUserAction(String action, {Map<String, dynamic>? parameters}) async {
    await initialize();
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final actionData = {
      'action': action,
      'timestamp': timestamp,
      'parameters': parameters ?? {},
    };
    
    _analytics['user_actions'] ??= [];
    (_analytics['user_actions'] as List).add(actionData);
    
    // 保持最近1000条记录
    if ((_analytics['user_actions'] as List).length > 1000) {
      (_analytics['user_actions'] as List).removeRange(0, 100);
    }
    
    await _saveAnalytics();
  }

  /// 记录答题数据
  Future<void> trackQuizData(TestRecord record) async {
    await initialize();
    
    _analytics['quiz_records'] ??= [];
    (_analytics['quiz_records'] as List).add({
      'id': record.id,
      'totalQuestions': record.totalQuestions,
      'correctAnswers': record.correctAnswers,
      'accuracy': record.accuracy,
      'totalTime': record.totalTime,
      'echoAge': record.echoAge,
      'testTime': record.testTime.millisecondsSinceEpoch,
      'categoryScores': record.categoryScores,
    });
    
    await _saveAnalytics();
  }

  /// 记录功能使用情况
  Future<void> trackFeatureUsage(String featureName, {Map<String, dynamic>? metadata}) async {
    await initialize();
    
    _analytics['feature_usage'] ??= {};
    final featureData = _analytics['feature_usage'] as Map<String, dynamic>;
    
    if (!featureData.containsKey(featureName)) {
      featureData[featureName] = {
        'count': 0,
        'lastUsed': 0,
        'metadata': <Map<String, dynamic>>[],
      };
    }
    
    final feature = featureData[featureName] as Map<String, dynamic>;
    feature['count'] = (feature['count'] as int) + 1;
    feature['lastUsed'] = DateTime.now().millisecondsSinceEpoch;
    
    if (metadata != null) {
      (feature['metadata'] as List).add({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': metadata,
      });
    }
    
    await _saveAnalytics();
  }

  /// 记录错误信息
  Future<void> trackError(String errorType, String errorMessage, {Map<String, dynamic>? context}) async {
    await initialize();
    
    _analytics['errors'] ??= [];
    (_analytics['errors'] as List).add({
      'type': errorType,
      'message': errorMessage,
      'context': context ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // 保持最近100条错误记录
    if ((_analytics['errors'] as List).length > 100) {
      (_analytics['errors'] as List).removeRange(0, 20);
    }
    
    await _saveAnalytics();
  }

  /// 记录性能数据
  Future<void> trackPerformance(String operation, int duration, {Map<String, dynamic>? metadata}) async {
    await initialize();
    
    _analytics['performance'] ??= {};
    final performanceData = _analytics['performance'] as Map<String, dynamic>;
    
    if (!performanceData.containsKey(operation)) {
      performanceData[operation] = {
        'count': 0,
        'totalDuration': 0,
        'averageDuration': 0,
        'minDuration': double.infinity,
        'maxDuration': 0,
        'records': <Map<String, dynamic>>[],
      };
    }
    
    final operationData = performanceData[operation] as Map<String, dynamic>;
    operationData['count'] = (operationData['count'] as int) + 1;
    operationData['totalDuration'] = (operationData['totalDuration'] as int) + duration;
    operationData['averageDuration'] = (operationData['totalDuration'] as int) / (operationData['count'] as int);
    operationData['minDuration'] = (operationData['minDuration'] as double) > duration ? duration : operationData['minDuration'];
    operationData['maxDuration'] = (operationData['maxDuration'] as int) < duration ? duration : operationData['maxDuration'];
    
    (operationData['records'] as List).add({
      'duration': duration,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': metadata ?? {},
    });
    
    // 保持最近50条记录
    if ((operationData['records'] as List).length > 50) {
      (operationData['records'] as List).removeRange(0, 10);
    }
    
    await _saveAnalytics();
  }

  /// 获取用户行为统计
  Map<String, dynamic> getUserBehaviorStats() {
    final userActions = _analytics['user_actions'] as List? ?? [];
    final actionCounts = <String, int>{};
    
    for (final action in userActions) {
      final actionName = action['action'] as String;
      actionCounts[actionName] = (actionCounts[actionName] ?? 0) + 1;
    }
    
    return {
      'totalActions': userActions.length,
      'actionCounts': actionCounts,
      'mostFrequentAction': actionCounts.isNotEmpty 
          ? actionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  /// 获取答题统计
  Map<String, dynamic> getQuizStats() {
    final quizRecords = _analytics['quiz_records'] as List? ?? [];
    
    if (quizRecords.isEmpty) {
      return {
        'totalTests': 0,
        'averageAccuracy': 0.0,
        'averageTime': 0.0,
        'averageEchoAge': 0.0,
        'bestAccuracy': 0.0,
        'fastestTime': 0,
        'categoryStats': <String, Map<String, dynamic>>{},
      };
    }
    
    double totalAccuracy = 0.0;
    double totalTime = 0.0;
    double totalEchoAge = 0.0;
    double bestAccuracy = 0.0;
    int fastestTime = 0;
    final categoryStats = <String, Map<String, dynamic>>{};
    
    for (final record in quizRecords) {
      final accuracy = record['accuracy'] as double;
      final time = record['totalTime'] as int;
      final echoAge = record['echoAge'] as int;
      final categoryScores = record['categoryScores'] as Map<String, dynamic>?;
      
      totalAccuracy += accuracy;
      totalTime += time;
      totalEchoAge += echoAge;
      
      if (accuracy > bestAccuracy) bestAccuracy = accuracy;
      if (fastestTime == 0 || time < fastestTime) fastestTime = time;
      
      if (categoryScores != null) {
        for (final entry in categoryScores.entries) {
          final category = entry.key;
          final score = entry.value as double;
          
          if (!categoryStats.containsKey(category)) {
            categoryStats[category] = {
              'count': 0,
              'totalScore': 0.0,
              'averageScore': 0.0,
            };
          }
          
          final stats = categoryStats[category]!;
          stats['count'] = (stats['count'] as int) + 1;
          stats['totalScore'] = (stats['totalScore'] as double) + score;
          stats['averageScore'] = (stats['totalScore'] as double) / (stats['count'] as int);
        }
      }
    }
    
    return {
      'totalTests': quizRecords.length,
      'averageAccuracy': totalAccuracy / quizRecords.length,
      'averageTime': totalTime / quizRecords.length,
      'averageEchoAge': totalEchoAge / quizRecords.length,
      'bestAccuracy': bestAccuracy,
      'fastestTime': fastestTime,
      'categoryStats': categoryStats,
    };
  }

  /// 获取功能使用统计
  Map<String, dynamic> getFeatureUsageStats() {
    final featureUsage = _analytics['feature_usage'] as Map<String, dynamic>? ?? {};
    
    final featureStats = <String, Map<String, dynamic>>{};
    for (final entry in featureUsage.entries) {
      final featureName = entry.key;
      final featureData = entry.value as Map<String, dynamic>;
      
      featureStats[featureName] = {
        'usageCount': featureData['count'] as int,
        'lastUsed': featureData['lastUsed'] as int,
        'lastUsedDate': DateTime.fromMillisecondsSinceEpoch(featureData['lastUsed'] as int),
      };
    }
    
    return {
      'totalFeatures': featureStats.length,
      'featureStats': featureStats,
      'mostUsedFeature': featureStats.isNotEmpty
          ? featureStats.entries.reduce((a, b) => a.value['usageCount'] > b.value['usageCount'] ? a : b).key
          : null,
    };
  }

  /// 获取错误统计
  Map<String, dynamic> getErrorStats() {
    final errors = _analytics['errors'] as List? ?? [];
    
    final errorCounts = <String, int>{};
    for (final error in errors) {
      final errorType = error['type'] as String;
      errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
    }
    
    return {
      'totalErrors': errors.length,
      'errorCounts': errorCounts,
      'mostCommonError': errorCounts.isNotEmpty
          ? errorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    final performance = _analytics['performance'] as Map<String, dynamic>? ?? {};
    
    final performanceStats = <String, Map<String, dynamic>>{};
    for (final entry in performance.entries) {
      final operation = entry.key;
      final operationData = entry.value as Map<String, dynamic>;
      
      performanceStats[operation] = {
        'count': operationData['count'] as int,
        'averageDuration': operationData['averageDuration'] as double,
        'minDuration': operationData['minDuration'] as double,
        'maxDuration': operationData['maxDuration'] as int,
        'totalDuration': operationData['totalDuration'] as int,
      };
    }
    
    return {
      'totalOperations': performanceStats.length,
      'operationStats': performanceStats,
      'slowestOperation': performanceStats.isNotEmpty
          ? performanceStats.entries.reduce((a, b) => a.value['averageDuration'] > b.value['averageDuration'] ? a : b).key
          : null,
    };
  }

  /// 获取学习进度分析
  Map<String, dynamic> getLearningProgressAnalysis() {
    final quizRecords = _analytics['quiz_records'] as List? ?? [];
    
    if (quizRecords.length < 2) {
      return {
        'hasProgress': false,
        'message': '需要更多数据来分析学习进度',
      };
    }
    
    // 按时间排序
    quizRecords.sort((a, b) => (a['testTime'] as int).compareTo(b['testTime'] as int));
    
    final recentRecords = quizRecords.take(10).toList();
    final olderRecords = quizRecords.skip(quizRecords.length - 10).take(10).toList();
    
    double recentAccuracy = 0.0;
    double olderAccuracy = 0.0;
    
    for (final record in recentRecords) {
      recentAccuracy += record['accuracy'] as double;
    }
    recentAccuracy /= recentRecords.length;
    
    for (final record in olderRecords) {
      olderAccuracy += record['accuracy'] as double;
    }
    olderAccuracy /= olderRecords.length;
    
    final accuracyImprovement = recentAccuracy - olderAccuracy;
    
    return {
      'hasProgress': true,
      'recentAccuracy': recentAccuracy,
      'olderAccuracy': olderAccuracy,
      'accuracyImprovement': accuracyImprovement,
      'isImproving': accuracyImprovement > 0,
      'improvementPercentage': (accuracyImprovement / olderAccuracy * 100).abs(),
    };
  }

  /// 导出分析数据
  Map<String, dynamic> exportAnalyticsData() {
    return Map<String, dynamic>.from(_analytics);
  }

  /// 清除分析数据
  Future<void> clearAnalyticsData() async {
    await initialize();
    _analytics.clear();
    await _saveAnalytics();
  }
}
