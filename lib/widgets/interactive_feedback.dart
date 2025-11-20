import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import 'animated_widgets.dart';

/// 交互反馈工具类
class InteractiveFeedback {
  /// 显示成功提示
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onTap,
  }) {
    // 震动反馈（鸿蒙平台支持，添加容错处理）
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      // 某些平台可能不支持震动，静默失败
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: onTap != null
            ? SnackBarAction(
                label: '查看',
                textColor: Colors.white,
                onPressed: onTap,
              )
            : null,
      ),
    );
  }

  /// 显示错误提示
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    // 震动反馈（鸿蒙平台支持，添加容错处理）
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      // 某些平台可能不支持震动，静默失败
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 显示信息提示
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    // 震动反馈（鸿蒙平台支持，添加容错处理）
    try {
      HapticFeedback.selectionClick();
    } catch (e) {
      // 某些平台可能不支持震动，静默失败
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 显示警告提示
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    // 震动反馈（鸿蒙平台支持，添加容错处理）
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      // 某些平台可能不支持震动，静默失败
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 显示加载提示
  static void showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PulseAnimation(
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppConstants.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 隐藏加载提示
  static void hideLoading(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// 显示确认对话框
  static Future<bool> showConfirm(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
    Color? confirmColor,
  }) async {
    // 震动反馈（鸿蒙平台支持，添加容错处理）
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      // 某些平台可能不支持震动，静默失败
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              try {
                HapticFeedback.selectionClick();
              } catch (e) {
                // 某些平台可能不支持震动，静默失败
              }
              Navigator.of(context).pop(false);
            },
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                HapticFeedback.mediumImpact();
              } catch (e) {
                // 某些平台可能不支持震动，静默失败
              }
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? const Color(AppConstants.primaryColor),
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// 增强的按钮组件
class EnhancedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool enableFeedback;
  final bool enableAnimation;

  const EnhancedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.enableFeedback = true,
    this.enableAnimation = true,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: widget.backgroundColor ?? const Color(AppConstants.primaryColor),
      borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
      child: InkWell(
        onTapDown: widget.onPressed != null
            ? (_) {
                if (widget.enableFeedback) {
                  try {
                    HapticFeedback.mediumImpact();
                  } catch (e) {
                    // 某些平台可能不支持震动，静默失败
                  }
                }
                if (widget.enableAnimation) {
                  setState(() => _isPressed = true);
                  _controller.forward();
                }
              }
            : null,
        onTapUp: widget.onPressed != null
            ? (_) {
                if (widget.enableAnimation) {
                  _controller.reverse().then((_) {
                    if (mounted) {
                      setState(() => _isPressed = false);
                    }
                  });
                }
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: widget.onPressed != null
            ? () {
                if (widget.enableAnimation) {
                  _controller.reverse();
                  setState(() => _isPressed = false);
                }
              }
            : null,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        child: Container(
          padding: widget.padding ?? const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: (widget.backgroundColor ?? const Color(AppConstants.primaryColor))
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: widget.foregroundColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.enableAnimation) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: button,
          );
        },
      );
    }

    return button;
  }
}

/// 选项卡片组件（带增强交互）
class InteractiveOptionCard extends StatefulWidget {
  final String optionText;
  final String optionLabel;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;
  final int index;

  const InteractiveOptionCard({
    super.key,
    required this.optionText,
    required this.optionLabel,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    this.onTap,
    required this.index,
  });

  @override
  State<InteractiveOptionCard> createState() => _InteractiveOptionCardState();
}

class _InteractiveOptionCardState extends State<InteractiveOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(InteractiveOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        try {
          HapticFeedback.mediumImpact();
        } catch (e) {
          // 某些平台可能不支持震动，静默失败
        }
        _controller.forward().then((_) {
          _controller.reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (widget.isWrong) {
      backgroundColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red;
      textColor = Colors.red;
    } else if (widget.isCorrect) {
      backgroundColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
      textColor = Colors.green;
    } else if (widget.isSelected) {
      backgroundColor = const Color(AppConstants.primaryColor).withOpacity(0.1);
      borderColor = const Color(AppConstants.primaryColor);
      textColor = const Color(AppConstants.primaryColor);
    } else {
      backgroundColor = Colors.white;
      borderColor = Colors.grey.withOpacity(0.3);
      textColor = Colors.black87;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              // 波纹效果
              splashColor: widget.isCorrect 
                  ? Colors.green.withOpacity(0.3)
                  : widget.isWrong
                      ? Colors.red.withOpacity(0.3)
                      : const Color(AppConstants.primaryColor).withOpacity(0.3),
              highlightColor: widget.isCorrect
                  ? Colors.green.withOpacity(0.1)
                  : widget.isWrong
                      ? Colors.red.withOpacity(0.1)
                      : const Color(AppConstants.primaryColor).withOpacity(0.1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: widget.isSelected || widget.isCorrect || widget.isWrong ? 2 : 1,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: borderColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.optionLabel,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.optionText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (widget.isCorrect)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  if (widget.isWrong)
                    const Icon(Icons.cancel, color: Colors.red, size: 24),
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }
}

/// 页面切换动画包装器
class PageTransitionWrapper extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

/// 增强的加载指示器
class EnhancedLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const EnhancedLoadingIndicator({
    super.key,
    this.message,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulseAnimation(
            child: SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(AppConstants.primaryColor),
                ),
                strokeWidth: 3,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 空状态组件（带动画）
class AnimatedEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  const AnimatedEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimationUtils.scaleIn(
              child: Icon(
                icon,
                size: 80,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            AnimationUtils.fadeIn(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimationUtils.fadeIn(
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 24),
              AnimationUtils.slideIn(
                child: EnhancedButton(
                  onPressed: onAction,
                  child: Text(actionText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

