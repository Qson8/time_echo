import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../constants/app_constants.dart';
import '../services/font_size_service.dart';
import '../services/theme_service.dart';

/// 无障碍访问工具类
class AccessibilityUtils {
  /// 获取无障碍标签
  static String getAccessibilityLabel(String text, {String? hint}) {
    if (hint != null) {
      return '$text, $hint';
    }
    return text;
  }

  /// 获取语义化描述
  static String getSemanticDescription(String action, String target) {
    return '$action $target';
  }

  /// 检查是否为老年用户模式
  static bool isElderlyMode(BuildContext context) {
    final themeService = ThemeService();
    // 检查当前主题是否为老年友好主题
    return themeService.currentTheme == ThemeType.elderly;
  }

  /// 获取适合的字体大小
  static double getAccessibleFontSize(BuildContext context, double baseFontSize) {
    final fontSizeService = FontSizeService();
    final scaleFactor = fontSizeService.getFontScaleFactor();
    return baseFontSize * scaleFactor;
  }

  /// 获取适合的按钮尺寸
  static Size getAccessibleButtonSize(BuildContext context) {
    final isElderly = isElderlyMode(context);
    if (isElderly) {
      return const Size(120, 48);
    }
    return const Size(100, 40);
  }

  /// 获取适合的间距
  static double getAccessibleSpacing(BuildContext context) {
    final isElderly = isElderlyMode(context);
    if (isElderly) {
      return 16.0;
    }
    return 12.0;
  }
}

/// 无障碍按钮组件
class AccessibleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticLabel;
  final String? semanticHint;
  final ButtonStyle? style;
  final bool isLoading;

  const AccessibleButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.semanticLabel,
    this.semanticHint,
    this.style,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isElderly = AccessibilityUtils.isElderlyMode(context);
    final buttonSize = AccessibilityUtils.getAccessibleButtonSize(context);
    
    return Semantics(
      label: semanticLabel ?? text,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style ?? ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryColor),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isElderly ? 16 : 12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isElderly ? 32 : 24,
            vertical: isElderly ? 16 : 12,
          ),
          minimumSize: buttonSize,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: isElderly ? 20 : 18,
                    ),
                    SizedBox(width: isElderly ? 12 : 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: AccessibilityUtils.getAccessibleFontSize(
                        context,
                        isElderly ? 18 : 16,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 无障碍图标按钮组件
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final Color? color;
  final double? size;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isElderly = AccessibilityUtils.isElderlyMode(context);
    final iconSize = size ?? (isElderly ? 28.0 : 24.0);
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
        onPressed: onPressed,
        iconSize: iconSize,
        padding: EdgeInsets.all(isElderly ? 16 : 12),
        constraints: BoxConstraints(
          minWidth: isElderly ? 56 : 48,
          minHeight: isElderly ? 56 : 48,
        ),
      ),
    );
  }
}

/// 无障碍文本组件
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final String? semanticLabel;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isElderly = AccessibilityUtils.isElderlyMode(context);
    final accessibleStyle = style?.copyWith(
      fontSize: style?.fontSize != null
          ? AccessibilityUtils.getAccessibleFontSize(context, style!.fontSize!)
          : null,
    );

    return Semantics(
      label: semanticLabel ?? text,
      child: Text(
        text,
        style: accessibleStyle,
        textAlign: textAlign,
        maxLines: maxLines,
      ),
    );
  }
}

/// 无障碍卡片组件
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final BoxDecoration? decoration;

  const AccessibleCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final isElderly = AccessibilityUtils.isElderlyMode(context);
    final accessiblePadding = padding ?? EdgeInsets.all(
      AccessibilityUtils.getAccessibleSpacing(context),
    );
    final accessibleMargin = margin ?? EdgeInsets.symmetric(
      vertical: isElderly ? 12 : 8,
    );

    Widget card = Container(
      padding: accessiblePadding,
      margin: accessibleMargin,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      card = Semantics(
        label: semanticLabel,
        hint: semanticHint,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// 无障碍开关组件
class AccessibleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;
  final String? semanticHint;

  const AccessibleSwitch({
    super.key,
    required this.value,
    this.onChanged,
    required this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final isElderly = AccessibilityUtils.isElderlyMode(context);
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      toggled: value,
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(AppConstants.primaryColor),
        materialTapTargetSize: isElderly 
            ? MaterialTapTargetSize.padded 
            : MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 无障碍滑块组件
class AccessibleSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String semanticLabel;
  final String? semanticHint;

  const AccessibleSlider({
    super.key,
    required this.value,
    this.onChanged,
    required this.min,
    required this.max,
    this.divisions,
    required this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final isElderly = AccessibilityUtils.isElderlyMode(context);
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      slider: true,
      value: value.toString(),
      onIncrease: onChanged != null && value < max
          ? () => onChanged!(value + (divisions != null ? (max - min) / divisions! : 1))
          : null,
      onDecrease: onChanged != null && value > min
          ? () => onChanged!(value - (divisions != null ? (max - min) / divisions! : 1))
          : null,
      child: Slider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: const Color(AppConstants.primaryColor),
        inactiveColor: Colors.grey[300],
      ),
    );
  }
}

/// 无障碍列表项组件
class AccessibleListItem extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String semanticLabel;
  final String? semanticHint;

  const AccessibleListItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final isElderly = AccessibilityUtils.isElderlyMode(context);
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      onTap: onTap,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isElderly ? 20 : 16,
          vertical: isElderly ? 12 : 8,
        ),
        minVerticalPadding: isElderly ? 16 : 12,
      ),
    );
  }
}

/// 无障碍对话框组件
class AccessibleDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final String? semanticLabel;

  const AccessibleDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isElderly = AccessibilityUtils.isElderlyMode(context);
    
    return Semantics(
      label: semanticLabel ?? title,
      child: AlertDialog(
        title: AccessibleText(
          title,
          style: TextStyle(
            fontSize: AccessibilityUtils.getAccessibleFontSize(
              context,
              isElderly ? 20 : 18,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: content,
        actions: actions,
        contentPadding: EdgeInsets.all(isElderly ? 24 : 20),
        actionsPadding: EdgeInsets.all(isElderly ? 16 : 12),
      ),
    );
  }
}

/// 无障碍提示组件
class AccessibleTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final Duration? duration;

  const AccessibleTooltip({
    super.key,
    required this.message,
    required this.child,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      child: Tooltip(
        message: message,
        child: child,
      ),
    );
  }
}
