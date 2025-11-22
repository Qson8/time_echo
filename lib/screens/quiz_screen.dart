import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../widgets/interactive_feedback.dart';
import '../services/quiz_theme_service.dart';
import '../services/quiz_sound_service.dart';
import '../widgets/celebration_animation.dart';
import 'quiz_result_screen.dart';

/// 答题页面
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _questionController;
  late AnimationController _correctAnimationController;
  late AnimationController _wrongAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _questionAnimation;
  late Animation<double> _correctAnimation;
  late Animation<double> _wrongAnimation;

  final QuizThemeService _themeService = QuizThemeService();
  final QuizSoundService _soundService = QuizSoundService();
  int _streakCount = 0; // 连击数

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _questionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeInOut,
    ));

    // 正确答案动画控制器
    _correctAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _correctAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _correctAnimationController,
      curve: Curves.elasticOut,
    ));

    // 错误答案动画控制器
    _wrongAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _wrongAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _wrongAnimationController,
      curve: Curves.easeInOut,
    ));

    _startQuiz();
  }

  Future<void> _startQuiz() async {
    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      // 调试信息
      print('🔍 QuizScreen._startQuiz 检查状态：');
      print('   isTestInProgress: ${appState.isTestInProgress}');
      print('   currentTestQuestions.length: ${appState.currentTestQuestions.length}');
      if (appState.currentTestQuestions.isNotEmpty) {
        print('   第一题分类: ${appState.currentTestQuestions.first.category}');
        print('   第一题年代: ${appState.currentTestQuestions.first.echoTheme}');
      }
      
      // 如果已经有题目（例如从定制页面启动的），就不需要再次启动
      // 优先检查是否有题目，即使 isTestInProgress 为 false（可能是刚设置完题目但还没标记为进行中）
      if (appState.currentTestQuestions.isNotEmpty) {
        print('✅ 检测到已有题目（${appState.currentTestQuestions.length} 道），使用现有题目');
        print('   题目分类分布: ${appState.currentTestQuestions.map((q) => q.category).toSet()}');
        print('   题目年代分布: ${appState.currentTestQuestions.map((q) => q.echoTheme).toSet()}');
        
        // 确保拾光状态正确设置
        if (!appState.isTestInProgress) {
          print('⚠️ 检测到题目存在但拾光未标记为进行中，这可能是旧状态，需要重新启动拾光');
          // 如果是旧状态，应该清除并重新启动
          // 但这里不自动清除，因为可能是从定制页面刚进入的
          // 如果确实有问题，会在后续的拾光中发现
        }
        
        _progressController.forward();
        _questionController.forward();
        return;
      }
      
      // 如果没有拾光在进行，使用默认方式启动拾光
      print('🔄 启动新的拾光（使用默认配置）');
      print('⚠️ 警告：这可能会覆盖定制配置的题目！');
      await appState.startTest().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('拾光启动超时');
        },
      );
      
      _progressController.forward();
      _questionController.forward();
    } catch (e) {
      print('启动拾光失败: $e');
      // 即使失败也显示题目（如果有示例题目）
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _questionController.dispose();
    _correctAnimationController.dispose();
    _wrongAnimationController.dispose();
    _soundService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        // 根据当前题目获取主题
        final theme = _themeService.getThemeForQuestion(appState.currentQuestion);
        final gradient = _themeService.getBackgroundGradient(appState.currentQuestion);

        return Theme(
          data: theme,
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('拾光'),
                  if (_streakCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '连击 $_streakCount',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _showExitDialog(context, appState),
              ),
            ),
            body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (!appState.isTestInProgress || appState.currentQuestion == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // 进度条
              _buildProgressBar(appState),
              
              // 题目区域（带手势支持）
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    // 左滑下一题，右滑上一题
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! > 0) {
                        // 右滑 - 上一题
                        if (appState.currentQuestionIndex > 0) {
                          _previousQuestion(appState);
                        }
                      } else {
                        // 左滑 - 下一题
                        final userAnswer = (appState.currentQuestionIndex < appState.userAnswers.length)
                            ? appState.userAnswers[appState.currentQuestionIndex]
                            : -1;
                        if (userAnswer != -1) {
                          _nextQuestion(appState);
                        }
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                    ),
                    child: AnimatedBuilder(
                      animation: _questionAnimation,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _questionAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.3, 0),
                              end: Offset.zero,
                            ).animate(_questionAnimation),
                            child: _buildQuestionContent(appState),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
          ),
        );
      },
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(AppStateProvider appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '第 ${appState.currentQuestionIndex + 1} 题',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${appState.currentTestQuestions.length} 题',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: appState.testProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(AppConstants.primaryColor),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建题目内容
  Widget _buildQuestionContent(AppStateProvider appState) {
    final question = appState.currentQuestion!;
    // 安全获取用户答案，如果索引超出范围或未回答，返回 -1
    final userAnswer = (appState.currentQuestionIndex < appState.userAnswers.length)
        ? appState.userAnswers[appState.currentQuestionIndex]
        : -1;
    // 判断是否已回答（答案不为 -1 表示已回答）
    final hasAnswered = userAnswer != -1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 题目卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.vintageDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 题目分类和难度标签
                Row(
                  children: [
                    _buildCategoryTag(question.category),
                    const SizedBox(width: 8),
                    _buildDifficultyTag(question.difficulty),
                    const Spacer(),
                    // 收藏按钮
                    _CollectionButton(
                      key: ValueKey('collection_${question.id}'),
                      questionId: question.id,
                      onToggle: () => _toggleCollection(appState, question.id),
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
          ),
          
          const SizedBox(height: 24),
          
          // 选项（带动画效果）
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = hasAnswered && userAnswer == index;
            final isCorrect = hasAnswered &&
                index == question.correctAnswer;
            final isWrong = hasAnswered &&
                isSelected &&
                index != question.correctAnswer;
            
            Widget optionCard = InteractiveOptionCard(
              optionText: option,
              optionLabel: String.fromCharCode(65 + index),
              isSelected: isSelected,
              isCorrect: isCorrect,
              isWrong: isWrong,
              onTap: hasAnswered
                  ? null
                  : () => _selectAnswer(appState, index),
              index: index,
            );

            // 正确答案动画效果（带庆祝动画，移除放大效果）
            if (isCorrect) {
              optionCard = CelebrationAnimation(
                isActive: isCorrect,
                duration: const Duration(milliseconds: 1000),
                child: AnimatedBuilder(
                  animation: _correctAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(_correctAnimation.value * 0.5),
                            blurRadius: 20 * _correctAnimation.value,
                            spreadRadius: 5 * _correctAnimation.value,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: optionCard,
                ),
              );
            }

            // 错误答案动画效果
            if (isWrong) {
              optionCard = AnimatedBuilder(
                animation: _wrongAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      (_wrongAnimation.value - 0.5) * 10,
                      0,
                    ),
                    child: child,
                  );
                },
                child: optionCard,
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: optionCard,
            );
          }).toList(),
          
          const SizedBox(height: 32),
          
          // 操作按钮
          Row(
            children: [
              // 上一题按钮
              if (appState.currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _previousQuestion(appState),
                    child: const Text('上一题'),
                  ),
                ),
              
              if (appState.currentQuestionIndex > 0) const SizedBox(width: 16),
              
              // 下一题/完成按钮
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: hasAnswered ? () => _nextQuestion(appState) : null,
                  child: Text(
                    appState.isLastQuestion ? '完成拾光' : '下一题',
                  ),
                ),
              ),
            ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(AppConstants.primaryColor),
          width: 1,
        ),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 12,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 选择答案
  void _selectAnswer(AppStateProvider appState, int answerIndex) {
    final question = appState.currentQuestion!;
    final isCorrect = answerIndex == question.correctAnswer;

    // 播放音效和震动反馈
    if (isCorrect) {
      _soundService.playCorrectSound();
      HapticFeedback.mediumImpact();
      _correctAnimationController.forward(from: 0.0);
      // 增加连击数
      setState(() {
        _streakCount++;
      });
    } else {
      _soundService.playWrongSound();
      HapticFeedback.heavyImpact();
      _wrongAnimationController.forward(from: 0.0);
      // 重置连击数
      setState(() {
        _streakCount = 0;
      });
    }

    appState.answerQuestion(answerIndex);
  }

  /// 下一题
  Future<void> _nextQuestion(AppStateProvider appState) async {
    if (appState.isLastQuestion) {
      await _completeQuiz(appState);
    } else {
      _questionController.reset();
      appState.nextQuestion();
      _questionController.forward();
    }
  }

  /// 上一题
  Future<void> _previousQuestion(AppStateProvider appState) async {
    _questionController.reset();
    appState.previousQuestion();
    _questionController.forward();
  }

  /// 完成拾光
  Future<void> _completeQuiz(AppStateProvider appState) async {
    try {
      final testRecord = await appState.completeTest();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(testRecord: testRecord),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拾光完成失败：$e')),
        );
      }
    }
  }

  /// 切换收藏状态
  Future<void> _toggleCollection(AppStateProvider appState, int questionId) async {
    final wasCollected = await appState.isQuestionCollected(questionId);
    await appState.toggleCollection(questionId);
    
    if (mounted) {
      if (wasCollected) {
        InteractiveFeedback.showInfo(context, '已取消收藏');
      } else {
        InteractiveFeedback.showSuccess(context, '已收藏至拾光收藏夹');
      }
    }
  }

  /// 显示退出对话框
  void _showExitDialog(BuildContext context, AppStateProvider appState) {
    // 计算已答题数量（答案不为 -1 表示已答题）
    final answeredCount = appState.userAnswers.where((answer) => answer >= 0).length;
    
    // 如果已答题数量为 0，直接退出，不显示弹窗
    if (answeredCount == 0) {
      Navigator.of(context).pop(); // 直接返回上一页
      return;
    }
    
    // 如果已答题数量 > 0，显示弹窗提示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出拾光'),
        content: const Text('确定要退出当前拾光吗？进度将不会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭对话框
              Navigator.of(context).pop(); // 返回上一页
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 收藏按钮组件
class _CollectionButton extends StatefulWidget {
  final int questionId;
  final Future<void> Function() onToggle;

  const _CollectionButton({
    super.key,
    required this.questionId,
    required this.onToggle,
  });

  @override
  State<_CollectionButton> createState() => _CollectionButtonState();
}

class _CollectionButtonState extends State<_CollectionButton> {
  bool _isCollected = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollectionStatus();
  }

  @override
  void didUpdateWidget(_CollectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 questionId 变化了，重新加载收藏状态
    if (oldWidget.questionId != widget.questionId) {
      print('⭐ questionId 已变化：${oldWidget.questionId} -> ${widget.questionId}，重新加载状态');
      _isLoading = true;
      _loadCollectionStatus();
    }
  }

  Future<void> _loadCollectionStatus() async {
    print('⭐ _loadCollectionStatus 开始，questionId=${widget.questionId}');
    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      print('⭐ 调用 isQuestionCollected...');
      final isCollected = await appState.isQuestionCollected(widget.questionId);
      print('⭐ 获取到收藏状态: $isCollected');
      if (mounted) {
        setState(() {
          _isCollected = isCollected;
          _isLoading = false;
        });
        print('⭐ UI已更新: _isCollected=$_isCollected, _isLoading=$_isLoading');
      } else {
        print('⭐ ⚠️ widget 已卸载，跳过更新');
      }
    } catch (e, stackTrace) {
      print('⭐ ❌ 加载收藏状态失败: $e');
      print('⭐ ❌ 错误堆栈: $stackTrace');
      if (mounted) {
        setState(() {
          _isCollected = false;
          _isLoading = false; // 设置为false避免一直转圈
        });
        print('⭐ 已设置为默认值，停止转圈');
      }
    }
  }

  Future<void> _handleToggle() async {
    // 先更新UI显示加载状态（可选，提供更好的用户体验）
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 执行收藏/取消收藏操作
      await widget.onToggle();
      
      // 操作完成后，重新加载收藏状态以确保UI状态正确
      await _loadCollectionStatus();
    } catch (e) {
      print('⭐ ❌ 切换收藏状态失败: $e');
      // 如果操作失败，重新加载状态以恢复正确显示
      await _loadCollectionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(AppConstants.primaryColor),
            width: 2,
          ),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: _handleToggle,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isCollected ? Colors.amber.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isCollected ? Colors.amber : const Color(AppConstants.primaryColor),
            width: 2,
          ),
        ),
        child: Icon(
          _isCollected ? Icons.star : Icons.star_border,
          color: _isCollected ? Colors.amber[700] : const Color(AppConstants.primaryColor),
          size: 20,
        ),
      ),
    );
  }
}
