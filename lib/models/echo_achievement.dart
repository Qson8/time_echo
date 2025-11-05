/// 拾光成就数据模型
class EchoAchievement {
  final int id;
  final String achievementName; // 成就名称
  final String achievementIcon; // 成就图标路径
  final String reward; // 奖励描述
  final String condition; // 达成条件
  final bool isUnlocked; // 是否已解锁
  final DateTime unlockedAt; // 解锁时间

  EchoAchievement({
    required this.id,
    required this.achievementName,
    required this.achievementIcon,
    required this.reward,
    required this.condition,
    this.isUnlocked = false,
    required this.unlockedAt,
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
    
    return EchoAchievement(
      id: map['id'],
      achievementName: map['achievement_name'],
      achievementIcon: map['achievement_icon'],
      reward: map['reward'],
      condition: map['condition'],
      isUnlocked: map['is_unlocked'] == 1,
      unlockedAt: unlockedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'achievement_name': achievementName,
      'achievement_icon': achievementIcon,
      'reward': reward,
      'condition': condition,
      'is_unlocked': isUnlocked ? 1 : 0,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }
}
