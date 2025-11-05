import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/offline_data_manager.dart';
import '../widgets/offline_friendly_components.dart';
import '../widgets/animated_widgets.dart';
import 'quiz_screen.dart';
import 'collection_screen.dart';
import 'achievement_screen.dart';
import 'settings_screen.dart';

/// 离线优化的主页
class OfflineOptimizedHomeScreen extends StatefulWidget {
  const OfflineOptimizedHomeScreen({super.key});

  @override
  State<OfflineOptimizedHomeScreen> createState() => _OfflineOptimizedHomeScreenState();
}

class _OfflineOptimizedHomeScreenState extends State<OfflineOptimizedHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final OfflineDataManager _dataManager = OfflineDataManager();
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _settings = {};
  List<Map<String, dynamic>> _achievements = [];

  final List<Widget> _screens = [
    const OfflineHomeTab(),
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
    
    _initializeData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 初始化数据
  Future<void> _initializeData() async {
    try {
      await _dataManager.initialize();
      await _loadData();
    } catch (e) {
      print('数据初始化失败: $e');
    }
  }

  /// 加载数据
  Future<void> _loadData() async {
    _stats = await _dataManager.getStatistics();
    _settings = {
      'voice_enabled': await _dataManager.getSetting<bool>('voice_enabled') ?? false,
      'elderly_mode': await _dataManager.getSetting<bool>('elderly_mode') ?? false,
      'font_size': await _dataManager.getSetting<String>('font_size') ?? '中',
      'comment_style': await _dataManager.getSetting<String>('comment_style') ?? '通用版',
    };
    
    final achievements = await _dataManager.getAllAchievements();
    _achievements = achievements.map((a) => a.toMap()).toList();
    
    if (mounted) {
      setState(() {});
    }
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
      bottomNavigationBar: _buildOfflineBottomNavigationBar(),
    );
  }

  /// 构建离线底部导航栏
  Widget _buildOfflineBottomNavigationBar() {
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

/// 离线首页标签页
class OfflineHomeTab extends StatefulWidget {
  const OfflineHomeTab({super.key});

  @override
  State<OfflineHomeTab> createState() => _OfflineHomeTabState();
}

class _OfflineHomeTabState extends State<OfflineHomeTab>
    with TickerProviderStateMixin {
  late AnimationController _welcomeController;
  late AnimationController _statsController;
  late Animation<double> _welcomeAnimation;
  late Animation<double> _statsAnimation;

  final OfflineDataManager _dataManager = OfflineDataManager();
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentTests = [];
  List<Map<String, dynamic>> _achievements = [];

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

    _loadData();
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

  /// 加载数据
  Future<void> _loadData() async {
    try {
      _stats = await _dataManager.getStatistics();
      final testRecords = await _dataManager.getAllTestRecords();
      _recentTests = testRecords.take(3).map((r) => r.toMap()).toList();
      
      final achievements = await _dataManager.getAllAchievements();
      _achievements = achievements.map((a) => a.toMap()).toList();
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('加载数据失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildOfflineAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 欢迎区域
            _buildOfflineWelcomeSection(),
            
            const SizedBox(height: 24),
            
            // 本地数据统计
            _buildLocalDataStats(),
            
            const SizedBox(height: 24),
            
            // 快速开始
            _buildQuickStartSection(),
            
            const SizedBox(height: 24),
            
            // 学习统计
            _buildLearningStats(),
            
            const SizedBox(height: 24),
            
            // 最近测试
            _buildRecentTestsSection(),
            
            const SizedBox(height: 24),
            
            // 成就预览
            _buildAchievementPreview(),
          ],
        ),
      ),
    );
  }

  /// 构建离线应用栏
  PreferredSizeWidget _buildOfflineAppBar() {
    return AppBar(
      title: const Text(AppConstants.appName),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        OfflineFriendlyComponents.buildOfflineIndicator(),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showAboutDialog(),
        ),
      ],
    );
  }

  /// 构建离线欢迎区域
  Widget _buildOfflineWelcomeSection() {
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
                Icon(
                  Icons.wifi_off,
                  color: const Color(AppConstants.primaryColor),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '离线拾光机',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '本地数据，隐私安全',
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
                    '本地题目',
                    '${_stats['total_questions'] ?? 0}',
                    Icons.quiz,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '拾光次数',
                    '${_stats['total_tests'] ?? 0}',
                    Icons.analytics,
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

  /// 构建本地数据统计
  Widget _buildLocalDataStats() {
    return OfflineFriendlyComponents.buildLocalDataStats(
      stats: _stats,
      onTap: () => _showDataDetails(),
    );
  }

  /// 构建快速开始区域
  Widget _buildQuickStartSection() {
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
        
        Row(
          children: [
            Expanded(
              child: _buildQuickStartButton(
                '开始拾光',
                Icons.play_arrow,
                Colors.blue,
                () => _startQuiz(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStartButton(
                '随机题目',
                Icons.shuffle,
                Colors.green,
                () => _startRandomQuiz(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickStartButton(
                '挑战模式',
                Icons.emoji_events,
                Colors.purple,
                () => _startChallengeMode(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStartButton(
                '收藏夹',
                Icons.favorite,
                Colors.red,
                () => _openCollections(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建快速开始按钮
  Widget _buildQuickStartButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建学习统计
  Widget _buildLearningStats() {
    return OfflineFriendlyComponents.buildLocalLearningStats(stats: _stats);
  }

  /// 构建最近测试区域
  Widget _buildRecentTestsSection() {
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
        
        if (_recentTests.isEmpty)
          OfflineFriendlyComponents.buildOfflineTipDialog(
            title: '还没有拾光记录',
            content: '开始你的第一次拾光，体验怀旧的魅力！',
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startQuiz();
                },
                child: const Text('开始拾光'),
              ),
            ],
          )
        else
          ..._recentTests.map((test) => _buildTestRecordCard(test)).toList(),
      ],
    );
  }

  /// 构建测试记录卡片
  Widget _buildTestRecordCard(Map<String, dynamic> test) {
    final testTime = DateTime.parse(test['test_time']);
    final accuracy = test['accuracy'] as double;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getAccuracyColor(accuracy).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.quiz,
                color: _getAccuracyColor(accuracy),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${testTime.month}月${testTime.day}日 ${testTime.hour}:${testTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '准确率: ${(accuracy * 100).toInt()}% | 用时: ${test['total_time']}秒',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${test['echo_age']}岁',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建成就预览
  Widget _buildAchievementPreview() {
    return OfflineFriendlyComponents.buildLocalAchievementDisplay(
      achievements: _achievements,
      onViewAll: () => _openAchievements(),
    );
  }

  /// 获取准确率颜色
  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  /// 开始测试
  void _startQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizScreen()),
    );
  }

  /// 开始随机测试
  void _startRandomQuiz() {
    // 实现随机测试逻辑
    _startQuiz();
  }

  /// 开始挑战模式
  void _startChallengeMode() {
    // 实现挑战模式逻辑
    _startQuiz();
  }

  /// 打开收藏夹
  void _openCollections() {
    // 导航到收藏页面
  }

  /// 打开成就页面
  void _openAchievements() {
    // 导航到成就页面
  }

  /// 显示数据详情
  void _showDataDetails() {
    showDialog(
      context: context,
      builder: (context) => OfflineFriendlyComponents.buildOfflineTipDialog(
        title: '本地数据详情',
        content: '题目总数: ${_stats['total_questions']}\n'
                '拾光次数: ${_stats['total_tests']}\n'
                '成就解锁: ${_stats['unlocked_achievements']}/${_stats['total_achievements']}\n'
                '收藏题目: ${_stats['total_collections']}',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => OfflineFriendlyComponents.buildOfflineTipDialog(
        title: '关于拾光机',
        content: '拾光机是一款专注于离线怀旧问答的Flutter应用。\n\n'
                '特色功能：\n'
                '• 全离线运行，保护隐私\n'
                '• 怀旧主题内容\n'
                '• 本地数据存储\n'
                '• 成就系统\n'
                '• 语音辅助',
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
