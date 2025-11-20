import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../models/test_record.dart';
import 'learning_report_screen.dart';

/// 拾光统计页面
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTab = 0; // 0: 拾光年龄, 1: 准确率, 2: 统计概览

  /// 加载所有记录
  Future<List<TestRecord>> _loadAllRecords(AppStateProvider appState) async {
    // 获取足够多的记录（100条应该足够）
    return await appState.getRecentTestRecords(100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拾光统计'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'daily') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LearningReportScreen(reportType: 'daily'),
                  ),
                );
              } else if (value == 'weekly') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LearningReportScreen(reportType: 'weekly'),
                  ),
                );
              } else if (value == 'monthly') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LearningReportScreen(reportType: 'monthly'),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'daily',
                child: Row(
                  children: [
                    Icon(Icons.today, size: 20),
                    SizedBox(width: 8),
                    Text('学习日报'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'weekly',
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 20),
                    SizedBox(width: 8),
                    Text('学习周报'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'monthly',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20),
                    SizedBox(width: 8),
                    Text('学习月报'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return FutureBuilder<List<TestRecord>>(
            future: _loadAllRecords(appState),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final records = snapshot.data ?? [];
              
              if (records.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  // Tab 切换
                  _buildTabBar(),
                  
                  // 内容区域
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 统计卡片
                          _buildStatsCards(records),
                          const SizedBox(height: 24),
                          
                          // 学习报告快捷入口
                          _buildReportQuickAccess(),
                          const SizedBox(height: 24),
                          
                          // 图表区域
                          if (_selectedTab == 0)
                            _buildEchoAgeChart(records)
                          else if (_selectedTab == 1)
                            _buildAccuracyChart(records)
                          else
                            _buildOverviewChart(records),
                          
                          const SizedBox(height: 24),
                          
                          // 分类统计图表
                          _buildCategoryChart(records),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              '暂无统计数据',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '完成几次拾光后，这里会显示你的统计图表',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Tab 切换栏
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('拾光年龄', 0),
          ),
          Expanded(
            child: _buildTabButton('准确率', 1),
          ),
          Expanded(
            child: _buildTabButton('统计概览', 2),
          ),
        ],
      ),
    );
  }

  /// 构建 Tab 按钮
  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(AppConstants.primaryColor) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatsCards(List<TestRecord> records) {
    if (records.isEmpty) return const SizedBox.shrink();

    final totalCount = records.length;
    final avgAccuracy = records.map((r) => r.accuracy).reduce((a, b) => a + b) / totalCount;
    final avgEchoAge = records.map((r) => r.echoAge).reduce((a, b) => a + b) / totalCount;
    final totalTime = records.map((r) => r.totalTime).reduce((a, b) => a + b);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '总次数',
            '$totalCount',
            Icons.quiz,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '平均准确率',
            '${avgAccuracy.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '平均拾光年龄',
            '${avgEchoAge.toStringAsFixed(0)}岁',
            Icons.cake,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建拾光年龄曲线图
  Widget _buildEchoAgeChart(List<TestRecord> records) {
    // 按时间排序（从旧到新）
    final sortedRecords = List<TestRecord>.from(records)
      ..sort((a, b) => a.testTime.compareTo(b.testTime));

    final spots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.echoAge.toDouble());
    }).toList();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '拾光年龄趋势',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
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
                          '${value.toInt()}',
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
                        if (value.toInt() >= sortedRecords.length) return const Text('');
                        final index = value.toInt();
                        if (index < sortedRecords.length) {
                          final date = sortedRecords[index].testTime;
                          return Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      interval: sortedRecords.length > 7 
                          ? (sortedRecords.length / 6).ceilToDouble() 
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
                    spots: spots,
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
                minY: spots.isNotEmpty 
                    ? (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 5).floor().toDouble()
                    : 0,
                maxY: spots.isNotEmpty 
                    ? (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 5).ceil().toDouble()
                    : 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建准确率曲线图
  Widget _buildAccuracyChart(List<TestRecord> records) {
    final sortedRecords = List<TestRecord>.from(records)
      ..sort((a, b) => a.testTime.compareTo(b.testTime));

    final spots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.accuracy);
    }).toList();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '准确率趋势',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
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
                        if (value.toInt() >= sortedRecords.length) return const Text('');
                        final index = value.toInt();
                        if (index < sortedRecords.length) {
                          final date = sortedRecords[index].testTime;
                          return Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      interval: sortedRecords.length > 7 
                          ? (sortedRecords.length / 6).ceilToDouble() 
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
                    spots: spots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.green,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计概览图表
  Widget _buildOverviewChart(List<TestRecord> records) {
    // 按日期分组统计
    final dateGroups = <String, int>{};
    for (final record in records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.testTime);
      dateGroups[dateKey] = (dateGroups[dateKey] ?? 0) + 1;
    }

    final sortedDates = dateGroups.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dateGroups[entry.value]!.toDouble());
    }).toList();

    return Column(
      children: [
        // 每日答题次数
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '每日答题次数',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: spots.isNotEmpty 
                        ? (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1)
                        : 5,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
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
                              '${value.toInt()}',
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
                            if (value.toInt() >= sortedDates.length) return const Text('');
                            final dateStr = sortedDates[value.toInt()];
                            return Text(
                              DateFormat('MM/dd').format(DateFormat('yyyy-MM-dd').parse(dateStr)),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          },
                          interval: sortedDates.length > 7 
                              ? (sortedDates.length / 6).ceilToDouble() 
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
                    barGroups: spots.map((spot) {
                      return BarChartGroupData(
                        x: spot.x.toInt(),
                        barRods: [
                          BarChartRodData(
                            toY: spot.y,
                            color: const Color(AppConstants.accentColor),
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建学习报告快捷入口
  Widget _buildReportQuickAccess() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assessment, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                '学习报告',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildReportButton(
                  '日报',
                  Icons.today,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LearningReportScreen(reportType: 'daily'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportButton(
                  '周报',
                  Icons.date_range,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LearningReportScreen(reportType: 'weekly'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportButton(
                  '月报',
                  Icons.calendar_month,
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LearningReportScreen(reportType: 'monthly'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分类统计图表
  Widget _buildCategoryChart(List<TestRecord> records) {
    if (records.isEmpty) return const SizedBox.shrink();

    // 统计各分类的答题情况
    final categoryStats = <String, Map<String, int>>{};
    for (final record in records) {
      if (record.categoryScores != null) {
        for (final entry in record.categoryScores!.entries) {
          final category = entry.key;
          if (!categoryStats.containsKey(category)) {
            categoryStats[category] = {'total': 0, 'count': 0};
          }
          categoryStats[category]!['total'] = (categoryStats[category]!['total'] ?? 0) + entry.value;
          categoryStats[category]!['count'] = (categoryStats[category]!['count'] ?? 0) + 1;
        }
      }
    }

    if (categoryStats.isEmpty) return const SizedBox.shrink();

    final categories = categoryStats.keys.toList();
    final spots = categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final total = categoryStats[category]!['total'] ?? 0;
      return FlSpot(index.toDouble(), total.toDouble());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类统计',
          style: TextStyle(
            fontSize: 18,
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
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: spots.isNotEmpty 
                  ? (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2)
                  : 10,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
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
                        '${value.toInt()}',
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
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= categories.length) return const Text('');
                      final category = categories[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
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
              barGroups: spots.asMap().entries.map((entry) {
                final index = entry.key;
                final spot = entry.value;
                final colors = [
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.red,
                ];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: spot.y,
                      color: colors[index % colors.length],
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
