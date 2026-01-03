/// 奖励类型枚举
enum RewardType {
  badge,           // 徽章（仅展示）
  points,          // 积分
  theme,           // 主题解锁
  quote,           // 语录
  decoration,      // 装饰
  special,         // 特殊奖励
}

/// 拾光成就数据模型
class EchoAchievement {
  final int id;
  final String achievementName; // 成就名称
  final String achievementIcon; // 成就图标路径
  final String reward; // 奖励描述
  final String condition; // 达成条件
  final bool isUnlocked; // 是否已解锁
  final DateTime unlockedAt; // 解锁时间
  final RewardType? rewardType; // 奖励类型（可选，向后兼容）
  final int? rewardValue; // 奖励值（可选，如积分数量等）

  EchoAchievement({
    required this.id,
    required this.achievementName,
    required this.achievementIcon,
    required this.reward,
    required this.condition,
    this.isUnlocked = false,
    required this.unlockedAt,
    this.rewardType,
    this.rewardValue,
  });

  factory EchoAchievement.fromMap(Map<String, dynamic> map) {
    // 安全地解析解锁时间，如果为空或无效则使用默认值
    DateTime unlockedTime;
    final unlockedAtStr = map['unlocked_at'];
    if (unlockedAtStr != null && unlockedAtStr.toString().isNotEmpty && unlockedAtStr.toString() != 'null') {
      try {
        unlockedTime = DateTime.parse(unlockedAtStr.toString());
      } catch (e) {
        // 如果解析失败，使用默认时间
        unlockedTime = DateTime(1970, 1, 1);
      }
    } else {
      // 如果字段为空或null，使用默认时间
      unlockedTime = DateTime(1970, 1, 1);
    }
    
    // 解析奖励类型（可选，向后兼容）
    RewardType? rewardType;
    if (map['reward_type'] != null) {
      try {
        rewardType = RewardType.values.firstWhere(
          (e) => e.name == map['reward_type'],
          orElse: () => RewardType.badge,
        );
      } catch (e) {
        rewardType = null;
      }
    }
    
    return EchoAchievement(
      id: map['id'],
      achievementName: map['achievement_name'],
      achievementIcon: map['achievement_icon'],
      reward: map['reward'],
      condition: map['condition'],
      isUnlocked: map['is_unlocked'] == 1,
      unlockedAt: unlockedTime,
      rewardType: rewardType,
      rewardValue: map['reward_value'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'achievement_name': achievementName,
      'achievement_icon': achievementIcon,
      'reward': reward,
      'condition': condition,
      'is_unlocked': isUnlocked ? 1 : 0,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
    
    // 可选字段，仅在存在时添加
    if (rewardType != null) {
      map['reward_type'] = rewardType!.name;
    }
    if (rewardValue != null) {
      map['reward_value'] = rewardValue!;
    }
    
    return map;
  }
}
