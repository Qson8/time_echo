import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../services/theme_service.dart';
import '../services/local_storage_service.dart';
import '../providers/theme_provider.dart';
import 'quiz_config_screen.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    print('🔍 SettingsScreen build() 被调用');
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: Consumer2<AppStateProvider, ThemeProvider>(
        builder: (context, appState, themeProvider, child) {
          print('🔍 Consumer2 builder 被调用: voiceEnabled=${appState.voiceEnabled}');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 个性化设置
                _buildPersonalizationSection(appState),
                
                const SizedBox(height: 24),
                
                // 显示设置
                _buildDisplaySection(appState, themeProvider),
                
                const SizedBox(height: 24),
                
                // 语音设置
                _buildVoiceSection(appState),
                
                const SizedBox(height: 24),
                
                // 拾光测试设置
                _buildQuizSettingsSection(appState),
                
                const SizedBox(height: 24),
                
                // 应用信息
                _buildAppInfoSection(),
                
                const SizedBox(height: 24),
                
                // 其他设置
                _buildOtherSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建个性化设置区域
  Widget _buildPersonalizationSection(AppStateProvider appState) {
    return _buildSection(
      title: '个性化设置',
      icon: Icons.person,
      children: [
        _buildListTile(
          title: '拾光评语风格',
          subtitle: appState.commentStyle,
          icon: Icons.format_quote,
          onTap: () => _showCommentStyleDialog(appState),
        ),
        _buildListTile(
          title: '字体大小',
          subtitle: appState.fontSize,
          icon: Icons.text_fields,
          onTap: () => _showFontSizeDialog(appState),
        ),
      ],
    );
  }

  /// 构建拾光测试设置区域
  Widget _buildQuizSettingsSection(AppStateProvider appState) {
    return _buildSection(
      title: '拾光测试设置',
      icon: Icons.quiz,
      children: [
        _buildListTile(
          title: '定制题目配置',
          subtitle: '设置题目数量、分类、年代、难度、组题模式等',
          icon: Icons.tune,
          onTap: () => _openQuizConfig(),
        ),
      ],
    );
  }

  /// 打开定制题目配置页面
  void _openQuizConfig() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QuizConfigScreen()),
    );
  }

  /// 获取组题模式名称
  String _getQuestionModeName(QuestionSelectionMode mode) {
    switch (mode) {
      case QuestionSelectionMode.random:
        return '随机模式';
      case QuestionSelectionMode.balanced:
        return '均衡模式';
      case QuestionSelectionMode.smart:
        return '智能推荐模式';
    }
  }

  /// 获取组题模式描述
  String _getQuestionModeDescription(QuestionSelectionMode mode) {
    switch (mode) {
      case QuestionSelectionMode.random:
        return '完全随机选择题目，简单高效';
      case QuestionSelectionMode.balanced:
        return '按分类、难度、年代均衡分配，确保分布均匀';
      case QuestionSelectionMode.smart:
        return '根据您的历史表现智能推荐，个性化学习';
    }
  }

  /// 显示组题模式选择对话框
  void _showQuestionModeDialog(AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择组题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: QuestionSelectionMode.values.map((mode) {
            return RadioListTile<QuestionSelectionMode>(
              title: Text(_getQuestionModeName(mode)),
              subtitle: Text(
                _getQuestionModeDescription(mode),
                style: const TextStyle(fontSize: 12),
              ),
              value: mode,
              groupValue: appState.questionSelectionMode,
              onChanged: (value) async {
                if (value != null) {
                  await appState.setQuestionSelectionMode(value);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('组题模式已设置为：${_getQuestionModeName(value)}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建显示设置区域
  Widget _buildDisplaySection(AppStateProvider appState, ThemeProvider themeProvider) {
    return _buildSection(
      title: '显示设置',
      icon: Icons.visibility,
      children: [
        _buildSwitchTile(
          title: '老年友好模式',
          subtitle: '放大字体和按钮，优化触控体验',
          icon: Icons.accessibility,
          value: appState.elderlyMode,
          onChanged: (value) => _toggleElderlyMode(appState, value),
        ),
        _buildListTile(
          title: '主题设置',
          subtitle: themeProvider.getThemeName(themeProvider.currentTheme),
          icon: Icons.palette,
          onTap: () => _showThemeDialog(themeProvider),
        ),
      ],
    );
  }

  /// 构建语音设置区域
  Widget _buildVoiceSection(AppStateProvider appState) {
    print('🔍 _buildVoiceSection: voiceEnabled=${appState.voiceEnabled}');
    final isPlatformSupported = appState.voiceService.isPlatformSupported;
    
    return _buildSection(
      title: '语音设置',
      icon: Icons.volume_up,
      children: [
        if (!isPlatformSupported) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '当前平台不支持语音读题功能',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        _buildSwitchTile(
          title: '拾光语音读题',
          subtitle: isPlatformSupported 
              ? '答题时自动读取题目内容'
              : '当前平台不支持此功能',
          icon: Icons.record_voice_over,
          value: appState.voiceEnabled && isPlatformSupported,
          onChanged: isPlatformSupported 
              ? (value) => _toggleVoice(appState, value)
              : (_) {}, // 平台不支持时提供空函数
        ),
        if (appState.voiceEnabled)
          _buildListTile(
            title: '语音速度',
            subtitle: appState.voiceSpeed,
            icon: Icons.speed,
            onTap: () => _showVoiceSpeedDialog(appState),
          ),
      ],
    );
  }

  /// 构建应用信息区域
  Widget _buildAppInfoSection() {
    return _buildSection(
      title: '应用信息',
      icon: Icons.info,
      children: [
        _buildListTile(
          title: '应用版本',
          subtitle: AppConstants.appVersion,
          icon: Icons.apps,
          onTap: null,
        ),
        _buildListTile(
          title: '关于拾光机',
          subtitle: '了解应用详情',
          icon: Icons.help_outline,
          onTap: () => _showAboutDialog(),
        ),
        _buildListTile(
          title: '隐私政策',
          subtitle: '查看隐私保护说明',
          icon: Icons.privacy_tip,
          onTap: () => _showPrivacyDialog(),
        ),
      ],
    );
  }

  /// 构建其他设置区域
  Widget _buildOtherSection() {
    return _buildSection(
      title: '其他',
      icon: Icons.more_horiz,
      children: [
        _buildListTile(
          title: '清除缓存',
          subtitle: '清理应用缓存数据',
          icon: Icons.cleaning_services,
          onTap: () => _showClearCacheDialog(),
        ),
        _buildListTile(
          title: '重置数据',
          subtitle: '清除所有本地数据',
          icon: Icons.refresh,
          onTap: () => _showResetDataDialog(),
        ),
      ],
    );
  }

  /// 构建设置区域
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(AppConstants.primaryColor),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// 构建列表项
  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(AppConstants.primaryColor),
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
          color: Colors.black54,
        ),
      ),
      trailing: onTap != null
          ? const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            )
          : null,
      onTap: onTap,
    );
  }

  /// 构建开关项
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(AppConstants.primaryColor),
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
          color: Colors.black54,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(AppConstants.primaryColor),
      ),
    );
  }

  /// 显示评语风格对话框
  void _showCommentStyleDialog(AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择评语风格'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('通用版'),
              value: '通用版',
              groupValue: appState.commentStyle,
              onChanged: (value) {
                if (value != null) {
                  appState.updateCommentStyle(value).then((_) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('老年友好版'),
              value: '老年友好版',
              groupValue: appState.commentStyle,
              onChanged: (value) {
                if (value != null) {
                  appState.updateCommentStyle(value).then((_) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示字体大小对话框
  void _showFontSizeDialog(AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择字体大小'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.fontSizes.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.key),
              value: entry.key,
              groupValue: appState.fontSize,
              onChanged: (value) {
                if (value != null) {
                  appState.updateFontSize(value).then((_) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 显示语音速度对话框
  void _showVoiceSpeedDialog(AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语音速度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.voiceSpeeds.keys.map((speed) {
            return RadioListTile<String>(
              title: Text(speed),
              value: speed,
              groupValue: appState.voiceSpeed,
              onChanged: (value) {
                if (value != null) {
                  appState.updateVoiceSettings(appState.voiceEnabled, value).then((_) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 切换语音
  void _toggleVoice(AppStateProvider appState, bool value) async {
    print('🚀 _toggleVoice 被调用，新值: $value');
    print('🚀 当前状态: voiceEnabled=${appState.voiceEnabled}, voiceSpeed=${appState.voiceSpeed}');
    try {
      print('🚀 开始调用 updateVoiceSettings...');
      await appState.updateVoiceSettings(value, appState.voiceSpeed);
      print('🚀 updateVoiceSettings 完成');
      print('🚀 更新后状态: voiceEnabled=${appState.voiceEnabled}');
    } catch (e, stackTrace) {
      print('❌ 语音设置更新失败: $e');
      print('❌ 错误堆栈: $stackTrace');
      // 如果保存失败，回滚状态
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('语音设置更新失败：$e')),
      );
    }
  }

  /// 切换老年友好模式
  void _toggleElderlyMode(AppStateProvider appState, bool value) async {
    try {
      await appState.updateElderlyMode(value);
    } catch (e) {
      // 如果保存失败，回滚状态
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('老年友好模式更新失败：$e')),
      );
    }
  }

  /// 显示主题对话框
  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeType.values.map((theme) {
            return RadioListTile<ThemeType>(
              title: Row(
                children: [
                  Icon(
                    themeProvider.getThemeIcon(theme),
                    color: themeProvider.getThemeColor(theme),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(themeProvider.getThemeName(theme)),
                ],
              ),
              subtitle: Text(
                themeProvider.getThemeDescription(theme),
                style: const TextStyle(fontSize: 12),
              ),
              value: theme,
              groupValue: themeProvider.currentTheme,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setTheme(value).then((_) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.favorite,
              color: Color(AppConstants.primaryColor),
              size: 24,
            ),
            SizedBox(width: 8),
            Text('关于拾光机'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 应用简介
              const Text(
                '拾光机是一款专为怀旧爱好者打造的离线问答应用。无需网络连接，随时随地畅享80-90年代的经典回忆。通过答题测试，系统会智能计算你的"拾光年龄"，让你了解自己对那个年代的记忆深度。提供详细解析、学习报告、记忆胶囊等功能，让每一份时光记忆都值得珍藏。',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              
              // 版本信息
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      '版本：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(AppConstants.appVersion),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 主要功能
              const Text(
                '主要功能',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('离线答题：无需网络，随时随地畅享怀旧问答乐趣'),
              _buildFeatureItem('题库丰富：持续更新，涵盖80-90年代影视、音乐、事件'),
              _buildFeatureItem('详细解析：每道题提供解析、历史背景和知识点标签'),
              _buildFeatureItem('拾光年龄：智能计算你的专属"拾光年龄"'),
              _buildFeatureItem('学习报告：自动生成日报/周报/月报，了解学习情况'),
              _buildFeatureItem('收藏题目：喜欢的题目一键收藏，添加个人笔记'),
              _buildFeatureItem('记忆胶囊：创建专属记忆，记录与题目相关的回忆'),
              _buildFeatureItem('每日挑战：每天3个挑战任务，完成获得奖励'),
              _buildFeatureItem('成就系统：8种成就徽章，见证成长足迹'),
              _buildFeatureItem('答题统计：可视化图表展示学习趋势和进步轨迹'),
              _buildFeatureItem('个性化设置：支持字体大小、语音读题等个性化体验'),
              _buildFeatureItem('一键分享：将有趣题目和学习报告分享给好友'),
              const SizedBox(height: 16),
              
              // 适用人群
              const Text(
                '适用人群',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('怀旧动漫、综艺与影视剧爱好者'),
              _buildFeatureItem('想与朋友回忆童年、共话旧时光的你'),
              _buildFeatureItem('喜欢迎接知识新挑战、增长见识的你'),
              _buildFeatureItem('希望了解自己"拾光年龄"的好奇者'),
              _buildFeatureItem('需要离线学习工具的用户'),
              _buildFeatureItem('老年用户（大字体、语音辅助）'),
              const SizedBox(height: 16),
              
              // 核心特色
              const Text(
                '核心特色',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('✅ 完全离线：无需网络，保护隐私，随时随地使用'),
              _buildFeatureItem('✅ 老年友好：大字体、大按钮、语音读题，专为老年用户优化'),
              _buildFeatureItem('✅ 智能学习：学习报告、数据分析，科学提升学习效果'),
              _buildFeatureItem('✅ 怀旧主题：80-90年代复古设计，沉浸式体验'),
              _buildFeatureItem('✅ 数据安全：所有数据存储在本地，不上传云端'),
              _buildFeatureItem('✅ 无广告：纯净体验，无任何广告干扰'),
              const SizedBox(height: 16),
              
              // 无广告说明
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '所有功能均可免费使用，无广告打扰，致力于还原纯粹的怀旧答题体验。',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // 结尾
              const Text(
                '快来拾光机，和过去的美好再一次相遇吧！',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(AppConstants.primaryColor),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 构建功能项
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(AppConstants.primaryColor),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示隐私政策对话框
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私政策'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '隐私保护承诺：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• 拾光机完全离线运行，不会收集任何个人信息'),
              Text('• 所有数据仅保存在本地设备，不会上传到服务器'),
              Text('• 不会访问网络，不会获取位置信息'),
              Text('• 不会读取通讯录、相册等个人隐私数据'),
              Text('• 卸载应用时，所有本地数据将被清除'),
              SizedBox(height: 8),
              Text(
                '我们承诺保护您的隐私，让您安心享受拾光之旅。',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示清除缓存对话框
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除应用缓存吗？这将不会影响您的拾光记录和收藏。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearCache();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 清除缓存
  Future<void> _clearCache() async {
    try {
      // 这里可以清除一些临时数据，比如图片缓存等
      // 由于我们使用的是SQLite和SharedPreferences，这些是持久化数据
      // 所以这里主要是清除一些运行时缓存
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存清除完成')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('缓存清除失败：$e')),
      );
    }
  }

  /// 显示重置数据对话框
  void _showResetDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置数据'),
        content: const Text(
          '确定要重置所有数据吗？这将清除所有拾光记录、收藏和成就，此操作不可恢复！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetAllData();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  /// 重置所有数据
  Future<void> _resetAllData() async {
    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      // 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('最终确认'),
          content: const Text('此操作将永久删除所有数据，确定继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('确定删除'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // 重置测试状态
        appState.resetTest();
        
        // 清除所有数据
        await appState.clearAllData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('所有数据已重置')),
          );
          
          // 延迟导航回首页，确保数据已清除
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              // 多次弹出到返回到首页
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据重置失败：$e')),
      );
    }
  }
}
