import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/offline_data_manager.dart';

/// 离线友好的用户界面组件
class OfflineFriendlyComponents {
  /// 创建离线状态指示器
  static Widget buildOfflineIndicator({
    String message = '离线模式',
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: backgroundColor ?? Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: 16,
            color: textColor ?? Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 创建本地数据统计卡片
  static Widget buildLocalDataStats({
    required Map<String, dynamic> stats,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.storage,
                    color: const Color(AppConstants.primaryColor),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '本地数据',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  OfflineFriendlyComponents.buildOfflineIndicator(),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 统计网格
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatItem(
                    '题目总数',
                    '${stats['total_questions'] ?? 0}',
                    Icons.quiz,
                    Colors.blue,
                  ),
                  _buildStatItem(
                    '拾光次数',
                    '${stats['total_tests'] ?? 0}',
                    Icons.analytics,
                    Colors.green,
                  ),
                  _buildStatItem(
                    '成就解锁',
                    '${stats['unlocked_achievements'] ?? 0}/${stats['total_achievements'] ?? 0}',
                    Icons.emoji_events,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    '收藏题目',
                    '${stats['total_collections'] ?? 0}',
                    Icons.favorite,
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建统计项
  static Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 创建离线功能卡片
  static Widget buildOfflineFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    bool isEnabled = true,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (iconColor ?? const Color(AppConstants.primaryColor))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(AppConstants.primaryColor),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isEnabled ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.chevron_right,
                color: isEnabled ? Colors.grey : Colors.grey[300],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 创建离线设置面板
  static Widget buildOfflineSettingsPanel({
    required Map<String, dynamic> settings,
    required Function(String, dynamic) onSettingChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '离线设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 语音设置
            _buildSettingSwitch(
              '语音朗读',
              '启用题目和选项的语音朗读',
              Icons.volume_up,
              settings['voice_enabled'] ?? false,
              (value) => onSettingChanged('voice_enabled', value),
            ),
            
            const SizedBox(height: 16),
            
            // 老年模式
            _buildSettingSwitch(
              '老年友好模式',
              '启用大字体和大按钮',
              Icons.accessibility,
              settings['elderly_mode'] ?? false,
              (value) => onSettingChanged('elderly_mode', value),
            ),
            
            const SizedBox(height: 16),
            
            // 字体大小
            _buildSettingDropdown(
              '字体大小',
              '选择适合的字体大小',
              Icons.text_fields,
              settings['font_size'] ?? '中',
              ['小', '中', '大', '特大'],
              (value) => onSettingChanged('font_size', value),
            ),
            
            const SizedBox(height: 16),
            
            // 评语风格
            _buildSettingDropdown(
              '评语风格',
              '选择评语显示风格',
              Icons.message,
              settings['comment_style'] ?? '通用版',
              ['通用版', '老年友好版'],
              (value) => onSettingChanged('comment_style', value),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建设置开关
  static Widget _buildSettingSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(AppConstants.primaryColor),
        ),
      ],
    );
  }

  /// 构建设置下拉菜单
  static Widget _buildSettingDropdown(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        DropdownButton<String>(
          value: value,
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 创建数据管理面板
  static Widget buildDataManagementPanel({
    required VoidCallback onExport,
    required VoidCallback onImport,
    required VoidCallback onClear,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '数据管理',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 导出数据
            _buildActionButton(
              '导出数据',
              '将本地数据导出为文件',
              Icons.download,
              Colors.blue,
              onExport,
            ),
            
            const SizedBox(height: 12),
            
            // 导入数据
            _buildActionButton(
              '导入数据',
              '从文件导入数据到本地',
              Icons.upload,
              Colors.green,
              onImport,
            ),
            
            const SizedBox(height: 12),
            
            // 清理数据
            _buildActionButton(
              '清理数据',
              '清除所有本地数据（谨慎操作）',
              Icons.delete_forever,
              Colors.red,
              onClear,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮
  static Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 创建离线提示对话框
  static Widget buildOfflineTipDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.wifi_off,
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
        ],
      ),
      content: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
      actions: actions,
    );
  }

  /// 创建本地成就展示
  static Widget buildLocalAchievementDisplay({
    required List<Map<String, dynamic>> achievements,
    required VoidCallback onViewAll,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '本地成就',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('查看全部'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 成就网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: achievements.take(6).length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final isUnlocked = achievement['is_unlocked'] ?? false;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? const Color(AppConstants.primaryColor).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked 
                          ? const Color(AppConstants.primaryColor).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getAchievementIcon(achievement['achievement_icon']),
                        color: isUnlocked 
                            ? const Color(AppConstants.primaryColor)
                            : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement['achievement_name'] ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isUnlocked ? Colors.black : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 获取成就图标
  static IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'movie':
        return Icons.movie;
      case 'music_note':
        return Icons.music_note;
      case 'history':
        return Icons.history;
      case 'speed':
        return Icons.speed;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'favorite':
        return Icons.favorite;
      case 'calendar_today':
        return Icons.calendar_today;
      default:
        return Icons.emoji_events;
    }
  }

  /// 创建本地学习统计
  static Widget buildLocalLearningStats({
    required Map<String, dynamic> stats,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '学习统计',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 统计信息
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '总拾光',
                    '${stats['total_tests'] ?? 0}',
                    Icons.quiz,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    '最佳准确率',
                    '${((stats['best_accuracy'] ?? 0.0) * 100).toInt()}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '当前连续',
                    '${stats['current_streak'] ?? 0}天',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    '最长连续',
                    '${stats['longest_streak'] ?? 0}天',
                    Icons.emoji_events,
                    Colors.purple,
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
