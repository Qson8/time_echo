import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../services/nostalgic_time_machine_service.dart';

/// 沉浸式怀旧体验界面
class ImmersiveNostalgicExperience extends StatefulWidget {
  const ImmersiveNostalgicExperience({super.key});

  @override
  State<ImmersiveNostalgicExperience> createState() => _ImmersiveNostalgicExperienceState();
}

class _ImmersiveNostalgicExperienceState extends State<ImmersiveNostalgicExperience>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late AnimationController _textController;
  
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _textAnimation;
  
  final NostalgicTimeMachineService _timeMachineService = NostalgicTimeMachineService();
  final Random _random = Random();
  
  String _currentTheme = '80s';
  List<Particle> _particles = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeParticles();
    _loadTimeMachineExperience();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));

    _backgroundController.repeat();
    _particleController.repeat(reverse: true);
    _textController.forward();
  }

  /// 初始化粒子效果
  void _initializeParticles() {
    _particles = List.generate(50, (index) => Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 3 + 1,
      speed: _random.nextDouble() * 0.02 + 0.01,
      opacity: _random.nextDouble() * 0.5 + 0.3,
    ));
  }

  /// 加载时光机体验
  Future<void> _loadTimeMachineExperience() async {
    try {
      final experience = await _timeMachineService.generateTimeMachineExperience();
      setState(() {
        _currentTheme = experience.theme;
        _isInitialized = true;
      });
    } catch (e) {
      print('加载时光机体验失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = _timeMachineService.getTimeMachineTheme(_currentTheme);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(theme['color']).withOpacity(0.8),
              Color(theme['color']).withOpacity(0.6),
              Color(theme['color']).withOpacity(0.4),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 背景动画
            _buildBackgroundAnimation(),
            
            // 粒子效果
            _buildParticleEffect(),
            
            // 主要内容
            _buildMainContent(theme),
            
            // 时光机控制面板
            _buildTimeMachineControlPanel(),
          ],
        ),
      ),
    );
  }

  /// 构建背景动画
  Widget _buildBackgroundAnimation() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPainter(_backgroundAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  /// 构建粒子效果
  Widget _buildParticleEffect() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles, _particleAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  /// 构建主要内容
  Widget _buildMainContent(Map<String, dynamic> theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 标题区域
            _buildTitleSection(theme),
            
            const SizedBox(height: 40),
            
            // 时光机状态
            _buildTimeMachineStatus(),
            
            const SizedBox(height: 40),
            
            // 怀旧内容
            Expanded(
              child: _buildNostalgicContent(),
            ),
            
            // 操作按钮
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 构建标题区域
  Widget _buildTitleSection(Map<String, dynamic> theme) {
    return ScaleTransition(
      scale: _textAnimation,
      child: Column(
        children: [
          Icon(
            theme['icon'],
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            theme['name'],
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            theme['description'],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建时光机状态
  Widget _buildTimeMachineStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '时光机状态',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem('时间', '1980-1999', Icons.access_time),
              _buildStatusItem('状态', '运行中', Icons.play_circle),
              _buildStatusItem('模式', '怀旧', Icons.star),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建状态项
  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 构建怀旧内容
  Widget _buildNostalgicContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '怀旧时光',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // 时光记忆卡片
          Expanded(
            child: ListView(
              children: [
                _buildMemoryCard(
                  '经典音乐',
                  '那些年我们一起听的歌',
                  Icons.music_note,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildMemoryCard(
                  '经典电影',
                  '银幕上的永恒瞬间',
                  Icons.movie,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                _buildMemoryCard(
                  '历史事件',
                  '见证时代的变迁',
                  Icons.history,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建记忆卡片
  Widget _buildMemoryCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white70,
            size: 20,
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            '开始时光之旅',
            Icons.play_arrow,
            Colors.green,
            () => _startTimeJourney(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            '切换主题',
            Icons.palette,
            Colors.purple,
            () => _switchTheme(),
          ),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建时光机控制面板
  Widget _buildTimeMachineControlPanel() {
    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildControlButton(Icons.settings, () => _openSettings()),
            const SizedBox(height: 8),
            _buildControlButton(Icons.info, () => _showInfo()),
            const SizedBox(height: 8),
            _buildControlButton(Icons.exit_to_app, () => _exitExperience()),
          ],
        ),
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  /// 开始时光之旅
  void _startTimeJourney() {
    // 播放时光机音效
    _timeMachineService.playTimeMachineSound();
    
    // 显示时光之旅界面
    showDialog(
      context: context,
      builder: (context) => _buildTimeJourneyDialog(),
    );
  }

  /// 切换主题
  void _switchTheme() {
    final themes = _timeMachineService.getAllThemes();
    final currentIndex = themes.indexWhere((theme) => theme['id'] == _currentTheme);
    final nextIndex = (currentIndex + 1) % themes.length;
    
    setState(() {
      _currentTheme = themes[nextIndex]['id'];
    });
    
    HapticFeedback.mediumImpact();
  }

  /// 打开设置
  void _openSettings() {
    // 实现设置功能
  }

  /// 显示信息
  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('时光机信息'),
        content: const Text('欢迎使用拾光机时光机！\n\n在这里，你可以：\n• 体验不同年代的怀旧主题\n• 开始你的时光之旅\n• 探索怀旧的经典内容\n• 享受沉浸式的怀旧体验'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 退出体验
  void _exitExperience() {
    Navigator.pop(context);
  }

  /// 构建时光之旅对话框
  Widget _buildTimeJourneyDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '时光之旅',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '准备好开始你的怀旧时光之旅了吗？',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // 开始时光之旅
                    },
                    child: const Text('开始'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 背景绘制器
class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // 绘制动态背景图案
    for (int i = 0; i < 20; i++) {
      final x = (size.width * (i / 20) + animationValue * 100) % size.width;
      final y = size.height * (i / 20);
      
      canvas.drawCircle(
        Offset(x, y),
        20 + (animationValue * 10),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 粒子绘制器
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = (particle.x + animationValue * particle.speed) % 1.0;
      final y = (particle.y + animationValue * particle.speed * 0.5) % 1.0;
      
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint..color = Colors.white.withOpacity(particle.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 粒子数据模型
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}
