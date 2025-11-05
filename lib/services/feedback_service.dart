import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// 用户反馈服务
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  SharedPreferences? _prefs;
  final List<Map<String, dynamic>> _feedbacks = [];

  /// 初始化服务
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadFeedbacks();
  }

  /// 加载反馈数据
  Future<void> _loadFeedbacks() async {
    if (_prefs == null) return;
    
    final feedbacksJson = _prefs!.getString('user_feedbacks');
    if (feedbacksJson != null) {
      try {
        final feedbacks = jsonDecode(feedbacksJson) as List<dynamic>;
        _feedbacks.clear();
        _feedbacks.addAll(feedbacks.cast<Map<String, dynamic>>());
      } catch (e) {
        print('加载反馈数据失败: $e');
      }
    }
  }

  /// 保存反馈数据
  Future<void> _saveFeedbacks() async {
    if (_prefs == null) return;
    
    try {
      final feedbacksJson = jsonEncode(_feedbacks);
      await _prefs!.setString('user_feedbacks', feedbacksJson);
    } catch (e) {
      print('保存反馈数据失败: $e');
    }
  }

  /// 提交反馈
  Future<bool> submitFeedback({
    required String type,
    required String content,
    String? rating,
    Map<String, dynamic>? metadata,
  }) async {
    await initialize();
    
    try {
      final feedback = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'content': content,
        'rating': rating,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      };
      
      _feedbacks.add(feedback);
      await _saveFeedbacks();
      
      return true;
    } catch (e) {
      print('提交反馈失败: $e');
      return false;
    }
  }

  /// 提交评分反馈
  Future<bool> submitRatingFeedback({
    required String feature,
    required int rating,
    String? comment,
  }) async {
    return await submitFeedback(
      type: 'rating',
      content: comment ?? '',
      rating: rating.toString(),
      metadata: {'feature': feature},
    );
  }

  /// 提交建议反馈
  Future<bool> submitSuggestionFeedback({
    required String suggestion,
    String? category,
  }) async {
    return await submitFeedback(
      type: 'suggestion',
      content: suggestion,
      metadata: {'category': category},
    );
  }

  /// 提交问题反馈
  Future<bool> submitProblemFeedback({
    required String problem,
    String? severity,
    Map<String, dynamic>? context,
  }) async {
    return await submitFeedback(
      type: 'problem',
      content: problem,
      metadata: {
        'severity': severity,
        'context': context ?? {},
      },
    );
  }

  /// 提交功能请求
  Future<bool> submitFeatureRequest({
    required String feature,
    required String description,
    String? priority,
  }) async {
    return await submitFeedback(
      type: 'feature_request',
      content: description,
      metadata: {
        'feature': feature,
        'priority': priority,
      },
    );
  }

  /// 获取反馈列表
  List<Map<String, dynamic>> getFeedbacks({String? type}) {
    if (type == null) {
      return List<Map<String, dynamic>>.from(_feedbacks);
    }
    
    return _feedbacks.where((feedback) => feedback['type'] == type).toList();
  }

  /// 获取反馈统计
  Map<String, dynamic> getFeedbackStats() {
    final stats = <String, int>{
      'total': _feedbacks.length,
      'rating': 0,
      'suggestion': 0,
      'problem': 0,
      'feature_request': 0,
    };
    
    for (final feedback in _feedbacks) {
      final type = feedback['type'] as String;
      stats[type] = (stats[type] ?? 0) + 1;
    }
    
    return stats;
  }

  /// 获取平均评分
  double getAverageRating() {
    final ratingFeedbacks = _feedbacks.where((f) => f['type'] == 'rating' && f['rating'] != null).toList();
    
    if (ratingFeedbacks.isEmpty) return 0.0;
    
    double totalRating = 0.0;
    for (final feedback in ratingFeedbacks) {
      totalRating += double.parse(feedback['rating'] as String);
    }
    
    return totalRating / ratingFeedbacks.length;
  }

  /// 复制反馈到剪贴板
  Future<void> copyFeedbackToClipboard(String feedbackId) async {
    final feedback = _feedbacks.firstWhere((f) => f['id'] == feedbackId);
    
    final feedbackText = '''
反馈类型: ${feedback['type']}
反馈内容: ${feedback['content']}
评分: ${feedback['rating'] ?? '无'}
时间: ${DateTime.fromMillisecondsSinceEpoch(feedback['timestamp'] as int)}
''';
    
    await Clipboard.setData(ClipboardData(text: feedbackText));
  }

  /// 导出反馈数据
  Map<String, dynamic> exportFeedbackData() {
    return {
      'feedbacks': _feedbacks,
      'stats': getFeedbackStats(),
      'averageRating': getAverageRating(),
      'exportTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 清除反馈数据
  Future<void> clearFeedbackData() async {
    await initialize();
    _feedbacks.clear();
    await _saveFeedbacks();
  }
}

/// 反馈类型枚举
enum FeedbackType {
  rating('评分反馈'),
  suggestion('建议反馈'),
  problem('问题反馈'),
  featureRequest('功能请求');

  const FeedbackType(this.displayName);
  final String displayName;
}

/// 反馈严重程度枚举
enum FeedbackSeverity {
  low('低'),
  medium('中'),
  high('高'),
  critical('严重');

  const FeedbackSeverity(this.displayName);
  final String displayName;
}

/// 反馈优先级枚举
enum FeedbackPriority {
  low('低'),
  medium('中'),
  high('高'),
  urgent('紧急');

  const FeedbackPriority(this.displayName);
  final String displayName;
}

/// 反馈模板
class FeedbackTemplates {
  static const Map<String, List<String>> templates = {
    'rating': [
      '这个功能很好用！',
      '希望能改进一下',
      '使用体验不错',
      '有些地方需要优化',
    ],
    'suggestion': [
      '建议增加更多题目类型',
      '希望能添加夜间模式',
      '建议优化界面布局',
      '希望能增加搜索功能',
    ],
    'problem': [
      '应用偶尔会卡顿',
      '某些题目显示异常',
      '语音功能有时不工作',
      '数据同步有问题',
    ],
    'feature_request': [
      '希望能添加离线模式',
      '建议增加学习计划功能',
      '希望能添加成就分享',
      '建议增加学习统计',
    ],
  };

  static List<String> getTemplates(String type) {
    return templates[type] ?? [];
  }
}

/// 反馈分析服务
class FeedbackAnalysisService {
  static final FeedbackAnalysisService _instance = FeedbackAnalysisService._internal();
  factory FeedbackAnalysisService() => _instance;
  FeedbackAnalysisService._internal();

  final FeedbackService _feedbackService = FeedbackService();

  /// 分析反馈趋势
  Map<String, dynamic> analyzeFeedbackTrends() {
    final feedbacks = _feedbackService.getFeedbacks();
    
    if (feedbacks.isEmpty) {
      return {
        'hasData': false,
        'message': '暂无反馈数据',
      };
    }

    // 按月份统计
    final monthlyStats = <String, Map<String, int>>{};
    for (final feedback in feedbacks) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(feedback['timestamp'] as int);
      final monthKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
      
      monthlyStats[monthKey] ??= {
        'total': 0,
        'rating': 0,
        'suggestion': 0,
        'problem': 0,
        'feature_request': 0,
      };
      
      monthlyStats[monthKey]!['total'] = monthlyStats[monthKey]!['total']! + 1;
      monthlyStats[monthKey]![feedback['type'] as String] = 
          (monthlyStats[monthKey]![feedback['type'] as String] ?? 0) + 1;
    }

    // 分析趋势
    final months = monthlyStats.keys.toList()..sort();
    final trends = <String, String>{};
    
    if (months.length >= 2) {
      final recent = monthlyStats[months.last]!;
      final previous = monthlyStats[months[months.length - 2]]!;
      
      for (final type in ['total', 'rating', 'suggestion', 'problem', 'feature_request']) {
        final recentCount = recent[type] ?? 0;
        final previousCount = previous[type] ?? 0;
        
        if (recentCount > previousCount) {
          trends[type] = '上升';
        } else if (recentCount < previousCount) {
          trends[type] = '下降';
        } else {
          trends[type] = '稳定';
        }
      }
    }

    return {
      'hasData': true,
      'monthlyStats': monthlyStats,
      'trends': trends,
      'totalMonths': months.length,
    };
  }

  /// 分析用户满意度
  Map<String, dynamic> analyzeUserSatisfaction() {
    final ratingFeedbacks = _feedbackService.getFeedbacks(type: 'rating');
    
    if (ratingFeedbacks.isEmpty) {
      return {
        'hasData': false,
        'message': '暂无评分数据',
      };
    }

    final ratings = <int>[];
    final featureRatings = <String, List<int>>{};
    
    for (final feedback in ratingFeedbacks) {
      if (feedback['rating'] != null) {
        final rating = int.parse(feedback['rating'] as String);
        ratings.add(rating);
        
        final feature = feedback['metadata']?['feature'] as String?;
        if (feature != null) {
          featureRatings[feature] ??= [];
          featureRatings[feature]!.add(rating);
        }
      }
    }

    if (ratings.isEmpty) {
      return {
        'hasData': false,
        'message': '暂无有效评分数据',
      };
    }

    final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
    final satisfactionLevel = _getSatisfactionLevel(averageRating);
    
    // 分析各功能评分
    final featureSatisfaction = <String, Map<String, dynamic>>{};
    for (final entry in featureRatings.entries) {
      final feature = entry.key;
      final featureRatingsList = entry.value;
      final featureAverage = featureRatingsList.reduce((a, b) => a + b) / featureRatingsList.length;
      
      featureSatisfaction[feature] = {
        'averageRating': featureAverage,
        'satisfactionLevel': _getSatisfactionLevel(featureAverage),
        'ratingCount': featureRatingsList.length,
      };
    }

    return {
      'hasData': true,
      'averageRating': averageRating,
      'satisfactionLevel': satisfactionLevel,
      'totalRatings': ratings.length,
      'featureSatisfaction': featureSatisfaction,
    };
  }

  /// 获取满意度等级
  String _getSatisfactionLevel(double rating) {
    if (rating >= 4.5) return '非常满意';
    if (rating >= 4.0) return '满意';
    if (rating >= 3.0) return '一般';
    if (rating >= 2.0) return '不满意';
    return '非常不满意';
  }

  /// 分析问题类型
  Map<String, dynamic> analyzeProblemTypes() {
    final problemFeedbacks = _feedbackService.getFeedbacks(type: 'problem');
    
    if (problemFeedbacks.isEmpty) {
      return {
        'hasData': false,
        'message': '暂无问题反馈数据',
      };
    }

    final problemTypes = <String, int>{};
    final severityCounts = <String, int>{};
    
    for (final feedback in problemFeedbacks) {
      final content = feedback['content'] as String;
      final severity = feedback['metadata']?['severity'] as String? ?? 'medium';
      
      // 简单的关键词分析
      if (content.contains('卡顿') || content.contains('慢')) {
        problemTypes['性能问题'] = (problemTypes['性能问题'] ?? 0) + 1;
      } else if (content.contains('显示') || content.contains('界面')) {
        problemTypes['界面问题'] = (problemTypes['界面问题'] ?? 0) + 1;
      } else if (content.contains('语音') || content.contains('声音')) {
        problemTypes['语音问题'] = (problemTypes['语音问题'] ?? 0) + 1;
      } else if (content.contains('数据') || content.contains('同步')) {
        problemTypes['数据问题'] = (problemTypes['数据问题'] ?? 0) + 1;
      } else {
        problemTypes['其他问题'] = (problemTypes['其他问题'] ?? 0) + 1;
      }
      
      severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
    }

    return {
      'hasData': true,
      'problemTypes': problemTypes,
      'severityCounts': severityCounts,
      'totalProblems': problemFeedbacks.length,
    };
  }
}
