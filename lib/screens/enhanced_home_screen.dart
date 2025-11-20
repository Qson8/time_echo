import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../models/test_record.dart';
import '../widgets/enhanced_ux_components.dart';
import '../widgets/animated_widgets.dart';
import 'quiz_screen.dart';
import 'collection_screen.dart';
import 'achievement_screen.dart';
import 'settings_screen.dart';
import 'memory_capsule_screen.dart';
import '../services/daily_challenge_service.dart';
import '../models/daily_challenge.dart';

/// 增强的首页
class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    const EnhancedHomeTab(),
    const CollectionScreen(),
    const AchievementScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildEnhancedBottomNavigationBar(),
    );
  }

  /// 构建增强的底部导航栏
  Widget _buildEnhancedBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, '首页'),
              _buildNavItem(1, Icons.favorite, '收藏'),
              _buildNavItem(2, Icons.emoji_events, '成就'),
              _buildNavItem(3, Icons.settings, '设置'),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建导航项
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(AppConstants.primaryColor).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected 
                    ? const Color(AppConstants.primaryColor)
                    : Colors.grey,
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected 
                    ? const Color(AppConstants.primaryColor)
                    : Colors.grey,
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// 增强的首页标签页
class EnhancedHomeTab extends StatefulWidget {
  const EnhancedHomeTab({super.key});

  @override
  State<EnhancedHomeTab> createState() => _EnhancedHomeTabState();
}

