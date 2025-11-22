import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/echo_achievement.dart';
import '../services/app_state_provider.dart';
import 'quiz_screen.dart';

/// 成就页面
class AchievementScreen extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  
  const AchievementScreen({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, onMenuPressed),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          // 检查是否有已解锁的成就
          if (appState.unlockedAchievementCount == 0) {
            return _buildEmptyView(context);
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 成就统计
                _buildAchievementStats(context, appState),
                
                const SizedBox(height: 20),
                
                // 成就列表
                _buildAchievementList(context, appState),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建AppBar（与其他页面统一）
  PreferredSizeWidget _buildAppBar(BuildContext context, VoidCallback? onMenuPressed) {
    // 检查是否可以返回（从底部导航进入时不显示返回按钮）
    final canPop = Navigator.canPop(context);
    
    return AppBar(
      title: const Text('我的拾光成就'),
      centerTitle: true,
      leading: onMenuPressed != null
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: onMenuPressed,
                tooltip: '打开菜单',
              ),
            )
          : canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '返回',
                )
              : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showAchievementHelp(context),
          tooltip: '帮助',
        ),
      ],
    );
  }

  /// 构建自定义AppBar（已废弃，保留用于参考）
  Widget _buildCustomAppBar_Deprecated(BuildContext context, VoidCallback? onMenuPressed) {
    // 获取状态栏高度
    final statusBarHeight = MediaQuery.of(context).padding.top;
    // 检查是否可以返回（从底部导航进入时不显示返回按钮）
    final canPop = Navigator.canPop(context);
    
    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(AppConstants.primaryColor),
            const Color(AppConstants.primaryColor).withOpacity(0.9),
            const Color(AppConstants.primaryColor).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // 菜单按钮或返回按钮
          if (onMenuPressed != null) ...[
            // 如果有菜单回调，显示菜单按钮
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: onMenuPressed,
                tooltip: '打开菜单',
              ),
            ),
            const SizedBox(width: 8),
          ] else if (canPop) ...[
            // 如果可以返回，显示返回按钮
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: '返回',
              ),
            ),
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: 48), // 占位，保持标题居中
          
          // 标题 - 使用与其他页面一致的字体大小
          Expanded(
            child: Text(
              '我的拾光成就',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20, // 与其他页面AppBar标题一致
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0, // 减少字间距
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          
          // 帮助按钮 - 带背景
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: () => _showAchievementHelp(context),
              tooltip: '帮助',
            ),
          ),
        ],
      ),
    );
  }

  /// 构建成就统计
  Widget _buildAchievementStats(BuildContext context, AppStateProvider appState) {
    final unlockedCount = appState.unlockedAchievementCount;
    final totalCount = appState.totalAchievementCount;
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(AppConstants.primaryColor).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 成就徽章图标 - 简化设计
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColor),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // 成就标题 - 简化设计
          const Text(
            '拾光成就',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.primaryColor),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          
          // 成就进度 - 简化设计
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 20,
                  color: Color(AppConstants.primaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  '已解锁 $unlockedCount/$totalCount 个成就',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // 进度条容器 - 简化设计
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(AppConstants.primaryColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 进度百分比 - 简化设计
          Text(
            '完成度 ${(progress * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建成就列表
  Widget _buildAchievementList(BuildContext context, AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(AppConstants.primaryColor),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '成就列表',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: appState.achievements.length,
          itemBuilder: (context, index) {
            final achievement = appState.achievements[index];
            return _buildAchievementCard(context, achievement, index);
          },
        ),
      ],
    );
  }

  /// 构建成就卡片
  Widget _buildAchievementCard(BuildContext context, EchoAchievement achievement, int index) {
    final isUnlocked = achievement.isUnlocked;
    
    return GestureDetector(
      onTap: () => _showAchievementDetail(context, achievement),
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? const Color(AppConstants.primaryColor).withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? const Color(AppConstants.primaryColor).withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
                  // 成就图标 - 简化设计
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? const Color(AppConstants.primaryColor)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _getAchievementIcon(achievement.id),
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // 成就名称
                  Flexible(
                    child: Text(
                      achievement.achievementName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? const Color(AppConstants.primaryColor)
                            : Colors.grey[600],
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 解锁状态徽章 - 简化设计
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? const Color(AppConstants.accentColor).withOpacity(0.15)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnlocked
                            ? const Color(AppConstants.accentColor).withOpacity(0.4)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUnlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                          size: 12,
                          color: isUnlocked
                              ? const Color(AppConstants.accentColor)
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isUnlocked ? '已解锁' : '未解锁',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked
                                ? const Color(AppConstants.accentColor)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取成就图标
  IconData _getAchievementIcon(int achievementId) {
    switch (achievementId) {
      case 1: // 拾光初遇
        return Icons.star;
      case 2: // 影视拾光者
        return Icons.movie;
      case 3: // 音乐回响者
        return Icons.music_note;
      case 4: // 时代见证者
        return Icons.history_edu;
      case 5: // 拾光速答手
        return Icons.speed;
      case 6: // 拾光挑战者
        return Icons.sports_esports;
      case 7: // 拾光收藏家
        return Icons.favorite;
      case 8: // 拾光全勤人
        return Icons.calendar_today;
      default:
        return Icons.emoji_events;
    }
  }

  /// 显示成就详情
  void _showAchievementDetail(BuildContext context, EchoAchievement achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(AppConstants.secondaryColor),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 成就图标
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: achievement.isUnlocked
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(AppConstants.primaryColor),
                              const Color(AppConstants.accentColor),
                            ],
                          )
                        : null,
                    color: achievement.isUnlocked ? null : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: achievement.isUnlocked
                        ? [
                            BoxShadow(
                              color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _getAchievementIcon(achievement.id),
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                
                // 成就名称
                Text(
                  achievement.achievementName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                
                // 信息卡片
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(AppConstants.primaryColor).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 达成条件
                      Row(
                        children: [
                          Icon(
                            Icons.flag,
                            size: 20,
                            color: const Color(AppConstants.primaryColor),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '达成条件',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(AppConstants.primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          achievement.condition,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 奖励
                      Row(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 20,
                            color: const Color(AppConstants.accentColor),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '奖励',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(AppConstants.accentColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          achievement.reward,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                      
                      if (achievement.isUnlocked) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: const Color(AppConstants.primaryColor).withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '解锁时间',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(AppConstants.primaryColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            _formatDate(achievement.unlockedAt),
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(AppConstants.primaryColor).withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                // 确定按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppConstants.primaryColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示成就帮助
  void _showAchievementHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(AppConstants.secondaryColor),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Color(AppConstants.primaryColor),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '拾光成就说明',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConstants.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                
                // 成就列表
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(AppConstants.primaryColor).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '成就系统说明：',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(AppConstants.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHelpItem('拾光初遇', '完成首次拾光'),
                      _buildHelpItem('影视拾光者', '影视分类题库正确率≥90%'),
                      _buildHelpItem('音乐回响者', '音乐分类题库正确率≥90%'),
                      _buildHelpItem('时代见证者', '事件分类题库正确率≥90%'),
                      _buildHelpItem('拾光速答手', '单次拾光单题平均耗时≤15秒'),
                      _buildHelpItem('拾光挑战者', '单次拾光困难题正确率100%'),
                      _buildHelpItem('拾光收藏家', '收藏题目数量≥20道'),
                      _buildHelpItem('拾光全勤人', '连续7天每天完成1次拾光'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // 提示信息
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.accentColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(AppConstants.accentColor).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(AppConstants.accentColor),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '注意：成就数据仅保存在本地，卸载App将清空，珍惜每一份时光记忆～',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(AppConstants.accentColor).withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                // 确定按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppConstants.primaryColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      '我知道了',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建帮助项
  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColor),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 构建空视图
  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 空状态图标 - 简化设计
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  size: 50,
                  color: const Color(AppConstants.primaryColor).withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 32),
              
              // 空状态标题
              const Text(
                '暂无成就',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              
              // 空状态描述
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(AppConstants.primaryColor).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  '开始你的拾光之旅吧！\n完成拾光、收藏题目，解锁更多成就～',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // 开始按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const QuizScreen()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text(
                    '开始拾光',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 帮助按钮
              TextButton.icon(
                onPressed: () => _showAchievementHelp(context),
                icon: const Icon(Icons.help_outline, size: 20),
                label: const Text(
                  '了解成就系统',
                  style: TextStyle(fontSize: 16),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(AppConstants.primaryColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

