import 'package:flutter/material.dart';
import 'dart:math';

/// 庆祝动画组件（正确答案时的烟花/星星效果）
class CelebrationAnimation extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;

  const CelebrationAnimation({
    super.key,
    required this.child,
    this.isActive = false,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<CelebrationAnimation> createState() => _CelebrationAnimationState();
}

class _CelebrationAnimationState extends State<CelebrationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  // 移除缩放和旋转动画
  // late Animation<double> _scaleAnimation;
  // late Animation<double> _rotationAnimation;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // 移除缩放动画
    // _scaleAnimation = Tween<double>(
    //   begin: 1.0,
    //   end: 1.15,
    // ).animate(CurvedAnimation(
    //   parent: _controller,
    //   curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    // ));

    // 移除旋转动画
    // _rotationAnimation = Tween<double>(
    //   begin: 0.0,
    //   end: 0.1,
    // ).animate(CurvedAnimation(
    //   parent: _controller,
    //   curve: Curves.easeInOut,
    // ));

    if (widget.isActive) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(CelebrationAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller.forward(from: 0.0);
    _generateParticles();
  }

  void _generateParticles() {
    _particles.clear();
    // 生成星星粒子
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        vx: (_random.nextDouble() - 0.5) * 0.02,
        vy: (_random.nextDouble() - 0.5) * 0.02,
        color: [
          Colors.yellow,
          Colors.orange,
          Colors.green,
          Colors.blue,
        ][_random.nextInt(4)],
        size: 4 + _random.nextDouble() * 4,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // 移除缩放和旋转动画，直接显示子组件
            widget.child,
            // 粒子效果
            if (widget.isActive && _controller.value > 0)
              ..._particles.map((particle) {
                final progress = _controller.value;
                return Positioned(
                  left: (particle.x + particle.vx * progress * 10) * MediaQuery.of(context).size.width,
                  top: (particle.y + particle.vy * progress * 10) * MediaQuery.of(context).size.height,
                  child: Opacity(
                    opacity: 1.0 - progress,
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        color: particle.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: particle.color.withOpacity(0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
          ],
        );
      },
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

