import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import 'animated_widgets.dart';

/// 增强的卡片组件
class EnhancedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool enableAnimation;
  final BoxDecoration? decoration;

  const EnhancedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.enableAnimation = true,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: decoration ?? AppTheme.photoPaperDecoration,
      child: child,
    );

    if (onTap != null) {
      card = AnimatedButton(
        onPressed: onTap,
        child: card,
      );
    }

    if (enableAnimation) {
      return AnimationUtils.fadeIn(
        child: AnimationUtils.slideIn(
          child: card,
        ),
      );
    }

    return card;
  }
}

/// 增强的按钮组件
class EnhancedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonStyle? style;
  final bool isLoading;
  final bool enableAnimation;

  const EnhancedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.style,
    this.isLoading = false,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style ?? ElevatedButton.styleFrom(
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
    );

    if (enableAnimation) {
      return AnimationUtils.scaleIn(child: button);
    }

    return button;
  }
}

/// 增强的图标按钮组件
class EnhancedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final String? tooltip;
  final bool enableAnimation;

  const EnhancedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size,
    this.tooltip,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconButton = IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: onPressed,
      tooltip: tooltip,
    );

    if (enableAnimation) {
      return AnimatedButton(
        onPressed: onPressed,
        child: iconButton,
      );
    }

    return iconButton;
  }
}

/// 增强的列表项组件
class EnhancedListItem extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enableAnimation;

  const EnhancedListItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget listItem = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );

    if (enableAnimation) {
      return AnimationUtils.fadeIn(
        child: AnimationUtils.slideIn(
          offset: const Offset(50, 0),
          child: listItem,
        ),
      );
    }

    return listItem;
  }
}

/// 增强的进度指示器
class EnhancedProgressIndicator extends StatelessWidget {
  final double progress;
  final String? label;
  final Color? color;
  final double height;
  final bool showPercentage;

  const EnhancedProgressIndicator({
    super.key,
    required this.progress,
    this.label,
    this.color,
    this.height = 8.0,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showPercentage)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        AnimatedProgressBar(
          progress: progress,
          height: height,
          progressColor: color ?? const Color(AppConstants.primaryColor),
        ),
      ],
    );
  }
}

/// 增强的徽章组件
class EnhancedBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool enableAnimation;

  const EnhancedBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(AppConstants.primaryColor),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    if (enableAnimation) {
      return AnimationUtils.scaleIn(child: badge);
    }

    return badge;
  }
}

/// 增强的开关组件
class EnhancedSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool enableAnimation;

  const EnhancedSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.enableAnimation = true,
  });

  @override
  State<EnhancedSwitch> createState() => _EnhancedSwitchState();
}

class _EnhancedSwitchState extends State<EnhancedSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(EnhancedSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    Widget switchWidget = Row(
      children: [
        if (widget.label != null) ...[
          Expanded(
            child: Text(
              widget.label!,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
        ],
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return GestureDetector(
              onTap: () => widget.onChanged?.call(!widget.value),
              child: Container(
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color.lerp(
                    Colors.grey[300],
                    const Color(AppConstants.primaryColor),
                    _animation.value,
                  ),
                ),
                child: Transform.translate(
                  offset: Offset(_animation.value * 20, 0),
                  child: Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );

    if (widget.enableAnimation) {
      return AnimationUtils.fadeIn(child: switchWidget);
    }

    return switchWidget;
  }
}

/// 增强的加载指示器
class EnhancedLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const EnhancedLoadingIndicator({
    super.key,
    this.message,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseAnimation(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? const Color(AppConstants.primaryColor),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 增强的空状态组件
class EnhancedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EnhancedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimationUtils.scaleIn(
              child: Icon(
                icon,
                size: 80,
                color: Colors.grey[400],
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
                textAlign: TextAlign.center,
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
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              AnimationUtils.scaleIn(
                child: EnhancedButton(
                  text: buttonText!,
                  onPressed: onButtonPressed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
