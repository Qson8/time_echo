import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../services/voice_service.dart';
import '../widgets/voice_control_widget.dart';
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
  late Animation<double> _progressAnimation;
  late Animation<double> _questionAnimation;

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
        
        // 确保测试状态正确设置
        if (!appState.isTestInProgress) {
          print('⚠️ 检测到题目存在但测试未标记为进行中，这可能是旧状态，需要重新启动测试');
          // 如果是旧状态，应该清除并重新启动
          // 但这里不自动清除，因为可能是从定制页面刚进入的
          // 如果确实有问题，会在后续的测试中发现
        }
        
        _progressController.forward();
        _questionController.forward();
        
        // 如果启用了语音，自动播放第一题
        if (appState.voiceEnabled) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && appState.currentQuestion != null) {
              _speakCurrentQuestion(appState);
            }
          });
        }
        return;
      }
      
      // 如果没有测试在进行，使用默认方式启动测试
      print('🔄 启动新的测试（使用默认配置）');
      print('⚠️ 警告：这可能会覆盖定制配置的题目！');
      await appState.startTest().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('测试启动超时');
        },
      );
      
      _progressController.forward();
      _questionController.forward();
      
      // 如果启用了语音，自动播放第一题
      // 添加短暂延迟，确保动画开始后再播放语音
      if (appState.voiceEnabled) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && appState.currentQuestion != null) {
            _speakCurrentQuestion(appState);
          }
        });
      }
    } catch (e) {
      print('启动测试失败: $e');
      // 即使失败也显示题目（如果有示例题目）
    }
  }

  @override
  void dispose() {
    // 停止语音播放
    try {
      // 使用VoiceService单例直接停止
      VoiceService().stop();
    } catch (e) {
      print('停止语音失败: $e');
    }
    
    _progressController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拾光'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              return VoiceControlWidget(
                voiceService: appState.voiceService,
                isEnabled: appState.voiceEnabled,
                currentSpeed: appState.voiceSpeed,
                isCompact: true, // 在AppBar中使用紧凑模式
                onToggle: () {
                  appState.updateVoiceSettings(
                    !appState.voiceEnabled,
                    appState.voiceSpeed,
                  );
                },
                onSpeedChanged: (speed) {
                  appState.updateVoiceSettings(
                    appState.voiceEnabled,
                    speed,
                  );
                },
              );
            },
          ),
        ],
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
              
              // 题目区域
              Expanded(
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
            ],
          );
        },
      ),
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
    final userAnswer = appState.userAnswers[appState.currentQuestionIndex];

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
                
                // 语音播放按钮
                if (appState.voiceEnabled) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      VoicePlayButton(
                        voiceService: appState.voiceService,
                        text: question.content,
                        isEnabled: appState.voiceEnabled,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '点击播放题目',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 选项
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = userAnswer == index;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectAnswer(appState, index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.answerOptionDecoration(
                    isSelected,
                    false,
                    false,
                  ),
                  child: Row(
                    children: [
                      // 选项标识
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected 
                              ? const Color(AppConstants.primaryColor)
                              : Colors.transparent,
                          border: Border.all(
                            color: const Color(AppConstants.primaryColor),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected 
                                  ? Colors.white 
                                  : const Color(AppConstants.primaryColor),
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
                            color: isSelected 
                                ? const Color(AppConstants.primaryColor)
                                : Colors.black87,
                            fontWeight: isSelected 
                                ? FontWeight.w500 
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                  onPressed: userAnswer != -1 ? () => _nextQuestion(appState) : null,
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
      
      // 如果启用了语音，朗读下一题
      if (appState.voiceEnabled && appState.currentQuestion != null) {
        await _speakCurrentQuestion(appState);
      }
    }
  }

  /// 上一题
  Future<void> _previousQuestion(AppStateProvider appState) async {
    _questionController.reset();
    appState.previousQuestion();
    _questionController.forward();
    
    // 如果启用了语音，朗读上一题
    if (appState.voiceEnabled && appState.currentQuestion != null) {
      await _speakCurrentQuestion(appState);
    }
  }

  /// 完成测试
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasCollected ? '已取消收藏' : '已收藏至拾光收藏夹'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// 朗读当前题目
  Future<void> _speakCurrentQuestion(AppStateProvider appState) async {
    if (appState.currentQuestion != null) {
      await appState.voiceService.speakQuestion(
        appState.currentQuestion!.content,
        appState.currentQuestion!.options,
      );
    }
  }

  /// 显示退出对话框
  void _showExitDialog(BuildContext context) {
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