class _EnhancedHomeTabState extends State<EnhancedHomeTab>
    with TickerProviderStateMixin {
  late AnimationController _welcomeController;
  late AnimationController _statsController;
  late Animation<double> _welcomeAnimation;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();
    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _welcomeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeOutBack,
    ));

    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutCubic,
    ));

    _welcomeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _statsController.forward();
    });
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildEnhancedAppBar(),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 欢迎区域
                _buildWelcomeSection(appState),
                
                const SizedBox(height: 24),
                
                // 快速开始
                _buildQuickStartSection(appState),
                
                const SizedBox(height: 24),
                
                // 每日挑战
                _buildDailyChallengesSection(),
                
                const SizedBox(height: 24),
                
                // 统计信息
                _buildStatsSection(appState),
                
                const SizedBox(height: 24),
                
                // 智能推荐
                _buildRecommendationSection(appState),
                
                const SizedBox(height: 24),
                
                // 最近测试
                _buildRecentTestsSection(appState),
                
                const SizedBox(height: 24),
                
                // 成就预览
                _buildAchievementPreview(appState),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建增强的应用栏
  PreferredSizeWidget _buildEnhancedAppBar() {
    return AppBar(
      title: const Text(AppConstants.appName),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showAboutDialog(),
        ),
      ],
    );
  }

  /// 构建欢迎区域
  Widget _buildWelcomeSection(AppStateProvider appState) {
    return ScaleTransition(
      scale: _welcomeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(AppConstants.primaryColor).withOpacity(0.1),
              const Color(AppConstants.primaryColor).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/icon.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '欢迎回到拾光机',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '让每一份时光记忆都值得珍藏',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 今日统计
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '今日拾光',
                    '${appState.testRecords.length}',
                    Icons.quiz,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '拾光年龄',
                    '${appState.testRecords.isNotEmpty ? appState.testRecords.last.echoAge : 0}',
                    Icons.cake,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建快速开始区域
  Widget _buildQuickStartSection(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速开始',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        EnhancedUXComponents.buildSmartButtonGroup(
          buttons: [
            SmartButtonData(
              text: '开始拾光',
              icon: Icons.play_arrow,
              onPressed: () => _startQuiz(appState),
              backgroundColor: const Color(AppConstants.primaryColor),
            ),
            SmartButtonData(
              text: '随机题目',
              icon: Icons.shuffle,
              onPressed: () => _startRandomQuiz(appState),
              backgroundColor: Colors.green,
            ),
            SmartButtonData(
              text: '挑战模式',
              icon: Icons.emoji_events,
              onPressed: () => _startChallengeMode(appState),
              backgroundColor: Colors.purple,
            ),
            SmartButtonData(
              text: '记忆胶囊',
              icon: Icons.inbox,
              onPressed: () => _openMemoryCapsules(),
              backgroundColor: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建统计信息区域
  Widget _buildStatsSection(AppStateProvider appState) {
    return FadeTransition(
      opacity: _statsAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '学习统计',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 总体统计
          EnhancedUXComponents.buildSmartCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('总体表现'),
                    Text(
                      '${appState.testRecords.isNotEmpty ? (appState.testRecords.last.accuracy * 100).toInt() : 0}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                EnhancedUXComponents.buildProgressIndicator(
                  progress: appState.testRecords.isNotEmpty ? appState.testRecords.last.accuracy : 0.0,
                  label: '准确率',
                  progressColor: Colors.green,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 分类统计
          Row(
            children: [
              Expanded(
                child: _buildCategoryStat('影视', Colors.blue, appState),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryStat('音乐', Colors.orange, appState),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryStat('事件', Colors.purple, appState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建分类统计
  Widget _buildCategoryStat(String category, Color color, AppStateProvider appState) {
    return EnhancedUXComponents.buildSmartCard(
      child: Column(
        children: [
          Icon(Icons.category, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            category,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_getCategoryAccuracy(category, appState)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取分类准确率
  int _getCategoryAccuracy(String category, AppStateProvider appState) {
    // 简化实现
    return 85;
  }

  /// 构建推荐区域
  Widget _buildRecommendationSection(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '智能推荐',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        EnhancedUXComponents.buildSmartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: const Color(AppConstants.primaryColor),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '个性化建议',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '基于你的学习模式，建议多练习影视分类题目',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建最近测试区域
  Widget _buildRecentTestsSection(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最近拾光',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (appState.testRecords.isEmpty)
          EnhancedUXComponents.buildSmartEmptyState(
            title: '还没有拾光记录',
            subtitle: '开始你的第一次拾光吧',
            icon: Icons.quiz,
            actionText: '开始拾光',
            onAction: () => _startQuiz(appState),
          )
        else
          ...appState.testRecords.take(3).map((record) => 
            _buildTestRecordCard(record)
          ).toList(),
      ],
    );
  }

  /// 构建测试记录卡片
  Widget _buildTestRecordCard(TestRecord record) {
    return EnhancedUXComponents.buildSmartCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getAccuracyColor(record.accuracy).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.quiz,
              color: _getAccuracyColor(record.accuracy),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.testTime.month}月${record.testTime.day}日',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '准确率: ${(record.accuracy * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${record.echoAge}岁',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建成就预览
  Widget _buildAchievementPreview(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '成就预览',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildAchievementCard(
                '拾光初遇',
                Icons.star,
                Colors.yellow,
                appState.achievements.isNotEmpty,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAchievementCard(
                '影视拾光者',
                Icons.movie,
                Colors.blue,
                false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAchievementCard(
                '音乐回响者',
                Icons.music_note,
                Colors.orange,
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建成就卡片
  Widget _buildAchievementCard(String title, IconData icon, Color color, bool isUnlocked) {
    return EnhancedUXComponents.buildSmartCard(
      child: Column(
        children: [
          Icon(
            icon,
            color: isUnlocked ? color : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isUnlocked ? color : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 获取准确率颜色
  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  /// 开始测试
  void _startQuiz(AppStateProvider appState) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizScreen()),
    );
  }

  /// 开始随机测试
  void _startRandomQuiz(AppStateProvider appState) {
    // 实现随机测试逻辑
    _startQuiz(appState);
  }

  /// 开始挑战模式
  void _startChallengeMode(AppStateProvider appState) {
    // 实现挑战模式逻辑
    _startQuiz(appState);
  }

  /// 打开记忆胶囊
  void _openMemoryCapsules() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemoryCapsuleScreen()),
    );
  }

  /// 构建每日挑战区域
  Widget _buildDailyChallengesSection() {
    return FutureBuilder<List<DailyChallenge>>(
      future: DailyChallengeService().getTodayChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final challenges = snapshot.data!;
        final completedCount = challenges.where((c) => c.isCompleted).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '每日挑战',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completedCount/${challenges.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...challenges.map((challenge) => _buildChallengeCard(challenge)),
          ],
        );
      },
    );
  }

  /// 构建挑战卡片
  Widget _buildChallengeCard(DailyChallenge challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: challenge.isCompleted
            ? Colors.green.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: challenge.isCompleted
              ? Colors.green
              : const Color(AppConstants.primaryColor).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                challenge.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: challenge.isCompleted ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: challenge.isCompleted ? Colors.green : null,
                  ),
                ),
              ),
              if (challenge.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '已完成',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: challenge.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    challenge.isCompleted ? Colors.green : const Color(AppConstants.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${challenge.currentValue}/${challenge.targetValue}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于拾光机'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '拾光机是一款专为怀旧爱好者打造的离线问答应用。无需网络连接，随时随地畅享80-90年代的经典回忆。通过答题测试，系统会智能计算你的"拾光年龄"，让你了解自己对那个年代的记忆深度。',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                '核心功能：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• 离线答题：无需网络，随时随地使用'),
              const Text('• 详细解析：提供解析、历史背景和知识点'),
              const Text('• 拾光年龄：智能计算专属"拾光年龄"'),
              const Text('• 学习报告：自动生成日报/周报/月报'),
              const Text('• 记忆胶囊：记录与题目相关的回忆'),
              const Text('• 每日挑战：每天3个挑战任务'),
              const Text('• 成就系统：8种成就徽章'),
              const Text('• 老年友好：大字体、语音读题'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '完全离线运行，无广告，保护隐私',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
