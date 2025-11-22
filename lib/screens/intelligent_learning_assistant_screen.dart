import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../services/intelligent_learning_assistant.dart';
import '../services/app_state_provider.dart';

/// 智能学习助手界面
class IntelligentLearningAssistantScreen extends StatefulWidget {
  const IntelligentLearningAssistantScreen({super.key});

  @override
  State<IntelligentLearningAssistantScreen> createState() => _IntelligentLearningAssistantScreenState();
}

class _IntelligentLearningAssistantScreenState extends State<IntelligentLearningAssistantScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final IntelligentLearningAssistant _assistant = IntelligentLearningAssistant();
  
  PersonalizedLearningPlan? _learningPlan;
  DailyLearningReminder? _dailyReminder;
  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLearningData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.3,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _cardController.forward();
  }

  /// 加载学习数据
  Future<void> _loadLearningData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final learningPlan = await _assistant.generateLearningPlan();
      final dailyReminder = await _assistant.generateDailyReminder();
      
      if (mounted) {
        setState(() {
          _learningPlan = learningPlan;
          _dailyReminder = dailyReminder;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ 加载学习数据失败: $e');
      print('❌ 错误堆栈: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('加载数据失败: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: () => _loadLearningData(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '正在加载学习数据...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // 标签页
                  _buildTabBar(),
                  
                  // 内容区域
                  Expanded(
                    child: IndexedStack(
                      index: _currentTabIndex,
                      children: [
                        _buildDailyReminderTab(),
                        _buildLearningPlanTab(),
                        _buildProgressTab(),
                        _buildSuggestionsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('智能学习助手'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black87),
      titleTextStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isLoading = true;
            });
            _loadLearningData();
          },
          tooltip: '刷新',
        ),
      ],
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabItem(0, '今日', Icons.today),
          _buildTabItem(1, '计划', Icons.assignment),
          _buildTabItem(2, '进度', Icons.trending_up),
          _buildTabItem(3, '建议', Icons.lightbulb),
        ],
      ),
    );
  }

  /// 构建标签项
  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _currentTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _currentTabIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(AppConstants.primaryColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建每日提醒标签页
  Widget _buildDailyReminderTab() {
    if (_dailyReminder == null) {
      return _buildEmptyState(
        icon: Icons.today,
        title: '暂无今日提醒',
        subtitle: '正在生成您的个性化学习提醒...',
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 激励语句
          _buildMotivationCard(),
          
          const SizedBox(height: 16),
          
          // 今日任务
          _buildTodayTasksCard(),
          
          const SizedBox(height: 16),
          
          // 学习提示
          _buildLearningTipsCard(),
          
          const SizedBox(height: 16),
          
          // 学习统计
          _buildLearningStatsCard(),
        ],
      ),
    );
  }

  /// 构建激励卡片
  Widget _buildMotivationCard() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(AppConstants.primaryColor).withOpacity(0.8),
                const Color(AppConstants.primaryColor).withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.psychology,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                _dailyReminder!.motivation,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建今日任务卡片
  Widget _buildTodayTasksCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '今日任务',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ..._dailyReminder!.tasks.map((task) => _buildTaskItem(task)).toList(),
          ],
        ),
      ),
    );
  }

  /// 构建任务项
  Widget _buildTaskItem(DailyTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getTaskColor(task.priority).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTaskColor(task.priority).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getTaskColor(task.priority),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${task.estimatedTime}分钟',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建学习提示卡片
  Widget _buildLearningTipsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '学习提示',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ..._dailyReminder!.tips.map((tip) => _buildTipItem(tip)).toList(),
          ],
        ),
      ),
    );
  }

  /// 构建提示项
  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建学习统计卡片
  Widget _buildLearningStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '学习统计',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '最佳时间',
                    _dailyReminder!.bestTime == 'morning' ? '早晨' : 
                    _dailyReminder!.bestTime == 'afternoon' ? '下午' : 
                    _dailyReminder!.bestTime == 'evening' ? '晚上' : '夜间',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    '预计时长',
                    '${_dailyReminder!.estimatedDuration}分钟',
                    Icons.timer,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建学习计划标签页
  Widget _buildLearningPlanTab() {
    if (_learningPlan == null) {
      return _buildEmptyState(
        icon: Icons.assignment,
        title: '暂无学习计划',
        subtitle: '正在为您制定个性化学习计划...',
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 学习目标
          _buildLearningGoalsCard(),
          
          const SizedBox(height: 16),
          
          // 学习路径
          _buildLearningPathCard(),
          
          const SizedBox(height: 16),
          
          // 学习模式
          _buildLearningPatternCard(),
        ],
      ),
    );
  }

  /// 构建学习目标卡片
  Widget _buildLearningGoalsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '学习目标',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ..._learningPlan!.goals.map((goal) => _buildGoalItem(goal)).toList(),
          ],
        ),
      ),
    );
  }

  /// 构建目标项
  Widget _buildGoalItem(LearningGoal goal) {
    final progress = goal.current / goal.target;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${goal.current}/${goal.target}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            goal.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 进度条
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getPriorityColor(goal.priority),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '截止日期: ${goal.deadline.month}/${goal.deadline.day}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建学习路径卡片
  Widget _buildLearningPathCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '学习路径',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ..._learningPlan!.path.steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCurrent = index == _learningPlan!.path.currentStep;
              final isCompleted = index < _learningPlan!.path.currentStep;
              
              return _buildPathStep(step, index, isCurrent, isCompleted);
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// 构建路径步骤
  Widget _buildPathStep(LearningStep step, int index, bool isCurrent, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 步骤图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrent 
                  ? const Color(AppConstants.primaryColor)
                  : isCompleted 
                      ? Colors.green 
                      : Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted 
                  ? Icons.check 
                  : isCurrent 
                      ? Icons.play_arrow 
                      : Icons.radio_button_unchecked,
              color: Colors.white,
              size: 16,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 步骤内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? const Color(AppConstants.primaryColor) : Colors.black,
                  ),
                ),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '预计时长: ${step.duration}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建学习模式卡片
  Widget _buildLearningPatternCard() {
    final pattern = _learningPlan!.pattern;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '学习模式',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildPatternItem(
                    '偏好时间',
                    pattern.preferredTime == 'morning' ? '早晨' : 
                    pattern.preferredTime == 'afternoon' ? '下午' : 
                    pattern.preferredTime == 'evening' ? '晚上' : '夜间',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPatternItem(
                    '学习风格',
                    pattern.learningStyle == 'visual' ? '视觉型' : '听觉型',
                    Icons.visibility,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildPatternItem(
                    '动机水平',
                    pattern.motivationLevel == 'high' ? '高' : 
                    pattern.motivationLevel == 'medium' ? '中' : '低',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPatternItem(
                    '会话时长',
                    '${pattern.averageSessionDuration}分钟',
                    Icons.timer,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建模式项
  Widget _buildPatternItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建进度标签页
  Widget _buildProgressTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final testRecords = appState.testRecords;
        final totalTests = testRecords.length;
        final totalQuestions = testRecords.fold<int>(
          0, 
          (sum, record) => sum + record.totalQuestions,
        );
        final totalCorrect = testRecords.fold<int>(
          0, 
          (sum, record) => sum + record.correctAnswers,
        );
        final avgAccuracy = totalTests > 0
            ? testRecords.fold<double>(0, (sum, record) => sum + record.accuracy) / totalTests
            : 0.0;
        
        // 计算各分类的统计
        // categoryScores存储的是题目数量，不是百分比
        final categoryStats = <String, Map<String, dynamic>>{};
        for (final record in testRecords) {
          for (final entry in record.categoryScores.entries) {
            final category = entry.key;
            if (!categoryStats.containsKey(category)) {
              categoryStats[category] = {
                'total': 0,
                'correct': 0,
              };
            }
            // entry.value是该分类的题目数量
            final categoryQuestionCount = entry.value;
            categoryStats[category]!['total'] = (categoryStats[category]!['total'] as int) + categoryQuestionCount;
            // 根据整体准确率估算该分类的正确数（accuracy是百分比格式，需要除以100）
            final accuracyRatio = (record.accuracy / 100).clamp(0.0, 1.0);
            final estimatedCorrect = (categoryQuestionCount * accuracyRatio).round();
            categoryStats[category]!['correct'] = (categoryStats[category]!['correct'] as int) + estimatedCorrect;
          }
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 总体统计卡片
              _buildOverallStatsCard(
                totalTests: totalTests,
                totalQuestions: totalQuestions,
                totalCorrect: totalCorrect,
                avgAccuracy: avgAccuracy,
              ),
              
              const SizedBox(height: 16),
              
              // 分类统计卡片
              if (categoryStats.isNotEmpty) ...[
                _buildCategoryStatsCard(categoryStats),
                const SizedBox(height: 16),
              ],
              
              // 最近拾光记录
              if (testRecords.isNotEmpty) ...[
                _buildRecentTestsCard(testRecords.take(5).toList()),
              ] else
                _buildEmptyProgressCard(),
            ],
          ),
        );
      },
    );
  }
  
  /// 构建总体统计卡片
  Widget _buildOverallStatsCard({
    required int totalTests,
    required int totalQuestions,
    required int totalCorrect,
    required double avgAccuracy,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '总体统计',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    '总拾光数',
                    '$totalTests',
                    Icons.quiz,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    '总题目数',
                    '$totalQuestions',
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
                  child: _buildStatBox(
                    '正确数',
                    '$totalCorrect',
                    Icons.check_circle,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    '平均正确率',
                    // avgAccuracy已经是百分比格式（0-100），不需要再乘以100
                    '${avgAccuracy.clamp(0.0, 100.0).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    const Color(AppConstants.primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建统计盒子
  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建分类统计卡片
  Widget _buildCategoryStatsCard(Map<String, Map<String, dynamic>> categoryStats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '分类统计',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ...categoryStats.entries.map((entry) {
              final category = entry.key;
              final stats = entry.value;
              final total = stats['total'] as int;
              final correct = stats['correct'] as int;
              final accuracy = total > 0 ? correct / total : 0.0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(accuracy * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(AppConstants.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: accuracy,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(AppConstants.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '正确: $correct / 总数: $total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  /// 构建最近拾光记录卡片
  Widget _buildRecentTestsCard(List<dynamic> recentRecords) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '最近拾光',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ...recentRecords.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: index < recentRecords.length - 1 ? 12 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getAccuracyColor(record.accuracy).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.quiz,
                        color: _getAccuracyColor(record.accuracy),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${record.testTime.month}月${record.testTime.day}日 ${record.testTime.hour}:${record.testTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${record.correctAnswers}/${record.totalQuestions} 题正确',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // record.accuracy已经是百分比格式（0-100），不需要再乘以100
                    Text(
                      '${record.accuracy.clamp(0.0, 100.0).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getAccuracyColor(record.accuracy),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  /// 构建空进度卡片
  Widget _buildEmptyProgressCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(AppConstants.primaryColor).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColor).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 50,
              color: const Color(AppConstants.primaryColor).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有拾光记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '开始你的第一次拾光吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(AppConstants.primaryColor),
                  const Color(AppConstants.primaryColor).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.quiz,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '开始拾光',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 获取准确率颜色
  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) {
      return Colors.green;
    } else if (accuracy >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  /// 构建通用空白状态
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(AppConstants.primaryColor).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: const Color(AppConstants.primaryColor).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建建议标签页
  Widget _buildSuggestionsTab() {
    if (_learningPlan == null) {
      return _buildEmptyState(
        icon: Icons.lightbulb_outline,
        title: '暂无学习建议',
        subtitle: '完成更多拾光后，将为您提供个性化建议',
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _learningPlan!.suggestions.map((suggestion) => 
          _buildSuggestionCard(suggestion)
        ).toList(),
      ),
    );
  }

  /// 构建建议卡片
  Widget _buildSuggestionCard(LearningSuggestion suggestion) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getPriorityColor(suggestion.priority).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                suggestion.icon,
                color: _getPriorityColor(suggestion.priority),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    suggestion.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(suggestion.priority).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                suggestion.priority == 'high' ? '高' : 
                suggestion.priority == 'medium' ? '中' : '低',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getPriorityColor(suggestion.priority),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取任务颜色
  Color _getTaskColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 获取优先级颜色
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
