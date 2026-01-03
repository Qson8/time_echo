import '../models/echo_achievement.dart';

/// 奖励系统服务
/// 处理成就解锁后的奖励发放
class RewardService {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  /// 发放成就奖励
  /// 根据成就的奖励类型和奖励值，执行相应的奖励逻辑
  Future<void> grantReward(EchoAchievement achievement) async {
    if (!achievement.isUnlocked) {
      print('🎁 [RewardService] 成就未解锁，无法发放奖励');
      return;
    }

    final rewardType = achievement.rewardType ?? RewardType.badge;
    final rewardValue = achievement.rewardValue;

    print('🎁 [RewardService] 发放奖励: ${achievement.achievementName}');
    print('🎁   奖励类型: ${rewardType.name}');
    print('🎁   奖励值: ${rewardValue ?? "无"}');

    switch (rewardType) {
      case RewardType.badge:
        // 徽章奖励，仅展示，无需额外处理
        print('🎁 ✅ 徽章奖励已解锁: ${achievement.achievementName}');
        break;

      case RewardType.points:
        // 积分奖励
        if (rewardValue != null) {
          await _grantPoints(rewardValue);
        }
        break;

      case RewardType.theme:
        // 主题解锁奖励
        await _unlockTheme(achievement);
        break;

      case RewardType.quote:
        // 语录奖励
        await _grantQuote(achievement);
        break;

      case RewardType.decoration:
        // 装饰奖励
        await _grantDecoration(achievement);
        break;

      case RewardType.special:
        // 特殊奖励
        await _grantSpecialReward(achievement);
        break;
    }
  }

  /// 发放积分奖励
  Future<void> _grantPoints(int points) async {
    // TODO: 实现积分系统
    print('🎁 ✅ 获得积分: $points');
  }

  /// 解锁主题
  Future<void> _unlockTheme(EchoAchievement achievement) async {
    // TODO: 实现主题解锁系统
    print('🎁 ✅ 解锁主题: ${achievement.achievementName}');
  }

  /// 发放语录奖励
  Future<void> _grantQuote(EchoAchievement achievement) async {
    // TODO: 实现语录系统
    print('🎁 ✅ 获得语录: ${achievement.achievementName}');
  }

  /// 发放装饰奖励
  Future<void> _grantDecoration(EchoAchievement achievement) async {
    // TODO: 实现装饰系统
    print('🎁 ✅ 获得装饰: ${achievement.achievementName}');
  }

  /// 发放特殊奖励
  Future<void> _grantSpecialReward(EchoAchievement achievement) async {
    // TODO: 实现特殊奖励系统
    print('🎁 ✅ 获得特殊奖励: ${achievement.achievementName}');
  }

  /// 获取奖励描述
  String getRewardDescription(RewardType? rewardType, int? rewardValue) {
    if (rewardType == null) {
      return '解锁成就徽章';
    }

    switch (rewardType) {
      case RewardType.badge:
        return '解锁成就徽章';
      case RewardType.points:
        return rewardValue != null ? '获得 $rewardValue 积分' : '获得积分';
      case RewardType.theme:
        return '解锁专属主题';
      case RewardType.quote:
        return '解锁怀旧语录';
      case RewardType.decoration:
        return '解锁装饰元素';
      case RewardType.special:
        return '解锁特殊奖励';
    }
  }
}

