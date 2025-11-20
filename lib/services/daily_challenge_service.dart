import 'dart:math';
import '../models/daily_challenge.dart';
import '../models/test_record.dart';
import 'json_storage_service.dart';
import 'test_record_service.dart';

/// 每日挑战服务类（完全离线，支持鸿蒙平台）
class DailyChallengeService {
  static final DailyChallengeService _instance = DailyChallengeService._internal();
  factory DailyChallengeService() => _instance;
  DailyChallengeService._internal();

  final JsonStorageService _jsonStorage = JsonStorageService();
  final TestRecordService _testRecordService = TestRecordService();
  static const String _challengesFile = 'daily_challenges.json';
  bool _initialized = false;

  List<DailyChallenge> _challenges = [];

  /// 初始化服务
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('🎯 初始化每日挑战服务...');
      await _jsonStorage.initialize();
      await _loadChallenges();
      _initialized = true;
      print('✅ 每日挑战服务初始化成功');
    } catch (e) {
      print('❌ 每日挑战服务初始化失败: $e');
      rethrow;
    }
  }

  /// 加载所有挑战
  Future<void> _loadChallenges() async {
    try {
      final data = await _jsonStorage.readJsonFile(_challengesFile);
      if (data != null && data is List) {
        _challenges = (data as List)
            .map((item) => DailyChallenge.fromMap(item as Map<String, dynamic>))
            .toList();
        print('✅ 加载了 ${_challenges.length} 个挑战');
      } else {
        _challenges = [];
        print('🎯 没有找到挑战数据，使用空列表');
      }
    } catch (e) {
      print('⚠️ 加载挑战失败: $e，使用空列表');
      _challenges = [];
    }
  }

  /// 保存所有挑战
  Future<void> _saveChallenges() async {
    try {
      final data = _challenges.map((challenge) => challenge.toMap()).toList();
      await _jsonStorage.writeJsonFile(_challengesFile, data);
      print('✅ 保存了 ${_challenges.length} 个挑战');
    } catch (e) {
      print('❌ 保存挑战失败: $e');
      rethrow;
    }
  }

  /// 生成今日挑战（如果还没有生成）
  Future<List<DailyChallenge>> getTodayChallenges() async {
    await initialize();

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    // 检查今天是否已有挑战
    final todayChallenges = _challenges.where((c) {
      final challengeDate = '${c.date.year}-${c.date.month}-${c.date.day}';
      return challengeDate == todayStr;
    }).toList();

    // 如果今天还没有挑战，生成新的
    if (todayChallenges.isEmpty) {
      final newChallenges = _generateDailyChallenges(today);
      _challenges.addAll(newChallenges);
      await _saveChallenges();
      return newChallenges;
    }

    return todayChallenges;
  }

  /// 生成每日挑战
  List<DailyChallenge> _generateDailyChallenges(DateTime date) {
    final random = Random();
    final challenges = <DailyChallenge>[];

    // 挑战1：准确率挑战
    final accuracyTarget = 80 + random.nextInt(20); // 80-100%
    challenges.add(DailyChallenge(
      id: _getNextId(),
      title: '精准答题',
      description: '在答题中达到 $accuracyTarget% 的准确率',
      type: ChallengeType.accuracy,
      targetValue: accuracyTarget,
      date: date,
      rewardPoints: 15,
    ));

    // 挑战2：速度挑战
    final speedTarget = 15 + random.nextInt(10); // 15-25秒
    challenges.add(DailyChallenge(
      id: _getNextId(),
      title: '快速答题',
      description: '单题平均耗时不超过 $speedTarget 秒',
      type: ChallengeType.speed,
      targetValue: speedTarget,
      date: date,
      rewardPoints: 20,
    ));

    // 挑战3：分类专精
    final categories = ['影视', '音乐', '事件'];
    final category = categories[random.nextInt(categories.length)];
    final categoryTarget = 5 + random.nextInt(5); // 5-10题
    challenges.add(DailyChallenge(
      id: _getNextId(),
      title: '$category 专精',
      description: '完成 $categoryTarget 道 $category 分类题目',
      type: ChallengeType.category,
      targetValue: categoryTarget,
      date: date,
      rewardPoints: 12,
    ));

    return challenges;
  }

  /// 获取下一个ID
  int _getNextId() {
    if (_challenges.isEmpty) return 1;
    return _challenges.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// 更新挑战进度
  Future<void> updateChallengeProgress(int challengeId, int newValue) async {
    await initialize();

    final index = _challenges.indexWhere((c) => c.id == challengeId);
    if (index != -1) {
      final challenge = _challenges[index];
      final updatedChallenge = challenge.copyWith(
        currentValue: newValue,
        isCompleted: newValue >= challenge.targetValue,
        completedAt: newValue >= challenge.targetValue ? DateTime.now() : null,
      );
      _challenges[index] = updatedChallenge;
      await _saveChallenges();
    }
  }

  /// 根据答题记录更新挑战进度
  Future<void> updateChallengesFromTestRecord(TestRecord record) async {
    await initialize();

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    // 获取今日挑战
    final todayChallenges = _challenges.where((c) {
      final challengeDate = '${c.date.year}-${c.date.month}-${c.date.day}';
      return challengeDate == todayStr && !c.isCompleted;
    }).toList();

    for (final challenge in todayChallenges) {
      int newValue = challenge.currentValue;

      switch (challenge.type) {
        case ChallengeType.accuracy:
          // 准确率挑战：检查本次答题的准确率
          final accuracy = (record.accuracy * 100).toInt();
          if (accuracy >= challenge.targetValue) {
            newValue = challenge.targetValue;
          } else {
            newValue = accuracy; // 更新为当前最高准确率
          }
          break;

        case ChallengeType.speed:
          // 速度挑战：检查平均耗时
          if (record.totalTime > 0 && record.totalQuestions > 0) {
            final avgTime = (record.totalTime / record.totalQuestions).round();
            if (avgTime <= challenge.targetValue) {
              newValue = challenge.targetValue;
            } else {
              newValue = max(newValue, challenge.targetValue - avgTime);
            }
          }
          break;

        case ChallengeType.category:
          // 分类专精：检查分类答题数
          final categoryScores = record.categoryScores;
          if (categoryScores != null) {
            // 从描述中提取分类名称
            String? targetCategory;
            if (challenge.description.contains('影视')) {
              targetCategory = '影视';
            } else if (challenge.description.contains('音乐')) {
              targetCategory = '音乐';
            } else if (challenge.description.contains('事件')) {
              targetCategory = '事件';
            }

            if (targetCategory != null && categoryScores.containsKey(targetCategory)) {
              // categoryScores 是 Map<String, int>，直接获取值
              newValue = categoryScores[targetCategory] ?? 0;
            }
          }
          break;

        case ChallengeType.streak:
          // 连击挑战：需要从答题过程中记录，这里暂时不处理
          break;

        case ChallengeType.total:
          // 总题数挑战
          newValue = record.totalQuestions;
          break;
      }

      await updateChallengeProgress(challenge.id, newValue);
    }
  }

  /// 获取所有挑战
  Future<List<DailyChallenge>> getAllChallenges() async {
    await initialize();
    return List.unmodifiable(_challenges);
  }

  /// 获取已完成的挑战
  Future<List<DailyChallenge>> getCompletedChallenges() async {
    await initialize();
    return _challenges.where((c) => c.isCompleted).toList();
  }

  /// 获取统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    await initialize();

    final total = _challenges.length;
    final completed = _challenges.where((c) => c.isCompleted).length;
    final todayChallenges = await getTodayChallenges();
    final todayCompleted = todayChallenges.where((c) => c.isCompleted).length;

    return {
      'total': total,
      'completed': completed,
      'completion_rate': total > 0 ? completed / total : 0.0,
      'today_total': todayChallenges.length,
      'today_completed': todayCompleted,
    };
  }
}

