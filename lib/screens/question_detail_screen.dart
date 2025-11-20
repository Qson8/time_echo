import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/question.dart';
import '../services/app_state_provider.dart';
import '../services/question_service.dart';

/// 题目详情页面
class QuestionDetailScreen extends StatefulWidget {
  final Question question;

  const QuestionDetailScreen({
    super.key,
    required this.question,
  });

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  List<Question>? _relatedQuestions;
  bool _loadingRelated = false;

  @override
  void initState() {
    super.initState();
    _loadRelatedQuestions();
  }

  Future<void> _loadRelatedQuestions() async {
    if (widget.question.relatedQuestionIds.isEmpty) return;
    
    setState(() {
      _loadingRelated = true;
    });
    
    try {
      final questionService = QuestionService();
      final related = <Question>[];
      for (final id in widget.question.relatedQuestionIds) {
        final q = await questionService.getQuestionById(id);
        if (q != null) {
          related.add(q);
        }
      }
      
      if (mounted) {
        setState(() {
          _relatedQuestions = related;
          _loadingRelated = false;
        });
      }
    } catch (e) {
      print('加载相关题目失败: $e');
      if (mounted) {
        setState(() {
          _loadingRelated = false;
        });
      }
    }
  }

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
                future: appState.isQuestionCollected(widget.question.id),
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
            
            // 知识点标签
            if (widget.question.knowledgePoints.isNotEmpty)
              _buildKnowledgePointsSection(),
            
            if (widget.question.knowledgePoints.isNotEmpty)
              const SizedBox(height: 24),
            
            // 历史背景
            if (widget.question.background != null && widget.question.background!.isNotEmpty)
              _buildBackgroundSection(),
            
            if (widget.question.background != null && widget.question.background!.isNotEmpty)
              const SizedBox(height: 24),
            
            // 答案解析
            _buildExplanationSection(),
            
            const SizedBox(height: 24),
            
            // 相关题目
            if (widget.question.relatedQuestionIds.isNotEmpty)
              _buildRelatedQuestionsSection(),
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
              _buildCategoryTag(widget.question.category),
              const SizedBox(width: 8),
              _buildDifficultyTag(widget.question.difficulty),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.question.echoTheme,
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
            widget.question.content,
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
        
        ...widget.question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isCorrect = index == widget.question.correctAnswer;
          
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
            widget.question.detailedExplanation ?? widget.question.explanation,
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

  /// 构建知识点标签区域
  Widget _buildKnowledgePointsSection() {
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
              Icon(
                Icons.school_outlined,
                color: Colors.blue,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '知识点',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.question.knowledgePoints.map((point) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  point,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建历史背景区域
  Widget _buildBackgroundSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.red.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
              Icon(
                Icons.history,
                color: Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '历史背景',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.question.background!,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建相关题目区域
  Widget _buildRelatedQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.link,
              color: Color(AppConstants.primaryColor),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              '相关题目',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingRelated)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_relatedQuestions == null || _relatedQuestions!.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                '暂无相关题目',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        else
          ..._relatedQuestions!.map((q) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  q.content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      _buildCategoryTag(q.category),
                      const SizedBox(width: 8),
                      _buildDifficultyTag(q.difficulty),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionDetailScreen(question: q),
                    ),
                  );
                },
              ),
            );
          }).toList(),
      ],
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
    await appState.toggleCollection(widget.question.id);
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
