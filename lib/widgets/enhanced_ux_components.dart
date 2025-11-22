import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/voice_service.dart';
import '../widgets/animated_widgets.dart';

/// 增强的用户体验组件
class EnhancedUXComponents {
  /// 创建智能提示对话框
  static Widget buildSmartTipDialog({
    required String title,
    required String content,
    required List<Widget> actions,
    String? voiceContent,
    bool enableVoice = true,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: const Color(AppConstants.primaryColor),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (enableVoice && voiceContent != null)
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () => VoiceService().speak(voiceContent),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 内容
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }

  /// 创建进度指示器
  static Widget buildProgressIndicator({
    required double progress,
    required String label,
    Color? progressColor,
    Color? backgroundColor,
    double height = 8.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        AnimatedProgressBar(
          progress: progress,
          height: height,
          progressColor: progressColor ?? const Color(AppConstants.primaryColor),
          backgroundColor: backgroundColor ?? Colors.grey.withOpacity(0.3),
        ),
      ],
    );
  }

  /// 创建智能搜索框
  static Widget buildSmartSearchBox({
    required String hintText,
    required ValueChanged<String> onChanged,
    VoidCallback? onClear,
    String? initialValue,
    bool enableVoice = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: TextEditingController(text: initialValue),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (enableVoice)
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () => _startVoiceSearch(),
                ),
              if (onClear != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// 创建智能卡片
  static Widget buildSmartCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    double? elevation,
    bool enableAnimation = true,
  }) {
    Widget card = Card(
      elevation: elevation ?? 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: backgroundColor ?? Colors.white,
      margin: margin ?? const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (enableAnimation) {
      return AnimationUtils.scaleIn(child: card);
    }

    return card;
  }

  /// 创建智能按钮组
  static Widget buildSmartButtonGroup({
    required List<SmartButtonData> buttons,
    MainAxisAlignment alignment = MainAxisAlignment.spaceEvenly,
  }) {
    return Row(
      mainAxisAlignment: alignment,
      children: buttons.map((buttonData) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedButton(
              onPressed: buttonData.onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: buttonData.backgroundColor ?? const Color(AppConstants.primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (buttonData.icon != null) ...[
                      Icon(
                        buttonData.icon,
                        color: buttonData.textColor ?? Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Flexible(
                      child: Text(
                        buttonData.text,
                        style: TextStyle(
                          color: buttonData.textColor ?? Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 创建智能列表项
  static Widget buildSmartListItem({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
    bool enableAnimation = true,
  }) {
    Widget listItem = ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(AppConstants.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
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
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      trailing: trailing ?? const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );

    if (enableAnimation) {
      return AnimationUtils.slideIn(child: listItem);
    }

    return listItem;
  }

  /// 创建智能通知横幅
  static Widget buildSmartNotificationBanner({
    required String message,
    required NotificationType type,
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    String? actionText,
  }) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case NotificationType.success:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case NotificationType.warning:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case NotificationType.error:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.error;
        break;
      case NotificationType.info:
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        icon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: textColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onAction != null && actionText != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: textColor,
                size: 20,
              ),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }

  /// 创建智能加载状态
  static Widget buildSmartLoadingState({
    required String message,
    double size = 40.0,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulseAnimation(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(AppConstants.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 创建智能空状态
  static Widget buildSmartEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 开始语音搜索
  static void _startVoiceSearch() {
    // 实现语音搜索逻辑
    HapticFeedback.lightImpact();
  }
}

/// 智能按钮数据模型
class SmartButtonData {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  SmartButtonData({
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });
}

/// 通知类型枚举
enum NotificationType {
  success,
  warning,
  error,
  info,
}
