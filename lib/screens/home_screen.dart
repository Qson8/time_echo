import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../services/local_storage_service.dart';
import '../models/test_record.dart';
import 'quiz_screen.dart';
import 'quiz_config_screen.dart';
import 'collection_screen.dart';
import 'achievement_screen.dart';
import 'settings_screen.dart';
import 'test_record_list_screen.dart';
import 'statistics_screen.dart';
import 'memory_screen.dart';
import 'story_library_screen.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const CollectionScreen(),
    const AchievementScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(AppConstants.primaryColor),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '收藏',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: '成就',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

/// 首页标签页
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _hasIncompleteTest = false;
  final LocalStorageService _localStorageService = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _checkIncompleteTest();
  }

  Future<void> _checkIncompleteTest() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final hasTest = await appState.hasIncompleteTest();
    if (mounted) {
      setState(() {
        _hasIncompleteTest = hasTest;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 题库更新提示
                if (appState.newQuestionCount > 0)
                  _buildUpdateNotification(context, appState),
                
                const SizedBox(height: 20),
                
                // 未完成测试提示
                if (_hasIncompleteTest)
                  _buildIncompleteTestCard(context, appState),
                
                if (_hasIncompleteTest)
                  const SizedBox(height: 20),
                
                // 欢迎区域
                _buildWelcomeSection(context),
                
                const SizedBox(height: 30),
                
                // 快速开始
                _buildQuickStartSection(context),
                
                const SizedBox(height: 30),
                
                // 统计信息
                _buildStatsSection(context, appState),
                
                const SizedBox(height: 30),
                
                // 最近测试
                _buildRecentTestsSection(context, appState),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建更新通知
  Widget _buildUpdateNotification(BuildContext context, AppStateProvider appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.secondaryColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(AppConstants.primaryColor),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/icon.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '待更新：${appState.newQuestionCount}道新拾光题目',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _updateQuestionDatabase(context, appState),
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  /// 构建未完成测试卡片
  Widget _buildIncompleteTestCard(BuildContext context, AppStateProvider appState) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: appState.getIncompleteTestProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final progress = snapshot.data!;
        final currentIndex = progress['currentIndex'] as int;
        final totalQuestions = progress['totalQuestions'] as int;
        final progressValue = progress['progress'] as double;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(AppConstants.primaryColor).withOpacity(0.1),
                const Color(AppConstants.accentColor).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(AppConstants.primaryColor),
              width: 2,
            ),
          ),
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
                  const SizedBox(width: 8),
                  const Text(
                    '未完成拾光',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(AppConstants.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '第 ${currentIndex + 1} / $totalQuestions 题',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(AppConstants.primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await appState.restoreTestState();
                        if (success && mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const QuizScreen(),
                            ),
                          );
                          setState(() {
                            _hasIncompleteTest = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('继续拾光'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppConstants.primaryColor),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      appState.resetTest();
                      await _localStorageService.clearTestState();
                      setState(() {
                        _hasIncompleteTest = false;
                      });
                    },
                    child: const Text('放弃'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建欢迎区域
  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.vintageDecoration,
      child: Column(
        children: [
          Image.asset(
            'assets/images/icon.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            '欢迎来到拾光机',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '通过怀旧问答，唤醒你的时光记忆',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建快速开始区域
  Widget _buildQuickStartSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速开始',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.primaryColor),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickStartCard(
                context,
                '开始拾光',
                '开始你的拾光之旅',
                Icons.play_arrow,
                () async => await _startQuiz(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickStartCard(
                context,
                '时光回忆',
                '记录你的回忆',
                Icons.photo_library,
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MemoryScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickStartCard(
                context,
                '随机题目',
                '探索更多怀旧内容',
                Icons.shuffle,
                () => _startRandomQuiz(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickStartCard(
                context,
                '时光故事馆',
                '阅读怀旧故事',
                Icons.book,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StoryLibraryScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建快速开始卡片
  Widget _buildQuickStartCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.photoPaperDecoration,
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(AppConstants.primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息区域
  Widget _buildStatsSection(BuildContext context, AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '我的拾光数据',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('查看统计'),
                  SizedBox(width: 4),
                  Icon(Icons.bar_chart, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '总题目',
                '${appState.questions.length}',
                Icons.quiz,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                '已收藏',
                '${appState.collectedQuestions.length}',
                Icons.favorite,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                '成就',
                '${appState.unlockedAchievementCount}/${appState.totalAchievementCount}',
                Icons.emoji_events,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.filmBorderDecoration,
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: const Color(AppConstants.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.primaryColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建最近测试区域
  Widget _buildRecentTestsSection(BuildContext context, AppStateProvider appState) {
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
                color: Color(AppConstants.primaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TestRecordListScreen(),
                  ),
                );
              },
              child: const Text('查看全部'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 显示最近的测试记录
        Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            return FutureBuilder<List<TestRecord>>(
              future: appState.getRecentTestRecords(3),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.photoPaperDecoration,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.photoPaperDecoration,
                    child: const Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 40,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '暂无拾光记录',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '开始你的第一次拾光吧！',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: records.map((record) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.photoPaperDecoration,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                '${record.echoAge}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(AppConstants.primaryColor),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '拾光年龄：${record.echoAge}岁',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '准确率：${record.accuracy.toStringAsFixed(1)}% | ${record.totalQuestions}题',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTestTime(record.testTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// 开始测试
  Future<void> _startQuiz(BuildContext context) async {
    final localStorageService = LocalStorageService();
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    // 检查是否有保存的定制配置
    final hasConfig = await localStorageService.hasQuizConfig();
    
    if (hasConfig) {
      // 有保存的配置，直接使用配置启动测试
      print('📋 检测到保存的定制配置，直接启动测试');
      
      try {
        final config = await localStorageService.getQuizConfig();
        if (config != null) {
          // 显示加载提示
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
          
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
          }
          
          // 清除旧的测试状态
          appState.resetTest();
          await localStorageService.clearTestState();
          
          // 使用保存的配置启动测试
          await appState.startTestWithFilters(
            questionCount: questionCount,
            mode: mode,
            categories: categories,
            eras: eras,
            difficulties: difficulties,
          );
          
          // 关闭加载对话框
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          
          // 导航到答题页面
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const QuizScreen()),
            );
          }
          
          print('✅ 使用保存的配置启动测试成功');
        }
      } catch (e) {
        print('❌ 使用保存的配置启动测试失败: $e');
        
        // 关闭加载对话框
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // 显示错误提示并导航到配置页面
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('启动测试失败：$e，请重新配置'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const QuizConfigScreen()),
          );
        }
      }
    } else {
      // 没有保存的配置，显示定制页面
      print('📋 未找到保存的定制配置，显示定制页面');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const QuizConfigScreen()),
      );
    }
  }

  /// 开始随机测试
  Future<void> _startRandomQuiz(BuildContext context) async {
    print('🎲 开始随机测试：清除旧状态并启动随机模式');
    
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final localStorageService = LocalStorageService();
    
    try {
      // 清除旧的测试状态
      appState.resetTest();
      await localStorageService.clearTestState();
      
      print('✅ 测试状态已清除');
      
      // 显示加载提示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // 使用随机模式启动测试（不受定制设置影响，使用所有题目）
      await appState.startTest(
        questionCount: 10, // 默认10道题
        mode: QuestionSelectionMode.random, // 强制使用随机模式
      );
      
      print('✅ 随机测试已启动，共 ${appState.currentTestQuestions.length} 道题目');
      
      // 关闭加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // 导航到答题页面
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const QuizScreen()),
        );
      }
    } catch (e) {
      print('❌ 启动随机测试失败: $e');
      
      // 关闭加载对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动随机测试失败：$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 更新题库
  Future<void> _updateQuestionDatabase(BuildContext context, AppStateProvider appState) async {
    // 检查是否有新题目
    final hasUpdate = await appState.hasQuestionUpdate();
    if (!hasUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无新题目需要更新')),
      );
      return;
    }

    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在更新题库...'),
            ],
          ),
        ),
      );

      // 执行更新
      final success = await appState.updateQuestionDatabase();
      
      // 关闭加载对话框
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('题库更新成功！'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('所有题目已是最新版本'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新出错：$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.favorite,
              color: Color(AppConstants.primaryColor),
              size: 24,
            ),
            SizedBox(width: 8),
            Text('关于拾光机'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 应用简介
              const Text(
                '拾光机是一款专为怀旧爱好者打造的离线问答应用，收录各类怀旧知识题库，涵盖动画、电视剧、流行音乐、历史事件、老物件等多个分类。通过精彩的题目，一起重温经典记忆，挑战你的怀旧知识力！',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              
              // 版本信息
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      '版本：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(AppConstants.appVersion),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 主要功能
              const Text(
                '主要功能',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('离线答题：无需网络，随时随地畅享怀旧问答乐趣'),
              _buildFeatureItem('题库丰富：持续更新，涵盖多类经典题材'),
              _buildFeatureItem('收藏题目：喜欢的题目一键收藏，反复温习'),
              _buildFeatureItem('成就系统：解锁趣味成就，见证成长足迹'),
              _buildFeatureItem('答题统计：自动记录测试成绩，了解进步轨迹'),
              _buildFeatureItem('个性化设置：支持字体大小、语音讲题等个性化体验'),
              _buildFeatureItem('一键分享：将有趣题目分享给好友，唤起更多共鸣'),
              const SizedBox(height: 16),
              
              // 适用人群
              const Text(
                '适用人群',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('怀旧动漫、综艺与影视剧爱好者'),
              _buildFeatureItem('想与朋友回忆童年、共话旧时光的你'),
              _buildFeatureItem('喜欢迎接知识新挑战、增长见识的你'),
              const SizedBox(height: 16),
              
              // 无广告说明
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '所有功能均可免费使用，无广告打扰，致力于还原纯粹的怀旧答题体验。',
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
              const SizedBox(height: 8),
              
              // 结尾
              const Text(
                '快来拾光机，和过去的美好再一次相遇吧！',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(AppConstants.primaryColor),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 构建功能项
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(AppConstants.primaryColor),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化测试时间
  String _formatTestTime(DateTime testTime) {
    final now = DateTime.now();
    final difference = now.difference(testTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
