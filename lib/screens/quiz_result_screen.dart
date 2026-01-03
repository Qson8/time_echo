import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/test_record.dart';
import '../services/app_state_provider.dart';
import '../services/local_storage_service.dart';
import 'enhanced_home_screen.dart';
import 'quiz_screen.dart';
import 'quiz_config_screen.dart';
import 'memory_capsule_creation_screen.dart';
import 'memory_capsule_detail_screen.dart';
import '../services/memory_capsule_service.dart';
import '../models/memory_capsule.dart';
import '../services/share_service.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/theme_adapter.dart';

/// 拾光结果页面
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
  
  MemoryCapsule? _relatedMemory; // 关联的记忆胶囊
  bool _isLoadingMemory = true; // 是否正在加载记忆

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
    _checkRelatedMemory(); // 检查是否有对应的记忆
  }
  
  /// 检查是否有对应的记忆胶囊
  Future<void> _checkRelatedMemory() async {
    try {
      final memoryCapsuleService = MemoryCapsuleService();
      await memoryCapsuleService.initialize();
      final allCapsules = await memoryCapsuleService.getAllCapsules();
      
      // 查找与当前拾光记录关联的记忆胶囊
      // 匹配条件：memoryDate 与 testTime 相同（允许1秒误差），且包含"拾光"标签
      final testTime = widget.testRecord.testTime;
      MemoryCapsule? relatedMemory;
      
      try {
        relatedMemory = allCapsules.firstWhere(
          (capsule) {
            // 检查时间是否匹配（允许1秒误差）
            if (capsule.memoryDate == null) return false;
            final timeDiff = (capsule.memoryDate!.difference(testTime).inSeconds).abs();
            final hasEchoTag = capsule.hasTag('拾光');
            return timeDiff <= 1 && hasEchoTag;
          },
        );
      } catch (e) {
        // 没有找到匹配的记忆
        relatedMemory = null;
      }
      
      if (mounted) {
        setState(() {
          _relatedMemory = relatedMemory;
          _isLoadingMemory = false;
        });
      }
    } catch (e) {
      print('检查关联记忆失败: $e');
      if (mounted) {
        setState(() {
          _relatedMemory = null;
          _isLoadingMemory = false;
        });
      }
    }
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
        title: Text(
          '拾光结果',
          style: TextStyle(
            color: ThemeAdapter.getTextColor(context),
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: ThemeAdapter.getSurfaceColor(context),
        iconTheme: IconThemeData(
          color: ThemeAdapter.getIconColor(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
              onPressed: () => _shareResult(context),
              tooltip: '分享成绩',
            ),
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
    return Builder(
      builder: (context) {
        final isDark = ThemeAdapter.isDarkMode(context);
        final primaryColor = ThemeAdapter.getPrimaryColor(context);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(isDark ? 0.4 : 0.3),
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
      },
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
    return Builder(
      builder: (context) {
        final isDark = ThemeAdapter.isDarkMode(context);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeAdapter.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.4 : 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
          Builder(
            builder: (context) => Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: ThemeAdapter.getSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  /// 构建评语卡片
  Widget _buildCommentCard() {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: ThemeAdapter.getPhotoPaperDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: ThemeAdapter.getPrimaryColor(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '拾光评语',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeAdapter.getPrimaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.testRecord.comment,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: ThemeAdapter.getTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建记录回忆提示卡片
  Widget _buildMemoryPromptCard(BuildContext context) {
    final isDark = ThemeAdapter.isDarkMode(context);
    
    // 如果正在加载，显示加载状态
    if (_isLoadingMemory) {
      return Builder(
        builder: (context) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(isDark ? 0.2 : 0.1),
                Colors.pink.withOpacity(isDark ? 0.2 : 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.purple.withOpacity(isDark ? 0.5 : 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ThemeAdapter.getPrimaryColor(context),
              ),
            ),
          ),
        ),
      );
    }
    
    // 如果已记录回忆，显示已记录状态
    final hasMemory = _relatedMemory != null;
    
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasMemory
                ? [
                    Colors.green.withOpacity(isDark ? 0.2 : 0.1),
                    Colors.teal.withOpacity(isDark ? 0.2 : 0.1),
                  ]
                : [
                    Colors.purple.withOpacity(isDark ? 0.2 : 0.1),
                    Colors.pink.withOpacity(isDark ? 0.2 : 0.1),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasMemory
                ? Colors.green.withOpacity(isDark ? 0.5 : 0.3)
                : Colors.purple.withOpacity(isDark ? 0.5 : 0.3),
            width: 1,
          ),
        ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                hasMemory ? Icons.check_circle : Icons.favorite,
                color: hasMemory ? Colors.green : Colors.purple,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                hasMemory ? '记忆已记录' : '这题让你想起什么？',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hasMemory ? Colors.green.shade700 : Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) => Text(
              hasMemory
                  ? '你已经为这次拾光之旅记录了回忆，可以在记忆胶囊中查看～'
                  : '记录下这段答题带来的回忆吧，让它成为你独特的怀旧档案～',
              style: TextStyle(
                fontSize: 14,
                color: ThemeAdapter.getTextColor(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          if (hasMemory) ...[
            // 已记录状态：显示查看记忆按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewMemory(context),
                icon: const Icon(Icons.visibility),
                label: const Text('查看记忆'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 编辑记忆按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _editMemory(context),
                icon: const Icon(Icons.edit),
                label: const Text('编辑记忆'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade700),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            // 未记录状态：显示记录回忆按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _recordMemory(context),
                icon: const Icon(Icons.edit),
                label: const Text('记忆胶囊'),
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
        ],
      ),
      ),
    );
  }
  
  /// 查看记忆胶囊
  Future<void> _viewMemory(BuildContext context) async {
    if (_relatedMemory == null) return;
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MemoryCapsuleDetailScreen(
          capsule: _relatedMemory!,
        ),
      ),
    );
    
    // 如果编辑了记忆胶囊，重新检查
    if (result == true && mounted) {
      await _checkRelatedMemory();
    }
  }
  
  /// 编辑记忆胶囊
  Future<void> _editMemory(BuildContext context) async {
    if (_relatedMemory == null) return;
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MemoryCapsuleCreationScreen(
          capsule: _relatedMemory!,
        ),
      ),
    );
    
    // 如果编辑成功，重新检查记忆胶囊
    if (result == true && mounted) {
      await _checkRelatedMemory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('记忆胶囊已更新'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 记录记忆（使用记忆胶囊）
  Future<void> _recordMemory(BuildContext context) async {
    final memoryCapsuleService = MemoryCapsuleService();
    await memoryCapsuleService.initialize();
    
    // 根据拾光记录推断年代和分类
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
    
    // 导航到记忆胶囊创建页面（标题为空，快速创建）
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MemoryCapsuleCreationScreen(
          capsule: MemoryCapsule(
            id: 0, // 0表示新建
            questionId: null,
            title: null, // 快速创建时标题为空
            content: defaultContentHint,
            imagePath: null,
            audioPath: null,
            createdAt: DateTime.now(),
            memoryDate: widget.testRecord.testTime,
            tags: ['拾光'],
            era: era,
            category: dominantCategory,
            mood: '怀念',
            location: null,
          ),
        ),
      ),
    );
    
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('回忆已记录到记忆胶囊'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    return Builder(
      builder: (context) => Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                print('🔄 再来一次按钮被点击');
                await _startNewTest(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeAdapter.getPrimaryColor(context),
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
      ),
    );
  }

  /// 开始新拾光
  Future<void> _startNewTest(BuildContext context) async {
    print('🔄 再来一次：清除旧拾光状态并导航到定制页面');
    
    try {
      // 获取 AppStateProvider 实例
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final localStorageService = LocalStorageService();
      
      // 清除拾光状态
      appState.resetTest();
      await localStorageService.clearTestState();
      
      print('✅ 拾光状态已清除');
      
      // 导航到定制页面，让用户重新选择配置
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QuizConfigScreen()),
        );
      }
    } catch (e) {
      print('❌ 清除拾光状态失败: $e');
      // 即使失败也导航到定制页面
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QuizConfigScreen()),
        );
      }
    }
  }

  /// 返回首页
  /// 分享成绩
  Future<void> _shareResult(BuildContext context) async {
    try {
      final shareService = ShareService();
      
      // 获取成就列表（如果有）
      final achievements = <String>[];
      if (widget.testRecord.accuracy >= 0.9) {
        achievements.add('答题高手');
      }
      if (widget.testRecord.totalQuestions >= 20) {
        achievements.add('挑战达人');
      }
      
      // 生成分享文本（由于screenshot包在鸿蒙平台不兼容，使用文本分享）
      final shareText = shareService.generateShareText(
        echoAge: widget.testRecord.echoAge,
        accuracy: widget.testRecord.accuracy,
        totalQuestions: widget.testRecord.totalQuestions,
        correctAnswers: widget.testRecord.correctAnswers,
        achievements: achievements,
      );
      
      if (mounted) {
        // 直接分享文本（鸿蒙平台可能不支持，添加错误处理）
        try {
          await Share.share(shareText, subject: '拾光机 - 我的拾光成绩');
        } catch (e) {
          // 如果分享失败（如鸿蒙平台不支持），显示文本内容供用户复制
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: ThemeAdapter.getSurfaceColor(context),
                title: Builder(
                  builder: (context) => Text(
                    '分享内容',
                    style: TextStyle(
                      color: ThemeAdapter.getTextColor(context),
                    ),
                  ),
                ),
                content: SingleChildScrollView(
                  child: SelectableText(
                    shareText,
                    style: TextStyle(
                      color: ThemeAdapter.getTextColor(context),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Builder(
                      builder: (context) => Text(
                        '关闭',
                        style: TextStyle(
                          color: ThemeAdapter.getPrimaryColor(context),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      // 复制到剪贴板
                      await Clipboard.setData(ClipboardData(text: shareText));
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制到剪贴板')),
                        );
                      }
                    },
                    child: Builder(
                      builder: (context) => Text(
                        '复制',
                        style: TextStyle(
                          color: ThemeAdapter.getPrimaryColor(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      print('分享成绩失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

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
          MaterialPageRoute(builder: (context) => const EnhancedHomeScreen()),
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
