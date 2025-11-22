import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../models/test_record.dart';
import 'quiz_result_screen.dart';

/// 拾光记录列表页面
class TestRecordListScreen extends StatelessWidget {
  const TestRecordListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拾光记录'),
        centerTitle: true,
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
                return const Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.history,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '暂无拾光记录',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '开始你的第一次拾光吧！',
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.photoPaperDecoration,
        child: Row(
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
                children: [
                  Text(
                    '${record.echoAge}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(AppConstants.primaryColor),
                    ),
                  ),
                  const Text(
                    '岁',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(AppConstants.primaryColor),
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
                children: [
                  Row(
                    children: [
                      Text(
                        '准确率：${record.accuracy.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${record.correctAnswers}/${record.totalQuestions} 题',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '用时：${(record.totalTime / 60).toStringAsFixed(1)} 分钟',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTestTime(record.testTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // 箭头图标
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
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
