import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/test_record.dart';
import '../services/app_state_provider.dart';
import '../services/local_storage_service.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';
import 'quiz_config_screen.dart';
import 'memory_detail_screen.dart';
import '../services/memory_service.dart';
import '../models/memory_record.dart';

/// 测试结果页面
class QuizResultScreen extends StatefulWidget {
  final TestRecord testRecord;

  const QuizResultScreen({
    super.key,
    required this.testRecord,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
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

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
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
      appBar: AppBar(
        title: const Text('拾光结果'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => _goHome(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 拾光年龄卡片
                    _buildEchoAgeCard(),
                    
                    const SizedBox(height: 32),
                    
                    // 详细统计
                    _buildStatsCards(),
                    
                    const SizedBox(height: 24),
                    
                    // 评语
                    _buildCommentCard(),
                    
                    const SizedBox(height: 24),
                    
                    // 记录回忆提示卡片
                    _buildMemoryPromptCard(context),
                    
                    const SizedBox(height: 48),
                    
                    // 操作按钮（添加底部间距）
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: _buildActionButtons(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建拾光年龄卡片
  Widget _buildEchoAgeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryColor),
            const Color(AppConstants.primaryColor).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryColor).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '你的拾光年龄',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.testRecord.echoAge}',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      '岁',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '正确率',
            '${widget.testRecord.accuracy.toStringAsFixed(1)}%',
            Icons.check_circle,
            const Color(AppConstants.accentColor),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            '答题数',
            '${widget.testRecord.correctAnswers}/${widget.testRecord.totalQuestions}',
            Icons.quiz,
            const Color(AppConstants.primaryColor),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            '用时',
            '${(widget.testRecord.totalTime / 60).toStringAsFixed(1)}分钟',
            Icons.timer,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
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

  /// 构建评语卡片
  Widget _buildCommentCard() {
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
                '拾光评语',
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
            widget.testRecord.comment,
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

  /// 构建记录回忆提示卡片
  Widget _buildMemoryPromptCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.pink.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.purple,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '这题让你想起什么？',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '记录下这段答题带来的回忆吧，让它成为你独特的怀旧档案～',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _recordMemory(context),
              icon: const Icon(Icons.edit),
              label: const Text('记录回忆'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 记录回忆
  Future<void> _recordMemory(BuildContext context) async {
    final memoryService = MemoryService();
    
    // 根据测试记录推断年代和分类
    // 从categoryScores中获取最高分的分类
    String dominantCategory = '影视';
    if (widget.testRecord.categoryScores.isNotEmpty) {
      final sorted = widget.testRecord.categoryScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.isNotEmpty) {
        dominantCategory = sorted.first.key;
      }
    }
    
    // 根据拾光年龄推断年代
    String era = '90年代';
    if (widget.testRecord.echoAge <= 30) {
      era = '90年代';
    } else if (widget.testRecord.echoAge <= 45) {
      era = '80年代';
    } else {
      era = '80年代';
    }
    
    // 生成默认回忆内容提示（用户自己写内容）
    final defaultContentHint = '这次拾光之旅让我想起了...';
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MemoryDetailScreen(
          memory: MemoryRecord(
            id: 0, // 0表示新建
            content: defaultContentHint,
            era: era,
            category: dominantCategory,
            memoryDate: widget.testRecord.testTime,
            createTime: DateTime.now(),
            mood: '怀念',
            tags: ['拾光测试'],
          ),
        ),
      ),
    );
    
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('回忆已记录到时光回忆'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              print('🔄 再来一次按钮被点击');
              await _startNewTest(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColor),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '再来一次',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 开始新测试
  Future<void> _startNewTest(BuildContext context) async {
    print('🔄 再来一次：清除旧测试状态并导航到定制页面');
    
    try {
      // 获取 AppStateProvider 实例
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final localStorageService = LocalStorageService();
      
      // 清除测试状态
      appState.resetTest();
      await localStorageService.clearTestState();
      
      print('✅ 测试状态已清除');
      
      // 导航到定制页面，让用户重新选择配置
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QuizConfigScreen()),
        );
      }
    } catch (e) {
      print('❌ 清除测试状态失败: $e');
      // 即使失败也导航到定制页面
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QuizConfigScreen()),
        );
      }
    }
  }

  /// 返回首页
  void _goHome(BuildContext context) {
    print('🏠 返回首页按钮被点击');
    try {
      // 先确保context有效
      if (!mounted) {
        print('🏠 ⚠️ Widget已卸载，无法导航');
        return;
      }
      
      print('🏠 开始导航到首页...');
      // 使用popUntil清除所有路由，然后导航到首页
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
      print('🏠 ✅ 导航到首页成功');
    } catch (e, stackTrace) {
      print('🏠 ❌ 返回首页失败: $e');
      print('🏠 ❌ 错误堆栈: $stackTrace');
      
      // 备用方案：尝试多次pop
      try {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e2) {
        print('🏠 ❌ 备用导航方案也失败: $e2');
      }
    }
  }
}
