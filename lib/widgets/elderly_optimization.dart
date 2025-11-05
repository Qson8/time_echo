import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';

/// 老年用户优化组件
class ElderlyOptimization {
  /// 获取老年友好版字体大小
  static double getElderlyFontSize(String fontSize) {
    final baseSize = AppConstants.fontSizes[fontSize] ?? 16.0;
    return baseSize * 1.2; // 放大20%
  }

  /// 获取老年友好版按钮尺寸
  static Size getElderlyButtonSize(Size originalSize) {
    return Size(
      originalSize.width * 1.2,
      originalSize.height * 1.2,
    );
  }

  /// 获取老年友好版间距
  static double getElderlySpacing(double originalSpacing) {
    return originalSpacing * 1.1; // 增加10%
  }

  /// 构建老年友好版文本样式
  static TextStyle buildElderlyTextStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 16.0) * 1.2,
      height: 1.6, // 增加行高
    );
  }

  /// 构建老年友好版按钮样式
  static ButtonStyle buildElderlyButtonStyle(ButtonStyle baseStyle) {
    return baseStyle.copyWith(
      minimumSize: MaterialStateProperty.all(const Size(120, 48)),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }

  /// 构建老年友好版卡片样式
  static BoxDecoration buildElderlyCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(AppConstants.primaryColor),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// 构建老年友好版输入框样式
  static InputDecoration buildElderlyInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(AppConstants.primaryColor),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(AppConstants.primaryColor),
          width: 3,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(
        fontSize: 18,
        color: Colors.grey,
      ),
    );
  }

  /// 构建老年友好版列表项
  static Widget buildElderlyListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(AppConstants.primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            icon,
            color: const Color(AppConstants.primaryColor),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        trailing: trailing ?? const Icon(
          Icons.chevron_right,
          color: Colors.grey,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }

  /// 构建老年友好版对话框
  static Widget buildElderlyDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
      actions: actions.map((action) {
        if (action is TextButton) {
          return TextButton(
            onPressed: action.onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(100, 44),
            ),
            child: Text(
              action.child.toString().replaceAll('Text("', '').replaceAll('")', ''),
              style: const TextStyle(fontSize: 16),
            ),
          );
        }
        return action;
      }).toList(),
    );
  }

  /// 构建老年友好版开关
  static Widget buildElderlySwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(AppConstants.primaryColor),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  /// 构建老年友好版进度指示器
  static Widget buildElderlyProgressIndicator({
    required double value,
    String? label,
  }) {
    return Column(
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(
            Color(AppConstants.primaryColor),
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          '${(value * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  /// 构建老年友好版提示信息
  static Widget buildElderlyHint({
    required String message,
    IconData? icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (color ?? const Color(AppConstants.primaryColor)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color ?? const Color(AppConstants.primaryColor),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color ?? const Color(AppConstants.primaryColor),
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: color ?? const Color(AppConstants.primaryColor),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
