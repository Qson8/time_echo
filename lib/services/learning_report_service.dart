import 'package:intl/intl.dart';
import '../models/test_record.dart';
import 'test_record_service.dart';

/// 学习报告数据模型
class LearningReport {
  final DateTime reportDate;
  final String reportType; // 'daily', 'weekly', 'monthly'
  final Map<String, dynamic> statistics;
  final List<String> insights;
  final List<String> suggestions;
  final Map<String, dynamic> charts;

  LearningReport({
    required this.reportDate,
    required this.reportType,
    required this.statistics,
    required this.insights,
    required this.suggestions,
    required this.charts,
  });

  Map<String, dynamic> toMap() {
    return {
      'report_date': reportDate.toIso8601String(),
      'report_type': reportType,
      'statistics': statistics,
      'insights': insights,
      'suggestions': suggestions,
      'charts': charts,
    };
  }
}

/// 学习报告服务类（完全离线）
class LearningReportService {
  static final LearningReportService _instance = LearningReportService._internal();
  factory LearningReportService() => _instance;
  LearningReportService._internal();

  final TestRecordService _testRecordService = TestRecordService();

  /// 生成日报
  Future<LearningReport> generateDailyReport(DateTime date) async {
    final records = await _testRecordService.getAllTestRecords();
    
    // 筛选当天的记录
    final dayRecords = records.where((r) {
      final recordDate = DateTime(r.testTime.year, r.testTime.month, r.testTime.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return recordDate == targetDate;
    }).toList();

    return _generateReport(dayRecords, date, 'daily');
  }

  /// 生成周报
  Future<LearningReport> generateWeeklyReport(DateTime weekStart) async {
    final records = await _testRecordService.getAllTestRecords();
    
    // 筛选本周的记录
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekRecords = records.where((r) {
      final recordDate = r.testTime;
      return recordDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             recordDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();

    return _generateReport(weekRecords, weekStart, 'weekly');
  }

  /// 生成月报
  Future<LearningReport> generateMonthlyReport(DateTime monthStart) async {
    final records = await _testRecordService.getAllTestRecords();
    
    // 筛选本月的记录
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    final monthRecords = records.where((r) {
      return r.testTime.year == monthStart.year &&
             r.testTime.month == monthStart.month;
    }).toList();

    return _generateReport(monthRecords, monthStart, 'monthly');
  }

  /// 生成报告的核心逻辑
  Future<LearningReport> _generateReport(
    List<TestRecord> records,
    DateTime reportDate,
    String reportType,
  ) async {
    if (records.isEmpty) {
      return LearningReport(
        reportDate: reportDate,
        reportType: reportType,
        statistics: {},
        insights: ['暂无学习数据'],
        suggestions: ['开始你的第一次拾光之旅吧！'],
        charts: {},
      );
    }

    // 计算统计数据
    final statistics = _calculateStatistics(records);
    
    // 生成洞察
    final insights = _generateInsights(records, statistics);
    
    // 生成建议
    final suggestions = _generateSuggestions(records, statistics);
    
    // 生成图表数据
    final charts = _generateChartData(records);

    return LearningReport(
      reportDate: reportDate,
      reportType: reportType,
      statistics: statistics,
      insights: insights,
      suggestions: suggestions,
      charts: charts,
    );
  }

  /// 计算统计数据
  Map<String, dynamic> _calculateStatistics(List<TestRecord> records) {
    if (records.isEmpty) {
      return {};
    }

    final totalCount = records.length;
    final totalQuestions = records.fold<int>(0, (sum, r) => sum + r.totalQuestions);
    final totalCorrect = records.fold<int>(0, (sum, r) => sum + r.correctAnswers);
    final avgAccuracy = records.fold<double>(0.0, (sum, r) => sum + r.accuracy) / totalCount;
    final avgEchoAge = records.fold<int>(0, (sum, r) => sum + r.echoAge) / totalCount;
    final totalTime = records.fold<int>(0, (sum, r) => sum + r.totalTime);

    // 分类统计
    final categoryStats = <String, Map<String, dynamic>>{};
    for (final record in records) {
      if (record.categoryScores != null) {
        for (final entry in record.categoryScores!.entries) {
          final category = entry.key;
          if (!categoryStats.containsKey(category)) {
            categoryStats[category] = {
              'total': 0,
              'correct': 0,
              'count': 0,
            };
          }
          categoryStats[category]!['total'] = (categoryStats[category]!['total'] as int) + entry.value;
          categoryStats[category]!['count'] = (categoryStats[category]!['count'] as int) + 1;
        }
      }
    }

    // 计算各分类准确率
    final categoryAccuracy = <String, double>{};
    categoryStats.forEach((category, stats) {
      final total = stats['total'] as int;
      final count = stats['count'] as int;
      if (count > 0) {
        // 估算正确数（基于总准确率，avgAccuracy已经是百分比格式）
        final accuracyRatio = (avgAccuracy / 100).clamp(0.0, 1.0);
        final estimatedCorrect = (total * accuracyRatio).round();
        final accuracy = (estimatedCorrect / total * 100);
        categoryAccuracy[category] = accuracy.clamp(0.0, 100.0);
      }
    });

    // 找出最佳和最差分类
    String? bestCategory;
    String? worstCategory;
    double bestAccuracy = 0;
    double worstAccuracy = 100;
    
    categoryAccuracy.forEach((category, accuracy) {
      if (accuracy > bestAccuracy) {
        bestAccuracy = accuracy;
        bestCategory = category;
      }
      if (accuracy < worstAccuracy) {
        worstAccuracy = accuracy;
        worstCategory = category;
      }
    });

    return {
      'total_count': totalCount,
      'total_questions': totalQuestions,
      'total_correct': totalCorrect,
      'avg_accuracy': avgAccuracy,
      'avg_echo_age': avgEchoAge,
      'total_time_minutes': (totalTime / 60).round(),
      'category_stats': categoryStats,
      'category_accuracy': categoryAccuracy,
      'best_category': bestCategory,
      'worst_category': worstCategory,
      'best_accuracy': bestAccuracy,
      'worst_accuracy': worstAccuracy,
    };
  }

  /// 生成洞察
  List<String> _generateInsights(List<TestRecord> records, Map<String, dynamic> stats) {
    final insights = <String>[];

    if (stats.isEmpty) return insights;

    final avgAccuracy = stats['avg_accuracy'] as double;
    final totalCount = stats['total_count'] as int;
    final avgEchoAge = stats['avg_echo_age'] as double;

    // 准确率洞察
    if (avgAccuracy >= 90) {
      insights.add('🎯 你的准确率非常优秀！保持在${avgAccuracy.toStringAsFixed(1)}%的高水平。');
    } else if (avgAccuracy >= 80) {
      insights.add('👍 你的准确率表现良好，达到${avgAccuracy.toStringAsFixed(1)}%。');
    } else if (avgAccuracy >= 70) {
      insights.add('📈 你的准确率为${avgAccuracy.toStringAsFixed(1)}%，还有提升空间。');
    } else {
      insights.add('💪 你的准确率为${avgAccuracy.toStringAsFixed(1)}%，继续努力，相信你会越来越好！');
    }

    // 学习频率洞察
    if (totalCount >= 5) {
      insights.add('🔥 你非常勤奋，完成了$totalCount 次拾光！');
    } else if (totalCount >= 3) {
      insights.add('✨ 你完成了$totalCount 次拾光，继续保持！');
    }

    // 拾光年龄洞察
    insights.add('🌟 你的拾光年龄为${avgEchoAge.toStringAsFixed(0)}岁，说明你对那个年代有深刻的记忆。');

    // 分类洞察
    final bestCategory = stats['best_category'] as String?;
    final worstCategory = stats['worst_category'] as String?;
    if (bestCategory != null) {
      final bestAccuracy = stats['best_accuracy'] as double;
      insights.add('🏆 你在"$bestCategory"分类表现最佳，准确率达到${bestAccuracy.toStringAsFixed(1)}%。');
    }
    if (worstCategory != null) {
      final worstAccuracy = stats['worst_accuracy'] as double;
      if (worstAccuracy < 70) {
        insights.add('📚 你在"$worstCategory"分类需要加强，当前准确率为${worstAccuracy.toStringAsFixed(1)}%。');
      }
    }

    return insights;
  }

  /// 生成建议
  List<String> _generateSuggestions(List<TestRecord> records, Map<String, dynamic> stats) {
    final suggestions = <String>[];

    if (stats.isEmpty) return suggestions;

    final avgAccuracy = stats['avg_accuracy'] as double;
    final worstCategory = stats['worst_category'] as String?;
    final worstAccuracy = stats['worst_accuracy'] as double;

    // 准确率建议
    if (avgAccuracy < 80) {
      suggestions.add('💡 建议多练习，提高整体准确率。可以尝试错题复习模式。');
    }

    // 薄弱环节建议
    if (worstCategory != null && worstAccuracy < 70) {
      suggestions.add('📖 建议重点练习"$worstCategory"分类的题目，加强薄弱环节。');
    }

    // 学习频率建议
    if (records.length < 3) {
      suggestions.add('⏰ 建议每天坚持练习，养成学习习惯。');
    }

    // 时间管理建议
    final totalTime = stats['total_time_minutes'] as int;
    final totalQuestions = stats['total_questions'] as int;
    if (totalQuestions > 0) {
      final avgTimePerQuestion = (totalTime * 60 / totalQuestions).round();
      if (avgTimePerQuestion > 30) {
        suggestions.add('⚡ 建议提高答题速度，当前平均每题${avgTimePerQuestion}秒。');
      }
    }

    // 通用建议
    suggestions.add('🎯 建议设定学习目标，如每天完成10道题，准确率达到85%以上。');

    return suggestions;
  }

  /// 生成图表数据
  Map<String, dynamic> _generateChartData(List<TestRecord> records) {
    // 按日期分组
    final dateGroups = <String, List<TestRecord>>{};
    for (final record in records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.testTime);
      if (!dateGroups.containsKey(dateKey)) {
        dateGroups[dateKey] = [];
      }
      dateGroups[dateKey]!.add(record);
    }

    // 生成每日数据点
    final dailyData = <Map<String, dynamic>>[];
    final sortedDates = dateGroups.keys.toList()..sort();
    
    for (final dateKey in sortedDates) {
      final dayRecords = dateGroups[dateKey]!;
      final dayAccuracy = dayRecords.fold<double>(0.0, (sum, r) => sum + r.accuracy) / dayRecords.length;
      final dayCount = dayRecords.length;
      final dayQuestions = dayRecords.fold<int>(0, (sum, r) => sum + r.totalQuestions);
      
      dailyData.add({
        'date': dateKey,
        'accuracy': dayAccuracy,
        'count': dayCount,
        'questions': dayQuestions,
      });
    }

    // 分类统计
    final categoryData = <String, Map<String, dynamic>>{};
    final categoryStats = <String, Map<String, dynamic>>{};
    
    for (final record in records) {
      if (record.categoryScores != null) {
        for (final entry in record.categoryScores!.entries) {
          final category = entry.key;
          if (!categoryStats.containsKey(category)) {
            categoryStats[category] = {
              'total': 0,
              'count': 0,
            };
          }
          categoryStats[category]!['total'] = (categoryStats[category]!['total'] as int) + entry.value;
          categoryStats[category]!['count'] = (categoryStats[category]!['count'] as int) + 1;
        }
      }
    }

    categoryStats.forEach((category, stats) {
      final total = stats['total'] as int;
      final count = stats['count'] as int;
      categoryData[category] = {
        'total': total,
        'count': count,
        'avg': count > 0 ? (total / count).round() : 0,
      };
    });

    return {
      'daily_data': dailyData,
      'category_data': categoryData,
    };
  }

  /// 导出报告为文本
  String exportReportAsText(LearningReport report) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final typeNames = {
      'daily': '日报',
      'weekly': '周报',
      'monthly': '月报',
    };

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('   拾光机 ${typeNames[report.reportType] ?? report.reportType}');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('报告日期：${dateFormat.format(report.reportDate)}');
    buffer.writeln('');

    // 统计数据
    if (report.statistics.isNotEmpty) {
      buffer.writeln('【统计数据】');
      final stats = report.statistics;
      buffer.writeln('总拾光次数：${stats['total_count'] ?? 0}');
      buffer.writeln('总答题数：${stats['total_questions'] ?? 0}');
      buffer.writeln('平均准确率：${(stats['avg_accuracy'] ?? 0.0).toStringAsFixed(1)}%');
      buffer.writeln('平均拾光年龄：${(stats['avg_echo_age'] ?? 0.0).toStringAsFixed(0)}岁');
      buffer.writeln('总学习时间：${stats['total_time_minutes'] ?? 0}分钟');
      buffer.writeln('');
    }

    // 学习洞察
    if (report.insights.isNotEmpty) {
      buffer.writeln('【学习洞察】');
      for (final insight in report.insights) {
        buffer.writeln(insight);
      }
      buffer.writeln('');
    }

    // 学习建议
    if (report.suggestions.isNotEmpty) {
      buffer.writeln('【学习建议】');
      for (final suggestion in report.suggestions) {
        buffer.writeln(suggestion);
      }
      buffer.writeln('');
    }

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('生成时间：${dateFormat.format(DateTime.now())}');
    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }
}

