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

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedUXComponents.buildSmartTipDialog(
        title: '关于拾光机',
        content: '拾光机是一款专注于离线怀旧问答的Flutter应用，通过题目唤醒用户的时光记忆。',
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
