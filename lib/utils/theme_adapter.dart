import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// 主题适配工具类
/// 用于在深色模式下自动适配颜色
class ThemeAdapter {
  /// 获取背景颜色（适配深色模式）
  static Color getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.scaffoldBackgroundColor;
  }

  /// 获取卡片/表面颜色（适配深色模式）
  static Color getSurfaceColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.cardColor;
  }

  /// 获取主要文本颜色（适配深色模式）
  static Color getTextColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge?.color ?? 
           (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
  }

  /// 获取次要文本颜色（适配深色模式）
  static Color getSecondaryTextColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium?.color ?? 
           (theme.brightness == Brightness.dark ? Colors.grey[300]! : Colors.grey[600]!);
  }

  /// 获取图标颜色（适配深色模式）
  static Color getIconColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.iconTheme.color ?? 
           (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
  }

  /// 获取分割线颜色（适配深色模式）
  static Color getDividerColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.dividerColor;
  }

  /// 获取边框颜色（适配深色模式）
  static Color getBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark 
        ? Colors.grey[700]! 
        : Colors.grey[300]!;
  }

  /// 获取主色（适配深色模式）
  static Color getPrimaryColor(BuildContext context) {
    return const Color(AppConstants.primaryColor);
  }

  /// 获取强调色（适配深色模式）
  static Color getAccentColor(BuildContext context) {
    return const Color(AppConstants.accentColor);
  }

  /// 获取成功色（适配深色模式）
  static Color getSuccessColor(BuildContext context) {
    return Colors.green;
  }

  /// 获取警告色（适配深色模式）
  static Color getWarningColor(BuildContext context) {
    return Colors.orange;
  }

  /// 获取错误色（适配深色模式）
  static Color getErrorColor(BuildContext context) {
    return const Color(AppConstants.errorColor);
  }

  /// 获取阴影颜色（适配深色模式）
  static Color getShadowColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.05);
  }

  /// 获取主要文本颜色（适配深色模式）
  static Color getPrimaryTextColor(BuildContext context) {
    return getTextColor(context);
  }

  /// 判断是否为深色模式
  static bool isDarkMode(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark;
  }

  /// 获取白色或适配颜色（深色模式下返回深色）
  static Color getWhiteOrAdaptive(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark 
        ? theme.scaffoldBackgroundColor 
        : Colors.white;
  }

  /// 获取黑色或适配颜色（深色模式下返回浅色）
  static Color getBlackOrAdaptive(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark 
        ? Colors.white 
        : Colors.black87;
  }

  /// 获取适配的复古装饰样式
  static BoxDecoration getVintageDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? theme.cardColor : const Color(AppConstants.secondaryColor),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: getPrimaryColor(context),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// 获取适配的相纸背景装饰
  static BoxDecoration getPhotoPaperDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? theme.cardColor : const Color(AppConstants.secondaryColor),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(AppConstants.primaryColor),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

