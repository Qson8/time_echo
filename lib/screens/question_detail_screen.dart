import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/question.dart';
import '../services/app_state_provider.dart';

/// 题目详情页面
class QuestionDetailScreen extends StatelessWidget {
  final Question question;

  const QuestionDetailScreen({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('题目详情'),
        centerTitle: true,
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              return FutureBuilder<bool>(
                future: appState.isQuestionCollected(question.id),
                builder: (context, snapshot) {
                  final isCollected = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isCollected ? Icons.star : Icons.star_border,
                      color: isCollected 
                          ? const Color(AppConstants.accentColor)
                          : null,
                    ),
                    onPressed: () => _toggleCollection(context, appState),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目卡片
            _buildQuestionCard(),
            
            const SizedBox(height: 24),
            
            // 选项
            _buildOptionsSection(),
            
            const SizedBox(height: 24),
            
            // 答案解析
            _buildExplanationSection(),
          ],
        ),
      ),
    );
  }

  /// 构建题目卡片
  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.vintageDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类和难度标签
          Row(
            children: [
              _buildCategoryTag(question.category),
              const SizedBox(width: 8),
              _buildDifficultyTag(question.difficulty),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.echoTheme,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(AppConstants.primaryColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 题目内容
          Text(
            question.content,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建选项区域
  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选项',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.primaryColor),
          ),
        ),
        const SizedBox(height: 12),
        
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isCorrect = index == question.correctAnswer;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect 
                  ? const Color(AppConstants.accentColor).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect 
                    ? const Color(AppConstants.accentColor)
                    : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // 选项标识
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCorrect 
                        ? const Color(AppConstants.accentColor)
                        : Colors.grey,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // 选项内容
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      color: isCorrect 
                          ? const Color(AppConstants.accentColor)
                          : Colors.black87,
                      fontWeight: isCorrect 
                          ? FontWeight.w500 
                          : FontWeight.normal,
                    ),
                  ),
                ),
                
                // 正确答案标识
                if (isCorrect)
                  const Icon(
                    Icons.check_circle,
                    color: Color(AppConstants.accentColor),
                    size: 20,
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 构建答案解析区域
  Widget _buildExplanationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.photoPaperDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Color(AppConstants.primaryColor),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '答案解析',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.explanation,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类标签
  Widget _buildCategoryTag(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(AppConstants.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(AppConstants.primaryColor),
          width: 1,
        ),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 10,
          color: Color(AppConstants.primaryColor),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建难度标签
  Widget _buildDifficultyTag(String difficulty) {
    Color color;
    switch (difficulty) {
      case '简单':
        color = Colors.green;
        break;
      case '中等':
        color = Colors.orange;
        break;
      case '困难':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 切换收藏状态
  Future<void> _toggleCollection(BuildContext context, AppStateProvider appState) async {
    await appState.toggleCollection(question.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('收藏状态已更新'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
