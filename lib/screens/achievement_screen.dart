import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/echo_achievement.dart';
import '../services/app_state_provider.dart';
import 'quiz_screen.dart';

/// 成就页面
class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的拾光成就'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showAchievementHelp(context),
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          // 检查是否有已解锁的成就
          if (appState.unlockedAchievementCount == 0) {
            return _buildEmptyView(context);
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 成就统计
                _buildAchievementStats(appState),
                
                const SizedBox(height: 24),
                
                // 成就列表
                _buildAchievementList(appState),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建成就统计
  Widget _buildAchievementStats(AppStateProvider appState) {
    final unlockedCount = appState.unlockedAchievementCount;
    final totalCount = appState.totalAchievementCount;
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.vintageDecoration,
      child: Column(
        children: [
          // 成就徽章图标
          Container(
            width: 80,
            height: 80,
            decoration: AppTheme.achievementBadgeDecoration,
            child: const Icon(
              Icons.emoji_events,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // 成就标题
          const Text(
            '拾光成就',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          
          // 成就进度
          Text(
            '已解锁 $unlockedCount/$totalCount 个成就',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // 进度条
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(AppConstants.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          
          // 进度百分比
          Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建成就列表
  Widget _buildAchievementList(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '成就列表',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.primaryColor),
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: appState.achievements.length,
          itemBuilder: (context, index) {
            final achievement = appState.achievements[index];
            return _buildAchievementCard(context, achievement);
          },
        ),
      ],
    );
  }

  /// 构建成就卡片
  Widget _buildAchievementCard(BuildContext context, EchoAchievement achievement) {
    return GestureDetector(
      onTap: () => _showAchievementDetail(context, achievement),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: achievement.isUnlocked 
              ? const Color(AppConstants.secondaryColor)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: achievement.isUnlocked 
                ? const Color(AppConstants.primaryColor)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 成就图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: achievement.isUnlocked 
                    ? const Color(AppConstants.primaryColor)
                    : Colors.grey,
              ),
              child: Icon(
                _getAchievementIcon(achievement.id),
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // 成就名称
            Flexible(
              child: Text(
                achievement.achievementName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: achievement.isUnlocked 
                      ? const Color(AppConstants.primaryColor)
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            
            // 解锁状态
            Text(
              achievement.isUnlocked ? '已解锁' : '未解锁',
              style: TextStyle(
                fontSize: 10,
                color: achievement.isUnlocked
                    ? const Color(AppConstants.accentColor)
                    : Colors.grey,
                fontWeight: achievement.isUnlocked ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
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
      builder: (context) => AlertDialog(
        title: Text(achievement.achievementName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 成就图标
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.isUnlocked 
                      ? const Color(AppConstants.primaryColor)
                      : Colors.grey,
                ),
                child: Icon(
                  _getAchievementIcon(achievement.id),
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 达成条件
            const Text(
              '达成条件：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.condition,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            
            // 奖励
            const Text(
              '奖励：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.reward,
              style: const TextStyle(fontSize: 14),
            ),
            
            if (achievement.isUnlocked) ...[
              const SizedBox(height: 12),
              const Text(
                '解锁时间：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(achievement.unlockedAt),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
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

  /// 显示成就帮助
  void _showAchievementHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('拾光成就说明'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '成就系统说明：',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '• 拾光初遇：完成首次测试\n'
                '• 影视拾光者：影视分类题库正确率≥90%\n'
                '• 音乐回响者：音乐分类题库正确率≥90%\n'
                '• 时代见证者：事件分类题库正确率≥90%\n'
                '• 拾光速答手：单次测试单题平均耗时≤15秒\n'
                '• 拾光挑战者：单次测试困难题正确率100%\n'
                '• 拾光收藏家：收藏题目数量≥20道\n'
                '• 拾光全勤人：连续7天每天完成1次测试',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '注意：成就数据仅保存在本地，卸载App将清空，珍惜每一份时光记忆～',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
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

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 构建空视图
  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 空状态图标
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 60,
                color: Colors.grey[400],
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
              ),
            ),
            const SizedBox(height: 16),
            
            // 空状态描述
            const Text(
              '开始你的拾光之旅吧！\n完成拾光、收藏题目，解锁更多成就～',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // 开始按钮
            ElevatedButton.icon(
              onPressed: () {
                // 跳转到答题页面
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const QuizScreen()),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始拾光'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 帮助按钮
            TextButton.icon(
              onPressed: () => _showAchievementHelp(context),
              icon: const Icon(Icons.help_outline),
              label: const Text('了解成就系统'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(AppConstants.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
