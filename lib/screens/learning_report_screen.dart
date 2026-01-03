import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_constants.dart';
import '../services/learning_report_service.dart';
import '../models/test_record.dart';
import '../utils/theme_adapter.dart';

/// 学习报告页面
class LearningReportScreen extends StatefulWidget {
  final String reportType; // 'daily', 'weekly', 'monthly'
  final DateTime? reportDate;

  const LearningReportScreen({
    super.key,
    this.reportType = 'daily',
    this.reportDate,
  });

  @override
  State<LearningReportScreen> createState() => _LearningReportScreenState();
}

class _LearningReportScreenState extends State<LearningReportScreen> {
  final LearningReportService _reportService = LearningReportService();
  LearningReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final date = widget.reportDate ?? DateTime.now();
      LearningReport report;

      switch (widget.reportType) {
        case 'weekly':
          // 计算本周开始日期（周一）
          final weekStart = date.subtract(Duration(days: date.weekday - 1));
          report = await _reportService.generateWeeklyReport(weekStart);
          break;
        case 'monthly':
          // 计算本月开始日期
          final monthStart = DateTime(date.year, date.month, 1);
          report = await _reportService.generateMonthlyReport(monthStart);
          break;
        default:
          report = await _reportService.generateDailyReport(date);
      }

      if (mounted) {
        setState(() {
          _report = report;
          _loading = false;
        });
      }
    } catch (e) {
      print('加载学习报告失败: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getReportTitle()),
        centerTitle: true,
        actions: [
          if (_report != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareReport,
              tooltip: '分享报告',
            ),
          if (_report != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyReport,
              tooltip: '复制报告',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  String _getReportTitle() {
    switch (widget.reportType) {
      case 'weekly':
        return '学习周报';
      case 'monthly':
        return '学习月报';
      default:
        return '学习日报';
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败：$_error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReport,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_report == null) {
      return const Center(child: Text('暂无报告数据'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 报告头部
          _buildReportHeader(),
          
          const SizedBox(height: 24),
          
          // 统计数据卡片
          _buildStatisticsCards(),
          
          const SizedBox(height: 24),
          
          // 学习洞察
          _buildInsightsSection(),
          
          const SizedBox(height: 24),
          
          // 学习建议
          _buildSuggestionsSection(),
          
          const SizedBox(height: 24),
          
          // 图表
          _buildChartsSection(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReportHeader() {
    final dateFormat = DateFormat('yyyy年MM月dd日');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryColor),
            const Color(AppConstants.primaryColor).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryColor).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _getReportTitle(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateFormat.format(_report!.reportDate),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    if (_report!.statistics.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = _report!.statistics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '统计数据',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '拾光次数',
                '${stats['total_count'] ?? 0}',
                Icons.quiz,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '总答题数',
                '${stats['total_questions'] ?? 0}',
                Icons.help_outline,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '平均准确率',
                '${(stats['avg_accuracy'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '拾光年龄',
                '${(stats['avg_echo_age'] ?? 0.0).toStringAsFixed(0)}岁',
                Icons.cake,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeAdapter.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(ThemeAdapter.isDarkMode(context) ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Builder(
            builder: (context) => Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: ThemeAdapter.getSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    if (_report!.insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                '学习洞察',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._report!.insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Builder(
                    builder: (context) => Text(
                      insight,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: ThemeAdapter.getTextColor(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    if (_report!.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                '学习建议',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._report!.suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Builder(
                    builder: (context) => Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: ThemeAdapter.getTextColor(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    if (_report!.charts.isEmpty) {
      return const SizedBox.shrink();
    }

    final dailyData = _report!.charts['daily_data'] as List<dynamic>?;
    if (dailyData == null || dailyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '学习趋势',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300]!,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= dailyData.length) return const Text('');
                      final index = value.toInt();
                      if (index < dailyData.length) {
                        final dateStr = dailyData[index]['date'] as String;
                        try {
                          final date = DateFormat('yyyy-MM-dd').parse(dateStr);
                          return Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        } catch (e) {
                          return const Text('');
                        }
                      }
                      return const Text('');
                    },
                    interval: dailyData.length > 7 
                        ? (dailyData.length / 6).ceilToDouble() 
                        : 1,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                  left: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: dailyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value as Map<String, dynamic>;
                    final accuracy = data['accuracy'] as double? ?? 0.0;
                    return FlSpot(index.toDouble(), accuracy);
                  }).toList(),
                  isCurved: true,
                  color: const Color(AppConstants.primaryColor),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: const Color(AppConstants.primaryColor),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                  ),
                ),
              ],
              minY: 0,
              maxY: 100,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareReport() async {
    if (_report == null) return;

    try {
      final text = _reportService.exportReportAsText(_report!);
      // 尝试使用系统分享菜单（鸿蒙平台可能不支持，添加错误处理）
      try {
        await Share.share(text, subject: _getReportTitle());
      } catch (e) {
        // 如果分享失败（如鸿蒙平台不支持），显示文本内容供用户复制
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(_getReportTitle()),
              content: SingleChildScrollView(
                child: SelectableText(text),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                TextButton(
                  onPressed: () async {
                    // 复制到剪贴板
                    await Clipboard.setData(ClipboardData(text: text));
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('报告已复制到剪贴板')),
                      );
                    }
                  },
                  child: const Text('复制'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  Future<void> _copyReport() async {
    if (_report == null) return;

    try {
      final text = _reportService.exportReportAsText(_report!);
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报告已复制到剪贴板')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('复制失败: $e')),
        );
      }
    }
  }
}

