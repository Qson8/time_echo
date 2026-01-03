import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../models/test_record.dart';
import 'quiz_result_screen.dart';
import '../utils/theme_adapter.dart';

/// 拾光记录列表页面
class TestRecordListScreen extends StatelessWidget {
  const TestRecordListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '拾光记录',
          style: TextStyle(
            color: ThemeAdapter.getTextColor(context),
          ),
        ),
        centerTitle: true,
        backgroundColor: ThemeAdapter.getSurfaceColor(context),
        iconTheme: IconThemeData(
          color: ThemeAdapter.getIconColor(context),
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return FutureBuilder<List<TestRecord>>(
            future: appState.getRecentTestRecords(100), // 获取所有记录
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final records = snapshot.data ?? [];
              
              if (records.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Builder(
                          builder: (context) => Icon(
                            Icons.history,
                            size: 80,
                            color: ThemeAdapter.getSecondaryTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Builder(
                          builder: (context) => Text(
                            '暂无拾光记录',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ThemeAdapter.getTextColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) => Text(
                            '开始你的第一次拾光吧！',
                            style: TextStyle(
                              fontSize: 14,
                              color: ThemeAdapter.getSecondaryTextColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return _buildRecordCard(context, record);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 构建记录卡片
  Widget _buildRecordCard(BuildContext context, TestRecord record) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(testRecord: record),
          ),
        );
      },
      child: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ThemeAdapter.getPhotoPaperDecoration(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拾光年龄图标
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(
                      builder: (context) => Text(
                        '${record.echoAge}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ThemeAdapter.getPrimaryColor(context),
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) => Text(
                        '岁',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeAdapter.getPrimaryColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // 记录详情
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 使用 Wrap 或 Flexible 来处理溢出
                    Builder(
                      builder: (context) {
                        final textScaleFactor = MediaQuery.of(context).textScaleFactor;
                        final isLargeText = textScaleFactor > 1.2;
                        
                        // 如果字体较大，使用垂直布局
                        if (isLargeText) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '准确率：${record.accuracy.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: ThemeAdapter.getTextColor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${record.correctAnswers}/${record.totalQuestions} 题',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ThemeAdapter.getSecondaryTextColor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        }
                        
                        // 正常字体使用水平布局
                        return Row(
                          children: [
                            Flexible(
                              child: Text(
                                '准确率：${record.accuracy.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: ThemeAdapter.getTextColor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '${record.correctAnswers}/${record.totalQuestions} 题',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ThemeAdapter.getSecondaryTextColor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 3),
                    Builder(
                      builder: (context) => Text(
                        '用时：${(record.totalTime / 60).toStringAsFixed(1)} 分钟',
                        style: TextStyle(
                          fontSize: 14,
                          color: ThemeAdapter.getSecondaryTextColor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Builder(
                      builder: (context) => Text(
                        _formatTestTime(record.testTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeAdapter.getSecondaryTextColor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 箭头图标
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Builder(
                  builder: (context) {
                    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
                    final isLargeText = textScaleFactor > 1.2;
                    return Icon(
                      Icons.chevron_right,
                      color: ThemeAdapter.getSecondaryTextColor(context),
                      size: isLargeText ? 28 : 24,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化拾光时间
  String _formatTestTime(DateTime testTime) {
    final now = DateTime.now();
    final difference = now.difference(testTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分钟前';
    } else {
      return '刚刚';
    }
  }
}
