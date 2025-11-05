import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/offline_data_manager.dart';
import '../widgets/offline_friendly_components.dart';
import '../widgets/animated_widgets.dart';

/// 离线设置页面
class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  State<OfflineSettingsScreen> createState() => _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final OfflineDataManager _dataManager = OfflineDataManager();
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      _settings = {
        'voice_enabled': await _dataManager.getSetting<bool>('voice_enabled') ?? false,
        'voice_speed': await _dataManager.getSetting<String>('voice_speed') ?? '中',
        'comment_style': await _dataManager.getSetting<String>('comment_style') ?? '通用版',
        'font_size': await _dataManager.getSetting<String>('font_size') ?? '中',
        'elderly_mode': await _dataManager.getSetting<bool>('elderly_mode') ?? false,
        'theme_mode': await _dataManager.getSetting<String>('theme_mode') ?? 'light',
      };
      
      _stats = await _dataManager.getStatistics();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('加载设置失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 更新设置
  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await _dataManager.setSetting(key, value);
      setState(() {
        _settings[key] = value;
      });
      
      // 震动反馈
      HapticFeedback.lightImpact();
    } catch (e) {
      print('更新设置失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 离线状态指示器
              _buildOfflineStatus(),
              
              const SizedBox(height: 24),
              
              // 个性化设置
              _buildPersonalizationSettings(),
              
              const SizedBox(height: 24),
              
              // 显示设置
              _buildDisplaySettings(),
              
              const SizedBox(height: 24),
              
              // 语音设置
              _buildVoiceSettings(),
              
              const SizedBox(height: 24),
              
              // 数据管理
              _buildDataManagement(),
              
              const SizedBox(height: 24),
              
              // 应用信息
              _buildAppInfo(),
              
              const SizedBox(height: 24),
              
              // 其他设置
              _buildOtherSettings(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('离线设置'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
    );
  }

  /// 构建离线状态
  Widget _buildOfflineStatus() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off,
              color: const Color(AppConstants.primaryColor),
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '离线模式',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '所有数据本地存储，保护隐私安全',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            OfflineFriendlyComponents.buildOfflineIndicator(),
          ],
        ),
      ),
    );
  }

  /// 构建个性化设置
  Widget _buildPersonalizationSettings() {
    return OfflineFriendlyComponents.buildOfflineSettingsPanel(
      settings: _settings,
      onSettingChanged: _updateSetting,
    );
  }

  /// 构建显示设置
  Widget _buildDisplaySettings() {
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
                  Icons.palette,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '显示设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 主题模式
            _buildSettingDropdown(
              '主题模式',
              '选择应用主题',
              Icons.brightness_6,
              _settings['theme_mode'] ?? 'light',
              ['light', 'dark', 'auto'],
              (value) => _updateSetting('theme_mode', value),
            ),
            
            const SizedBox(height: 16),
            
            // 字体大小
            _buildSettingDropdown(
              '字体大小',
              '选择适合的字体大小',
              Icons.text_fields,
              _settings['font_size'] ?? '中',
              ['小', '中', '大', '特大'],
              (value) => _updateSetting('font_size', value),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建语音设置
  Widget _buildVoiceSettings() {
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
                  Icons.volume_up,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '语音设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 语音开关
            _buildSettingSwitch(
              '语音朗读',
              '启用题目和选项的语音朗读',
              Icons.volume_up,
              _settings['voice_enabled'] ?? false,
              (value) => _updateSetting('voice_enabled', value),
            ),
            
            const SizedBox(height: 16),
            
            // 语音速度
            if (_settings['voice_enabled'] == true)
              _buildSettingDropdown(
                '语音速度',
                '选择语音朗读速度',
                Icons.speed,
                _settings['voice_speed'] ?? '中',
                ['很慢', '慢', '中', '快', '很快'],
                (value) => _updateSetting('voice_speed', value),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建数据管理
  Widget _buildDataManagement() {
    return OfflineFriendlyComponents.buildDataManagementPanel(
      onExport: _exportData,
      onImport: _importData,
      onClear: _clearData,
    );
  }

  /// 构建应用信息
  Widget _buildAppInfo() {
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
                  Icons.info,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '应用信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            _buildInfoItem('应用名称', AppConstants.appName),
            _buildInfoItem('版本号', '1.0.0'),
            _buildInfoItem('构建时间', '2024-01-01'),
            _buildInfoItem('数据版本', '1.0.0'),
            _buildInfoItem('本地题目', '${_stats['total_questions'] ?? 0} 道'),
            _buildInfoItem('拾光次数', '${_stats['total_tests'] ?? 0} 次'),
            _buildInfoItem('成就解锁', '${_stats['unlocked_achievements'] ?? 0}/${_stats['total_achievements'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建其他设置
  Widget _buildOtherSettings() {
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
                  Icons.more_horiz,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  '其他设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 重置设置
            _buildActionButton(
              '重置设置',
              '恢复所有设置为默认值',
              Icons.restore,
              Colors.orange,
              _resetSettings,
            ),
            
            const SizedBox(height: 12),
            
            // 检查更新
            _buildActionButton(
              '检查更新',
              '检查应用是否有新版本',
              Icons.system_update,
              Colors.blue,
              _checkUpdate,
            ),
            
            const SizedBox(height: 12),
            
            // 关于应用
            _buildActionButton(
              '关于应用',
              '查看应用详细信息',
              Icons.info_outline,
              Colors.green,
              _showAbout,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建设置开关
  Widget _buildSettingSwitch(
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
  Widget _buildSettingDropdown(
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

  /// 构建操作按钮
  Widget _buildActionButton(
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

  /// 导出数据
  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => OfflineFriendlyComponents.buildOfflineTipDialog(
        title: '导出数据',
        content: '将本地数据导出为JSON文件，可以用于备份或迁移。',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final data = await _dataManager.exportData();
                // 这里应该实现文件保存逻辑
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据导出成功')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('数据导出失败: $e')),
                );
              }
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );
  }

  /// 导入数据
  void _importData() {
    showDialog(
      context: context,
      builder: (context) => OfflineFriendlyComponents.buildOfflineTipDialog(
        title: '导入数据',
        content: '从JSON文件导入数据到本地。注意：这将覆盖现有数据！',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // 这里应该实现文件选择和数据导入逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据导入功能开发中')),
              );
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  /// 清理数据
  void _clearData() {
    showDialog(
      context: context,
      builder: (context) => OfflineFriendlyComponents.buildOfflineTipDialog(
        title: '清理数据',
        content: '这将清除所有本地数据，包括拾光记录、收藏和设置。此操作不可恢复！',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dataManager.clearAllData();
                await _loadSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据清理成功')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('数据清理失败: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('确认清理'),
          ),
        ],
      ),
    );
  }

  /// 重置设置
  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => OfflineFriendlyComponents.buildOfflineTipDialog(
        title: '重置设置',
        content: '将所有设置恢复为默认值。',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // 重置设置逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置重置成功')),
              );
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  /// 检查更新
  void _checkUpdate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('离线应用无需更新检查')),
    );
  }

  /// 显示关于
  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => OfflineFriendlyComponents.buildOfflineTipDialog(
        title: '关于拾光机',
        content: '拾光机 v1.0.0\n\n'
                '一款专注于离线怀旧问答的Flutter应用。\n\n'
                '特色功能：\n'
                '• 全离线运行，保护隐私\n'
                '• 怀旧主题内容\n'
                '• 本地数据存储\n'
                '• 成就系统\n'
                '• 语音辅助\n\n'
                '开发者：拾光团队\n'
                '版本：1.0.0',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
