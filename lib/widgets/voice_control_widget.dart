import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/voice_service.dart';

/// 语音控制组件
class VoiceControlWidget extends StatefulWidget {
  final VoiceService voiceService;
  final bool isEnabled;
  final String currentSpeed;
  final VoidCallback? onToggle;
  final ValueChanged<String>? onSpeedChanged;
  final bool isCompact; // 是否使用紧凑模式（用于AppBar）

  const VoiceControlWidget({
    super.key,
    required this.voiceService,
    required this.isEnabled,
    required this.currentSpeed,
    this.onToggle,
    this.onSpeedChanged,
    this.isCompact = false,
  });

  @override
  State<VoiceControlWidget> createState() => _VoiceControlWidgetState();
}

class _VoiceControlWidgetState extends State<VoiceControlWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      // 在AppBar中使用的简化版本
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _isSpeaking ? _rotationAnimation.value * 2 * 3.14159 : 0,
                child: Icon(
                  widget.isEnabled ? Icons.mic : Icons.mic_off,
                  color: widget.isEnabled 
                      ? const Color(AppConstants.primaryColor)
                      : Colors.grey,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Switch(
            value: widget.isEnabled,
            onChanged: (value) {
              widget.onToggle?.call();
              if (value) {
                _startSpeakingAnimation();
              } else {
                _stopSpeakingAnimation();
              }
            },
            activeColor: const Color(AppConstants.primaryColor),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      );
    }
    
    // 完整版本（用于其他页面）
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isEnabled 
            ? const Color(AppConstants.primaryColor).withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isEnabled 
              ? const Color(AppConstants.primaryColor)
              : Colors.grey,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 语音状态显示
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _isSpeaking ? _rotationAnimation.value * 2 * 3.14159 : 0,
                    child: Icon(
                      widget.isEnabled ? Icons.mic : Icons.mic_off,
                      color: widget.isEnabled 
                          ? const Color(AppConstants.primaryColor)
                          : Colors.grey,
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.isEnabled ? '语音开启' : '语音关闭',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isEnabled 
                        ? const Color(AppConstants.primaryColor)
                        : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: widget.isEnabled,
                onChanged: (value) {
                  widget.onToggle?.call();
                  if (value) {
                    _startSpeakingAnimation();
                  } else {
                    _stopSpeakingAnimation();
                  }
                },
                activeColor: const Color(AppConstants.primaryColor),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          
          // 语音速度控制
          if (widget.isEnabled) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.speed,
                  color: Color(AppConstants.primaryColor),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '速度：',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: DropdownButton<String>(
                    value: widget.currentSpeed,
                    isExpanded: false,
                    underline: Container(),
                    items: AppConstants.voiceSpeeds.keys.map((String speed) {
                      return DropdownMenuItem<String>(
                        value: speed,
                        child: Text(
                          speed,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        widget.onSpeedChanged?.call(newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 开始语音动画
  void _startSpeakingAnimation() {
    setState(() {
      _isSpeaking = true;
    });
    _animationController.repeat();
  }

  /// 停止语音动画
  void _stopSpeakingAnimation() {
    setState(() {
      _isSpeaking = false;
    });
    _animationController.stop();
  }
}

/// 语音播放控制按钮
class VoicePlayButton extends StatefulWidget {
  final VoiceService voiceService;
  final String text;
  final bool isEnabled;
  final String? question; // 题目内容（可选，如果提供则播放完整题目）
  final List<String>? options; // 选项列表（可选，如果提供则播放完整题目）

  const VoicePlayButton({
    super.key,
    required this.voiceService,
    required this.text,
    this.isEnabled = true,
    this.question,
    this.options,
  });

  @override
  State<VoicePlayButton> createState() => _VoicePlayButtonState();
}

class _VoicePlayButtonState extends State<VoicePlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEnabled ? _togglePlayback : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.isEnabled 
                    ? const Color(AppConstants.primaryColor)
                    : Colors.grey,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isEnabled 
                        ? const Color(AppConstants.primaryColor)
                        : Colors.grey).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          );
        },
      ),
    );
  }

  /// 切换播放状态
  Future<void> _togglePlayback() async {
    if (!widget.isEnabled) {
      print('🗣️ ⚠️ 语音功能未启用，无法播放');
      // 显示提示信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先在设置中开启语音读题功能'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // 添加触觉反馈
    HapticFeedback.lightImpact();
    
    if (_isPlaying) {
      try {
        await widget.voiceService.stop();
        setState(() {
          _isPlaying = false;
        });
      } catch (e) {
        print('🗣️ ❌ 停止播放失败: $e');
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // 确保语音服务已初始化
        if (!widget.voiceService.isEnabled) {
          print('🗣️ ⚠️ 语音服务未启用，尝试重新初始化...');
          await widget.voiceService.initialize();
        }
        
        // 如果提供了 question 和 options，使用 speakQuestion 播放完整题目
        if (widget.question != null && widget.options != null && widget.options!.isNotEmpty) {
          print('🗣️ 播放完整题目（包含选项）');
          await widget.voiceService.speakQuestion(
            widget.question!, 
            widget.options!,
            throwOnUnsupported: true, // 手动点击需要错误提示
          );
        } else {
          // 否则只播放文本
          print('🗣️ 播放文本内容');
          await widget.voiceService.speak(
            widget.text,
            throwOnUnsupported: true, // 手动点击需要错误提示
          );
        }
        
        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
        
        // 监听播放完成（通过检查 isSpeaking 状态）
        _checkSpeakingStatus();
      } catch (e, stackTrace) {
        print('🗣️ ❌ 播放失败: $e');
        print('🗣️ ❌ 错误堆栈: $stackTrace');
        setState(() {
          _isPlaying = false;
          _isLoading = false;
        });
        
        // 显示错误提示
        if (mounted) {
          String errorMessage = '播放失败';
          bool isPlatformUnsupported = e.toString().contains('PlatformUnsupportedException') ||
                                       e.toString().contains('不支持语音读题功能') ||
                                       e.toString().contains('MissingPluginException');
          
          if (isPlatformUnsupported) {
            errorMessage = '当前平台不支持语音读题功能';
          } else {
            errorMessage = '播放失败: ${e.toString()}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: Duration(seconds: isPlatformUnsupported ? 3 : 2),
              action: isPlatformUnsupported ? null : SnackBarAction(
                label: '重试',
                onPressed: () => _togglePlayback(),
              ),
            ),
          );
        }
      }
    }
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }
  
  /// 检查语音播放状态
  void _checkSpeakingStatus() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _pollSpeakingStatus();
      }
    });
  }
  
  /// 轮询检查是否还在播放
  void _pollSpeakingStatus() {
    if (!mounted) return;
    
    final isSpeaking = widget.voiceService.isSpeaking;
    if (!isSpeaking && _isPlaying) {
      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
    } else if (isSpeaking && _isPlaying) {
      // 继续检查
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _pollSpeakingStatus();
        }
      });
    }
  }
}

/// 语音状态指示器
class VoiceStatusIndicator extends StatefulWidget {
  final bool isEnabled;
  final bool isSpeaking;

  const VoiceStatusIndicator({
    super.key,
    required this.isEnabled,
    required this.isSpeaking,
  });

  @override
  State<VoiceStatusIndicator> createState() => _VoiceStatusIndicatorState();
}

class _VoiceStatusIndicatorState extends State<VoiceStatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(VoiceStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSpeaking ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isEnabled 
                  ? (widget.isSpeaking 
                      ? const Color(AppConstants.accentColor)
                      : const Color(AppConstants.primaryColor))
                  : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
