import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../models/test_record.dart';
import '../widgets/enhanced_ux_components.dart';
import '../widgets/animated_widgets.dart';
import 'quiz_screen.dart';
import 'quiz_config_screen.dart';
import 'collection_screen.dart';
import 'achievement_screen.dart';
import 'settings_screen.dart';
import 'memory_capsule_screen.dart';
import 'memory_capsule_detail_screen.dart';
import '../services/memory_capsule_service.dart';
import '../models/memory_capsule.dart';
import 'statistics_screen.dart';
import 'intelligent_learning_assistant_screen.dart';
import 'test_record_list_screen.dart';
import 'quiz_result_screen.dart';
import '../services/daily_challenge_service.dart';
import '../models/daily_challenge.dart';
import '../services/local_storage_service.dart';
import '../services/app_state_provider.dart' show QuestionSelectionMode;

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<Widget> _screens;

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
    
    // 初始化屏幕列表，为 EnhancedHomeTab 传递打开 drawer 的回调
    _screens = [
      EnhancedHomeTab(
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      CollectionScreen(hideAppBar: true),
      AchievementScreen(
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      SettingsScreen(hideAppBar: true),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 首页和成就页面不显示主 AppBar（它们有自己的 AppBar 或不需要 AppBar）
    // 首页：使用自己的 AppBar（带菜单按钮）
    // 成就页面：使用自定义 AppBar（带状态栏处理）
    final bool showMainAppBar = _currentIndex != 0 && _currentIndex != 2;
    
    return Scaffold(
      key: _scaffoldKey,
      // 统一的 AppBar（首页和成就页面不显示）
      appBar: showMainAppBar ? _buildAppBar(context) : null,
      // 使用 IndexedStack 保持页面状态
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      drawer: _buildNavigationDrawer(context),
      // 确保侧边栏在所有页面都能正常工作
      // 支持从左侧边缘向右滑动展开侧边栏
      drawerEnableOpenDragGesture: true,
      // 支持手势关闭侧边栏（向左滑动或点击外部区域）
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.2, // 设置边缘拖拽区域宽度
    );
  }

  /// 构建统一的 AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final titles = ['首页', '拾光收藏夹', '我的拾光成就', '设置'];
    final currentTitle = titles[_currentIndex];
    
    // 根据页面类型构建不同的 AppBar
    if (_currentIndex == 1) {
      // 收藏页面需要批量操作按钮
      return AppBar(
        title: Text(currentTitle),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: '打开菜单',
          ),
        ),
        actions: [
          // 批量操作按钮由 CollectionScreen 通过 Consumer 管理
          // 由于 CollectionScreen 隐藏了 AppBar，批量操作功能通过 CollectionScreen 内部的按钮栏实现
          // 这里暂时不添加，避免状态管理复杂化
        ],
      );
    }
    
    return AppBar(
      title: Text(currentTitle),
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: '打开菜单',
        ),
      ),
      actions: _currentIndex == 0
          ? [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showAboutDialog(context),
                tooltip: '关于',
              ),
            ]
          : null,
    );
  }

  /// 显示关于对话框
  void _showAboutDialog(BuildContext context) {
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
                '拾光机是一款专为怀旧爱好者打造的离线问答应用，带你重温80-90年代的美好时光。无需网络连接，随时随地畅享经典回忆，通过答题拾光，系统会智能计算你的"拾光年龄"，让你了解自己对那个年代的记忆深度。',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                '核心特色：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('✨ 完全离线运行：无需网络，保护隐私安全'),
              const Text('🎬 怀旧主题设计：聚焦80-90年代经典内容'),
              const Text('🧠 智能拾光年龄：专属的"拾光年龄"评估'),
              const Text('💎 记忆胶囊功能：记录与题目相关的珍贵回忆'),
              const Text('🎖️ 成就系统：8种不同的拾光成就等待解锁'),
              const Text('📚 丰富题库：持续更新，涵盖影视、音乐、事件'),
              const Text('👴 老年友好设计：大字体、语音读题，易于操作'),
              const SizedBox(height: 16),
              const Text(
                '主要功能：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• 怀旧问答：随机出题，智能计算拾光年龄'),
              const Text('• 记忆胶囊：记录回忆，按年代分类查找'),
              const Text('• 拾光收藏夹：收藏喜欢的题目，添加个人笔记'),
              const Text('• 学习报告：自动生成日报/周报/月报'),
              const Text('• 每日挑战：每天3个挑战任务，完成获得奖励'),
              const Text('• 成就系统：8种成就徽章，见证成长足迹'),
              const Text('• 答题统计：可视化图表展示学习趋势'),
              const Text('• 个性化设置：字体大小、语音读题等'),
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

  /// 构建导航侧边栏
  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      // 支持手势关闭（向左滑动）
      elevation: 8.0, // 设置阴影以增强视觉层次
      width: MediaQuery.of(context).size.width * 0.75, // 设置侧边栏宽度为屏幕宽度的75%
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(AppConstants.secondaryColor),
              Colors.white,
            ],
          ),
      ),
      child: SafeArea(
          child: Column(
            children: [
              // 头部区域
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(AppConstants.primaryColor),
                      const Color(AppConstants.primaryColor).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '拾光机',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '让每一份时光记忆都值得珍藏',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 数据统计区域
              Consumer<AppStateProvider>(
                builder: (context, appState, child) {
                  return _buildStatisticsSection(context, appState);
                },
              ),
              
              const SizedBox(height: 8),
              
              // 导航菜单项
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      context,
                      0,
                      Icons.home_rounded,
                      '首页',
                      '回到主页',
                    ),
                    _buildDrawerItem(
                      context,
                      1,
                      Icons.favorite_rounded,
                      '拾光收藏夹',
                      '查看收藏的题目',
                    ),
                    _buildDrawerItem(
                      context,
                      2,
                      Icons.emoji_events_rounded,
                      '我的拾光成就',
                      '查看成就和徽章',
                    ),
                    _buildDrawerItem(
                      context,
                      4,
                      Icons.photo_library_rounded,
                      '记忆胶囊',
                      '查看记录的记忆',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MemoryCapsuleScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      3,
                      Icons.settings_rounded,
                      '设置',
                      '个性化设置',
                    ),
                  ],
                ),
              ),
              
              // 底部信息
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Divider(
                      color: Colors.grey[300],
                      height: 1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '版本 ${AppConstants.appVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建数据统计区域
  Widget _buildStatisticsSection(BuildContext context, AppStateProvider appState) {
    final testCount = appState.testRecords.length;
    final collectionCount = appState.collectedQuestions.length;
    final achievementCount = appState.achievements.length;
    
    // 计算平均准确率
    double avgAccuracy = 0.0;
    if (appState.testRecords.isNotEmpty) {
      final totalAccuracy = appState.testRecords
          .map((record) => record.accuracy)
          .reduce((a, b) => a + b);
      avgAccuracy = totalAccuracy / appState.testRecords.length;
    }
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context); // 先关闭侧边栏
        Future.delayed(const Duration(milliseconds: 200), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StatisticsScreen(),
            ),
          );
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(AppConstants.primaryColor).withOpacity(0.1),
              const Color(AppConstants.accentColor).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(AppConstants.primaryColor).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 18,
              color: const Color(AppConstants.primaryColor),
            ),
            const SizedBox(width: 8),
            Expanded(
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
                  const Text(
                    '数据统计',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactStatItem(
                          Icons.quiz_outlined,
                          '$testCount',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildCompactStatItem(
                          Icons.favorite_outline,
                          '$collectionCount',
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildCompactStatItem(
                          Icons.emoji_events_outlined,
                          '$achievementCount',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FutureBuilder<int>(
                          future: MemoryCapsuleService().getAllCapsules().then((capsules) => capsules.length),
                          builder: (context, snapshot) {
                            final memoryCount = snapshot.data ?? 0;
                            return _buildCompactStatItem(
                              Icons.photo_library_outlined,
                              '$memoryCount',
                              Colors.purple,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建紧凑的统计项（用于侧边栏）
  Widget _buildCompactStatItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建侧边栏菜单项
  Widget _buildDrawerItem(
    BuildContext context,
    int index,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: onTap ?? () {
        // 先关闭侧边栏
        Navigator.pop(context);
        // 延迟切换页面，确保侧边栏关闭动画完成
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _currentIndex != index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(AppConstants.primaryColor).withOpacity(0.15),
                    const Color(AppConstants.primaryColor).withOpacity(0.05),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(AppConstants.primaryColor),
                          const Color(AppConstants.accentColor),
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.grey[200],
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected 
                    ? const Color(AppConstants.primaryColor)
                          : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
                  Text(
                    subtitle,
              style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(AppConstants.accentColor),
                size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// 增强的首页标签页
class EnhancedHomeTab extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  
  const EnhancedHomeTab({super.key, this.onMenuPressed});

  @override
  State<EnhancedHomeTab> createState() => _EnhancedHomeTabState();
}

class _EnhancedHomeTabState extends State<EnhancedHomeTab>
    with TickerProviderStateMixin {
  late AnimationController _welcomeController;
  late AnimationController _statsController;
  late Animation<double> _welcomeAnimation;
  late Animation<double> _statsAnimation;
  int _memoryCapsuleRefreshKey = 0; // 用于强制刷新记忆胶囊区域
  DateTime? _lastMemoryRefreshTime; // 记录最后刷新时间，避免过度刷新

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

  /// 当页面重新可见时刷新记忆胶囊数据
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面可见时都刷新一次，但添加防抖机制（至少间隔1秒）
    final now = DateTime.now();
    if (_lastMemoryRefreshTime == null || 
        now.difference(_lastMemoryRefreshTime!).inSeconds > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🔄 首页可见，刷新记忆胶囊区域...');
          setState(() {
            _memoryCapsuleRefreshKey++; // 改变key强制刷新FutureBuilder
          });
          _lastMemoryRefreshTime = now;
        }
      });
    }
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
                
                // 记忆胶囊（提升权重，放在更靠前的位置）
                _buildRecentMemoriesSection(),
                
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
                
                // 最近拾光
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
      title: Text(
        AppConstants.appName,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.95), // 使用半透明白色背景
      iconTheme: const IconThemeData(
        color: Colors.black87, // 设置图标颜色为深色
      ),
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              // 优先使用传递的回调函数
              if (widget.onMenuPressed != null) {
                widget.onMenuPressed!();
              } else {
                // 如果没有回调，尝试查找父级 Scaffold
                final scaffoldState = context.findAncestorStateOfType<ScaffoldState>();
                if (scaffoldState != null) {
                  scaffoldState.openDrawer();
                } else {
                  // 最后尝试使用 Scaffold.of
                  try {
                    Scaffold.of(context).openDrawer();
                  } catch (e) {
                    print('无法打开侧边栏: $e');
                  }
                }
              }
            },
            tooltip: '打开菜单',
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showAboutDialog(),
          tooltip: '关于',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '学习统计',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '查看详情',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(AppConstants.primaryColor),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: const Color(AppConstants.primaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 总体统计（可点击）
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
            child: EnhancedUXComponents.buildSmartCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('总体表现'),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                    Text(
                      '${appState.testRecords.isNotEmpty ? appState.testRecords.last.accuracy.clamp(0.0, 100.0).toInt() : 0}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                        ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                EnhancedUXComponents.buildProgressIndicator(
                  progress: appState.testRecords.isNotEmpty 
                      ? (appState.testRecords.last.accuracy / 100).clamp(0.0, 1.0) 
                      : 0.0,
                  label: '准确率',
                  progressColor: Colors.green,
                ),
              ],
              ),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StatisticsScreen(),
          ),
        );
      },
      child: EnhancedUXComponents.buildSmartCard(
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
      ),
    );
  }

  /// 获取分类准确率
  int _getCategoryAccuracy(String category, AppStateProvider appState) {
    if (appState.testRecords.isEmpty) return 0;
    
    // 计算该分类的准确率
    final categoryRecords = appState.testRecords.where((record) => 
      record.categoryScores.containsKey(category)).toList();
    
    if (categoryRecords.isEmpty) return 0;
    
    // 计算该分类的总题目数和正确数
    // categoryScores存储的是题目数量，不是百分比
    int totalQuestions = 0;
    int correctAnswers = 0;
    
    for (final record in categoryRecords) {
      final categoryQuestionCount = record.categoryScores[category]!;
      totalQuestions += categoryQuestionCount;
      // 根据整体准确率估算该分类的正确数（accuracy是百分比格式，需要除以100）
      final accuracyRatio = (record.accuracy / 100).clamp(0.0, 1.0);
      correctAnswers += (categoryQuestionCount * accuracyRatio).round();
    }
    
    if (totalQuestions == 0) return 0;
    
    final accuracy = ((correctAnswers / totalQuestions) * 100).round();
    // 确保准确率不超过100%
    return accuracy.clamp(0, 100);
  }

  /// 构建推荐区域
  Widget _buildRecommendationSection(AppStateProvider appState) {
    // 分析用户表现，生成个性化建议
    String recommendation = '开始你的第一次拾光吧！';
    IconData recommendationIcon = Icons.lightbulb_outline;
    Color recommendationColor = const Color(AppConstants.primaryColor);
    
    if (appState.testRecords.isNotEmpty) {
      // 计算各分类的准确率
      final categoryAccuracies = <String, int>{};
      for (final category in ['影视', '音乐', '事件']) {
        categoryAccuracies[category] = _getCategoryAccuracy(category, appState);
      }
      
      // 找出最薄弱的分类
      String? weakestCategory;
      int lowestAccuracy = 100;
      categoryAccuracies.forEach((category, accuracy) {
        if (accuracy < lowestAccuracy) {
          lowestAccuracy = accuracy;
          weakestCategory = category;
        }
      });
      
      // 找出最强的分类
      String? strongestCategory;
      int highestAccuracy = 0;
      categoryAccuracies.forEach((category, accuracy) {
        if (accuracy > highestAccuracy) {
          highestAccuracy = accuracy;
          strongestCategory = category;
        }
      });
      
      // 生成个性化建议
      if (weakestCategory != null && lowestAccuracy < 70) {
        recommendation = '建议多练习$weakestCategory分类题目，当前准确率${lowestAccuracy}%';
        recommendationIcon = Icons.trending_down;
        recommendationColor = Colors.orange;
      } else if (strongestCategory != null && highestAccuracy >= 80) {
        recommendation = '你在$strongestCategory分类表现优秀！继续保持，可以尝试挑战更高难度';
        recommendationIcon = Icons.trending_up;
        recommendationColor = Colors.green;
      } else {
        recommendation = '继续练习，保持学习节奏，你的拾光年龄会不断提升';
        recommendationIcon = Icons.auto_awesome;
        recommendationColor = const Color(AppConstants.primaryColor);
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '智能推荐',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IntelligentLearningAssistantScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '查看详情',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(AppConstants.primaryColor),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: const Color(AppConstants.primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        EnhancedUXComponents.buildSmartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    recommendationIcon,
                    color: recommendationColor,
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
              Text(
                recommendation,
                style: const TextStyle(
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

  /// 构建最近拾光区域
  Widget _buildRecentTestsSection(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '最近拾光',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (appState.testRecords.isNotEmpty)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TestRecordListScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '查看全部',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(AppConstants.primaryColor),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: const Color(AppConstants.primaryColor),
                    ),
                  ],
                ),
              ),
          ],
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
        else ...[
          ...appState.testRecords.take(3).map((record) => 
            _buildTestRecordCard(record)
          ).toList(),
          // 显示"查看更多"按钮（始终显示，方便用户查看所有记录）
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestRecordListScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appState.testRecords.length > 3 
                        ? '查看更多拾光记录 (${appState.testRecords.length}条)'
                        : '查看全部拾光记录 (${appState.testRecords.length}条)',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(AppConstants.primaryColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: const Color(AppConstants.primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建拾光记录卡片
  Widget _buildTestRecordCard(TestRecord record) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(testRecord: record),
          ),
        );
      },
      child: EnhancedUXComponents.buildSmartCard(
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
                    '准确率: ${record.accuracy.clamp(0.0, 100.0).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${record.echoAge}岁',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '查看详情',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(AppConstants.primaryColor),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: const Color(AppConstants.primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建记忆胶囊区域
  Widget _buildRecentMemoriesSection() {
    return FutureBuilder<List<MemoryCapsule>>(
      key: ValueKey<int>(_memoryCapsuleRefreshKey), // 使用key强制刷新
      future: MemoryCapsuleService().getAllCapsules(forceReload: true).then((capsules) {
        print('📦 首页加载记忆胶囊: ${capsules.length} 个');
        // 按创建时间倒序排列
        final mutableCapsules = List<MemoryCapsule>.from(capsules);
        mutableCapsules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('📦 首页记忆胶囊排序后: ${mutableCapsules.length} 个');
        return mutableCapsules;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final memories = snapshot.data ?? [];
        
        // 调试日志
        if (snapshot.hasError) {
          print('❌ 首页加载记忆胶囊失败: ${snapshot.error}');
        } else if (snapshot.hasData) {
          print('✅ 首页记忆胶囊数据: ${memories.length} 个');
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: const Color(AppConstants.primaryColor),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '记忆胶囊',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConstants.primaryColor),
                      ),
                    ),
                  ],
                ),
                if (memories.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MemoryCapsuleScreen(),
                        ),
                      );
                      // 如果返回true，说明数据有变化，需要刷新
                      if (result == true && mounted) {
                        print('🔄 从记忆胶囊页面返回，刷新首页数据...');
                        setState(() {
                          _memoryCapsuleRefreshKey++; // 改变key强制刷新FutureBuilder
                        });
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '查看全部',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(AppConstants.primaryColor),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: const Color(AppConstants.primaryColor),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (memories.isEmpty)
              EnhancedUXComponents.buildSmartEmptyState(
                title: '还没有记忆记录',
                subtitle: '记录下那些让你怀念的时光吧',
                icon: Icons.photo_library_outlined,
                actionText: '创建记忆胶囊',
                onAction: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MemoryCapsuleScreen(),
                    ),
                  );
                  // 如果返回true，说明创建成功，需要刷新
                  if (result == true && mounted) {
                    print('🔄 创建记忆胶囊后返回，刷新首页数据...');
                    setState(() {
                      _memoryCapsuleRefreshKey++; // 改变key强制刷新FutureBuilder
                    });
                  }
                },
              )
            else ...[
              ...memories.take(4).map((memory) => _buildMemoryCard(memory)),
              if (memories.length > 4)
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MemoryCapsuleScreen(),
                      ),
                    );
                    // 如果返回true，说明数据有变化，需要刷新
                    if (result == true && mounted) {
                      print('🔄 从记忆胶囊页面返回，刷新首页数据...');
                      setState(() {
                        _memoryCapsuleRefreshKey++; // 改变key强制刷新FutureBuilder
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '查看更多记忆 (${memories.length}条)',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(AppConstants.primaryColor),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: const Color(AppConstants.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
  
  /// 构建记忆胶囊卡片
  Widget _buildMemoryCard(MemoryCapsule capsule) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemoryCapsuleDetailScreen(capsule: capsule),
          ),
        );
        // 如果返回true，说明数据有变化（删除或编辑），需要刷新
        if (result == true && mounted) {
          print('🔄 从记忆胶囊详情页返回，刷新首页数据...');
          setState(() {
            _memoryCapsuleRefreshKey++; // 改变key强制刷新FutureBuilder
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.purple.withOpacity(0.2),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.photo_library,
                color: Colors.purple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capsule.getPreviewText(maxLength: 30),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        capsule.era,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        capsule.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MM/dd').format(capsule.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建成就预览
  Widget _buildAchievementPreview(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '成就预览',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AchievementScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '查看成就',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(AppConstants.primaryColor),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: const Color(AppConstants.primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildAchievementCard(
                '拾光初遇',
                Icons.star,
                Colors.yellow,
                _isAchievementUnlocked('拾光初遇', appState.achievements),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAchievementCard(
                '影视拾光者',
                Icons.movie,
                Colors.blue,
                _isAchievementUnlocked('影视拾光者', appState.achievements),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAchievementCard(
                '音乐回响者',
                Icons.music_note,
                Colors.orange,
                _isAchievementUnlocked('音乐回响者', appState.achievements),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建成就卡片
  Widget _buildAchievementCard(String title, IconData icon, Color color, bool isUnlocked) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AchievementScreen(),
          ),
        );
      },
      child: EnhancedUXComponents.buildSmartCard(
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
      ),
    );
  }

  /// 获取准确率颜色
  Color _getAccuracyColor(double accuracy) {
    // accuracy是百分比格式（0-100），转换为小数进行比较
    final ratio = (accuracy / 100).clamp(0.0, 1.0);
    if (ratio >= 0.8) return Colors.green;
    if (ratio >= 0.6) return Colors.orange;
    return Colors.red;
  }

  /// 检查成就是否已解锁
  bool _isAchievementUnlocked(String achievementName, List achievements) {
    return achievements.any((achievement) => 
      achievement.achievementName == achievementName && achievement.isUnlocked);
  }

  /// 开始拾光
  Future<void> _startQuiz(AppStateProvider appState) async {
    final localStorageService = LocalStorageService();
    
    // 检查是否有保存的定制配置
    final hasConfig = await localStorageService.hasQuizConfig();
    
    if (hasConfig) {
      // 有保存的配置，直接使用配置启动拾光
      try {
        final config = await localStorageService.getQuizConfig();
        if (config != null) {
          // 显示加载提示
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // 解析配置
          final questionCount = config['questionCount'] as int? ?? 10;
          final categories = (config['categories'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['影视', '音乐', '事件'];
          final eras = (config['eras'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['80年代', '90年代', '00年代'];
          final difficulties = (config['difficulties'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['简单', '中等', '困难'];
          
          QuestionSelectionMode mode = QuestionSelectionMode.balanced;
          final modeStr = config['selectionMode'] as String? ?? 'balanced';
          switch (modeStr) {
            case 'random':
              mode = QuestionSelectionMode.random;
              break;
            case 'balanced':
              mode = QuestionSelectionMode.balanced;
              break;
            case 'smart':
              mode = QuestionSelectionMode.smart;
              break;
            default:
              mode = QuestionSelectionMode.balanced;
          }
          
          // 启动拾光
          await appState.startTest(
            questionCount: questionCount,
            mode: mode,
          );
          
          // 关闭加载对话框
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          
          // 导航到答题页面
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuizScreen()),
            );
          }
          return;
        }
      } catch (e, stackTrace) {
        print('❌ 启动拾光失败: $e');
        print('❌ 错误堆栈: $stackTrace');
        // 关闭加载对话框
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // 显示错误提示
        if (mounted) {
          String errorMessage = '启动拾光失败';
          if (e.toString().contains('没有找到') || e.toString().contains('符合条件的题目')) {
            errorMessage = '没有找到符合条件的题目，请调整筛选条件后重试';
          } else if (e.toString().contains('数据库') || e.toString().contains('存储')) {
            errorMessage = '数据加载失败，请检查应用数据文件';
          } else if (e.toString().contains('题库') || e.toString().contains('题目')) {
            errorMessage = '题库中没有题目，请检查数据文件';
          } else {
            errorMessage = '启动拾光失败：${e.toString()}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }
    
    // 没有保存的配置，显示定制页面
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QuizConfigScreen()),
      );
    }
  }

  /// 开始随机拾光
  Future<void> _startRandomQuiz(AppStateProvider appState) async {
    print('🎲 开始随机拾光：清除旧状态并启动随机模式');
    
    final localStorageService = LocalStorageService();
    
    try {
      // 清除旧的拾光状态
      appState.resetTest();
      await localStorageService.clearTestState();
      
      print('✅ 拾光状态已清除');
      
      // 显示加载提示
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      // 使用随机模式启动拾光（不受定制设置影响，使用所有题目）
      await appState.startTest(
        questionCount: 10, // 默认10道题
        mode: QuestionSelectionMode.random, // 强制使用随机模式
      );
      
      print('✅ 随机拾光已启动，共 ${appState.currentTestQuestions.length} 道题目');
      
      // 关闭加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // 导航到答题页面
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuizScreen()),
        );
      }
    } catch (e) {
      print('❌ 启动随机拾光失败: $e');
      
      // 关闭加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动随机拾光失败：$e')),
        );
      }
    }
  }

  /// 开始挑战模式
  Future<void> _startChallengeMode(AppStateProvider appState) async {
    print('🏆 开始挑战模式：使用困难题目');
    
    final localStorageService = LocalStorageService();
    
    try {
      // 清除旧的拾光状态
      appState.resetTest();
      await localStorageService.clearTestState();
      
      print('✅ 拾光状态已清除');
      
      // 显示加载提示
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      // 挑战模式：使用困难题目，智能推荐模式
      await appState.startTest(
        questionCount: 15, // 挑战模式使用15道题
        mode: QuestionSelectionMode.smart, // 使用智能推荐模式
      );
      
      print('✅ 挑战模式已启动，共 ${appState.currentTestQuestions.length} 道题目');
      
      // 关闭加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // 导航到答题页面
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuizScreen()),
        );
      }
    } catch (e) {
      print('❌ 启动挑战模式失败: $e');
      
      // 关闭加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动挑战模式失败：$e')),
        );
      }
    }
  }

  /// 打开记忆胶囊
  void _openMemoryCapsules() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemoryCapsuleScreen()),
    );
    // 如果返回true，说明数据有变化，需要刷新首页
    if (result == true && mounted) {
      print('🔄 从记忆胶囊页面返回，刷新首页数据...');
      setState(() {
        _memoryCapsuleRefreshKey++; // 改变key强制刷新FutureBuilder
      });
    }
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // 如果挑战未完成，可以点击开始挑战
        if (!challenge.isCompleted) {
          // 根据挑战类型执行相应操作
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          _startQuiz(appState);
        }
      },
      child: Container(
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
                '拾光机是一款专为怀旧爱好者打造的离线问答应用。无需网络连接，随时随地畅享80-90年代的经典回忆。通过答题拾光，系统会智能计算你的"拾光年龄"，让你了解自己对那个年代的记忆深度。',
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
              const Text('• 记忆胶囊：记录与题目相关的记忆'),
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
