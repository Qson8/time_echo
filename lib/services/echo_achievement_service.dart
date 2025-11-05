import '../models/echo_achievement.dart';
import '../models/test_record.dart';
import '../models/question.dart';
import '../models/era_statistics.dart';
import 'json_storage_service.dart';
import 'test_record_service.dart';

/// 拾光成就服务类（使用JSON文件存储）
class EchoAchievementService {
  static final EchoAchievementService _instance = EchoAchievementService._internal();
  factory EchoAchievementService() => _instance;
  EchoAchievementService._internal();

  final _storage = JsonStorageService();

  /// 获取所有成就
  Future<List<EchoAchievement>> getAllAchievements() async {
    return await _storage.getAllAchievements();
  }

  /// 获取已解锁的成就
  Future<List<EchoAchievement>> getUnlockedAchievements() async {
    final allAchievements = await _storage.getAllAchievements();
    final unlocked = allAchievements.where((a) => a.isUnlocked).toList();
    // 按解锁时间降序排序
    unlocked.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    return unlocked;
  }

  /// 解锁成就
  Future<void> unlockAchievement(int achievementId) async {
    try {
      print('🏆 ========== 开始解锁成就 ==========');
      print('🏆 🎯 成就ID: $achievementId');
      
      // 先检查成就是否存在
      final achievementBefore = await getAchievementById(achievementId);
      if (achievementBefore == null) {
        print('🏆 ❌ 错误：成就 ID=$achievementId 不存在！');
        throw Exception('成就不存在: ID=$achievementId');
      }
      print('🏆 📋 成就名称: ${achievementBefore.achievementName}');
      print('🏆 📋 成就条件: ${achievementBefore.condition}');
      print('🏆 🔓 解锁前状态: ${achievementBefore.isUnlocked}');
      
      final unlockedAt = DateTime.now();
      print('🏆 📅 解锁时间: ${unlockedAt.toIso8601String()}');
      
      print('🏆 💾 执行JSON存储更新操作...');
      
      // 更新成就状态
      final updatedAchievement = EchoAchievement(
        id: achievementBefore.id,
        achievementName: achievementBefore.achievementName,
        achievementIcon: achievementBefore.achievementIcon,
        reward: achievementBefore.reward,
        condition: achievementBefore.condition,
        isUnlocked: true,
        unlockedAt: unlockedAt,
      );
      
      await _storage.updateAchievement(updatedAchievement);
      
      print('🏆 ✅ JSON存储更新完成');
      
      // 验证解锁是否成功
      print('🏆 🔍 验证解锁结果...');
      final achievementAfter = await getAchievementById(achievementId);
      if (achievementAfter != null) {
        print('🏆 📋 验证：成就名称: ${achievementAfter.achievementName}');
        print('🏆 🔓 验证：解锁状态: ${achievementAfter.isUnlocked}');
        print('🏆 📅 验证：解锁时间: ${achievementAfter.unlockedAt}');
        
        if (achievementAfter.isUnlocked) {
          print('🏆 ✅ ✅ 成就解锁验证成功！');
        } else {
          print('🏆 ❌ 错误：成就解锁后验证失败，状态仍为未解锁！');
        }
      } else {
        print('🏆 ❌ 错误：解锁后无法查询到成就对象！');
      }
      
      print('🏆 ========== 解锁成就流程完成 ==========');
    } catch (e, stackTrace) {
      print('🏆 ❌ 解锁成就失败: $e');
      print('🏆 ❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 检查成就是否已解锁
  Future<bool> isAchievementUnlocked(int achievementId) async {
    final achievement = await getAchievementById(achievementId);
    return achievement?.isUnlocked ?? false;
  }

  /// 获取已解锁成就数量
  Future<int> getUnlockedAchievementCount() async {
    final allAchievements = await _storage.getAllAchievements();
    return allAchievements.where((a) => a.isUnlocked).length;
  }

  /// 获取总成就数量
  Future<int> getTotalAchievementCount() async {
    final allAchievements = await _storage.getAllAchievements();
    return allAchievements.length;
  }

  /// 检查并解锁成就
  Future<List<EchoAchievement>> checkAndUnlockAchievements(
    TestRecord testRecord, {
    List<Question>? questions,
    List<int>? userAnswers,
  }) async {
    print('🏆 ========== 开始检查成就 ==========');
    print('🏆 测试记录 ID: ${testRecord.id}');
    print('🏆 正确率: ${testRecord.accuracy}%');
    print('🏆 总题目数: ${testRecord.totalQuestions}');
    print('🏆 分类得分: ${testRecord.categoryScores}');
    
    try {
      print('🏆 ✅ JSON存储服务连接成功');
      
      // 验证成就数据是否存在
      final achievementCount = await getTotalAchievementCount();
      print('🏆 成就总数: $achievementCount');
      if (achievementCount == 0) {
        print('🏆 ⚠️ 警告：成就列表为空，可能需要初始化默认数据！');
      }
      
      final List<EchoAchievement> newAchievements = [];

      // 检查拾光初遇成就（检查是否是第一次完成测试）
      print('🏆 ========== 开始检查拾光初遇成就 ==========');
      
      // 获取测试记录的基本信息
      final testRecordId = testRecord.id;
      print('🏆 📝 测试记录 ID: $testRecordId');
      
      // 方法1：查询数据库中的记录总数（包含刚保存的这条）
      final totalRecordCount = await _getTotalRecordCount();
      print('🏆 📊 当前测试记录总数: $totalRecordCount');
      
      // 方法2：验证成就ID=1是否存在
      final achievement1 = await getAchievementById(1);
      if (achievement1 == null) {
        print('🏆 ❌ 严重错误：无法找到拾光初遇成就（ID=1）！');
        print('🏆 ⚠️ 跳过拾光初遇成就检查');
      } else {
        print('🏆 ✅ 找到拾光初遇成就: ${achievement1.achievementName}');
        print('🏆 📋 成就条件: ${achievement1.condition}');
        print('🏆 🔓 当前解锁状态: ${achievement1.isUnlocked}');
        
        // 检查成就是否已解锁
        final isAlreadyUnlocked = await isAchievementUnlocked(1);
        print('🏆 🔍 验证解锁状态查询结果: $isAlreadyUnlocked');
        
        // 判断是否为首次测试的多种条件
        // 条件1：记录总数刚好是1（说明这是第一条记录）
        // 条件2：记录ID为1（如果是数据库自增，第一条记录通常是1）
        // 条件3：如果成就未解锁且这是第一条或第二条记录（容错，因为可能有测试数据）
        final isFirstTestByCount = (totalRecordCount == 1);
        final isFirstTestById = (testRecordId == 1);
        final isFirstTest = isFirstTestByCount || isFirstTestById;
        
        print('🏆 🔍 判断结果:');
        print('   - 按记录总数判断（总数==1）: $isFirstTestByCount');
        print('   - 按记录ID判断（ID==1）: $isFirstTestById');
        print('   - 综合判断为首次测试: $isFirstTest');
        
        if (isFirstTest && !isAlreadyUnlocked) {
          print('🏆 🎯 检测到首次测试且成就未解锁，准备解锁拾光初遇成就...');
          try {
            await unlockAchievement(1);
            print('🏆 ✅ 解锁操作完成，正在验证...');
            
            // 验证解锁是否成功
            final unlockedAchievement = await getAchievementById(1);
            if (unlockedAchievement != null) {
              print('🏆 ✅ 成就对象获取成功');
              print('🏆 📋 成就名称: ${unlockedAchievement.achievementName}');
              print('🏆 🔓 解锁状态: ${unlockedAchievement.isUnlocked}');
              print('🏆 📅 解锁时间: ${unlockedAchievement.unlockedAt}');
              
              if (unlockedAchievement.isUnlocked) {
                newAchievements.add(unlockedAchievement);
                print('🏆 ✅ ✅ 拾光初遇成就已成功解锁并添加到新成就列表！');
              } else {
                print('🏆 ❌ 错误：解锁操作后，成就状态仍为未解锁！');
                print('🏆 ⚠️ 可能存在数据库写入问题或事务未提交');
              }
            } else {
              print('🏆 ❌ 错误：解锁后无法获取成就对象！');
            }
          } catch (e, stackTrace) {
            print('🏆 ❌ 解锁拾光初遇成就时发生异常: $e');
            print('🏆 ❌ 错误堆栈: $stackTrace');
          }
        } else if (isAlreadyUnlocked) {
          print('🏆 ℹ️ 拾光初遇成就已经解锁，跳过');
          // 即使已解锁，也检查一下成就对象是否正常
          final unlockedAchievement = await getAchievementById(1);
          if (unlockedAchievement != null) {
            print('🏆 📋 已解锁的成就信息: ${unlockedAchievement.achievementName}');
            print('🏆 📅 解锁时间: ${unlockedAchievement.unlockedAt}');
          }
        } else {
          print('🏆 ℹ️ 不满足首次测试条件，跳过拾光初遇成就');
          print('🏆 📊 详情: 记录ID=$testRecordId, 记录总数=$totalRecordCount');
          if (!isFirstTest) {
            print('🏆 💡 提示: 这可能是第二次或更多次测试');
          }
        }
      }
      print('🏆 ========== 拾光初遇成就检查完成 ==========');

      // 检查影视拾光者成就
      if (testRecord.categoryScores['影视'] != null && 
          testRecord.categoryScores['影视']! >= 90 && 
          !await isAchievementUnlocked(2)) {
        await unlockAchievement(2);
        final achievement = await getAchievementById(2);
        if (achievement != null) {
          newAchievements.add(achievement);
          print('🏆 ✅ 解锁成就：影视拾光者');
        }
      }

      // 检查音乐回响者成就
      if (testRecord.categoryScores['音乐'] != null && 
          testRecord.categoryScores['音乐']! >= 90 && 
          !await isAchievementUnlocked(3)) {
        await unlockAchievement(3);
        final achievement = await getAchievementById(3);
        if (achievement != null) {
          newAchievements.add(achievement);
          print('🏆 ✅ 解锁成就：音乐回响者');
        }
      }

      // 检查时代见证者成就
      if (testRecord.categoryScores['事件'] != null && 
          testRecord.categoryScores['事件']! >= 90 && 
          !await isAchievementUnlocked(4)) {
        await unlockAchievement(4);
        final achievement = await getAchievementById(4);
        if (achievement != null) {
          newAchievements.add(achievement);
          print('🏆 ✅ 解锁成就：时代见证者');
        }
      }

      // 检查拾光速答手成就
      final averageTime = testRecord.totalTime / testRecord.totalQuestions;
      if (averageTime <= 15 && !await isAchievementUnlocked(5)) {
        await unlockAchievement(5);
        final achievement = await getAchievementById(5);
        if (achievement != null) {
          newAchievements.add(achievement);
          print('🏆 ✅ 解锁成就：拾光速答手');
        }
      }

      // 检查拾光挑战者成就（需要传入题目和答案）
      if (questions != null && userAnswers != null) {
        await checkChallengeAchievement(questions, userAnswers);
        final challengeAchievement = await getAchievementById(6);
        if (challengeAchievement != null && 
            challengeAchievement.isUnlocked && 
            !newAchievements.any((a) => a.id == 6)) {
          newAchievements.add(challengeAchievement);
        }
      }

      // 检查拾光全勤人成就
      await checkAttendanceAchievement();
      final attendanceAchievement = await getAchievementById(8);
      if (attendanceAchievement != null && 
          attendanceAchievement.isUnlocked && 
          !newAchievements.any((a) => a.id == 8)) {
        newAchievements.add(attendanceAchievement);
      }

      // 检查基于年代的成就（80年代专家、90年代专家、00年代专家）
      if (questions != null && userAnswers != null) {
        await checkEraExpertAchievements(questions, userAnswers);
        for (int achievementId in [9, 10, 11]) {
          final achievement = await getAchievementById(achievementId);
          if (achievement != null && 
              achievement.isUnlocked && 
              !newAchievements.any((a) => a.id == achievementId)) {
            newAchievements.add(achievement);
          }
        }
      }

      // 检查拾光完美主义者成就（100%正确率）
      if (testRecord.accuracy >= 100.0 && !await isAchievementUnlocked(13)) {
        await unlockAchievement(13);
        final achievement = await getAchievementById(13);
        if (achievement != null) {
          newAchievements.add(achievement);
          print('🏆 ✅ 解锁成就：拾光完美主义者');
        }
      }

      // 检查拾光记忆大师成就（累计测试次数≥30）
      // 重用之前已获取的 totalRecordCount 变量
      if (totalRecordCount >= 30 && !await isAchievementUnlocked(12)) {
        await unlockAchievement(12);
        final achievement = await getAchievementById(12);
        if (achievement != null && 
            !newAchievements.any((a) => a.id == 12)) {
          newAchievements.add(achievement);
          print('🏆 ✅ 解锁成就：拾光记忆大师');
        }
      }
      
      print('🏆 ✅ 成就检查完成，共解锁 ${newAchievements.length} 个新成就');
      if (newAchievements.isNotEmpty) {
        print('🏆 新解锁的成就列表:');
        for (final achievement in newAchievements) {
          print('   - ${achievement.achievementName} (ID: ${achievement.id})');
        }
      }
      return newAchievements;
    } catch (e, stackTrace) {
      print('🏆 ❌ 检查并解锁成就失败: $e');
      print('🏆 ❌ 错误堆栈: $stackTrace');
      print('🏆 ⚠️ 注意：返回空列表，不影响测试完成流程');
      // 返回空列表，不影响测试完成流程
      return [];
    }
  }
  
  /// 获取测试记录总数（用于判断是否首次测试）
  Future<int> _getTotalRecordCount() async {
    try {
      print('🏆 🔍 查询测试记录总数...');
      
      // 使用 TestRecordService 获取记录
      final testRecordService = TestRecordService();
      final allRecords = await testRecordService.getAllTestRecords();
      final count = allRecords.length;
      
      print('🏆 📊 查询到的记录数量: $count');
      
      // 如果记录数大于0，打印前几条记录的ID
      if (allRecords.length > 0) {
        final recordIds = allRecords.take(5).map((r) => r.id).toList();
        print('🏆 📋 前几条记录的ID: $recordIds');
      }
      
      print('🏆 ✅ 测试记录总数查询成功: $count');
      
      return count;
    } catch (e, stackTrace) {
      print('🏆 ❌ 获取测试记录总数失败: $e');
      print('🏆 ❌ 错误堆栈: $stackTrace');
      return 0;
    }
  }
  
  /// 检查拾光挑战者成就（需要传入题目和答案以检查困难题正确率）
  Future<void> checkChallengeAchievement(
    List<Question> questions,
    List<int> userAnswers,
  ) async {
    try {
      // 筛选出困难题
      final difficultQuestions = <Question>[];
      final difficultAnswers = <int>[];
      
      for (int i = 0; i < questions.length; i++) {
        if (questions[i].difficulty == '困难') {
          difficultQuestions.add(questions[i]);
          difficultAnswers.add(userAnswers[i]);
        }
      }
      
      // 如果没有困难题，跳过
      if (difficultQuestions.isEmpty) {
        return;
      }
      
      // 检查困难题正确率是否为100%
      bool allCorrect = true;
      for (int i = 0; i < difficultQuestions.length; i++) {
        if (difficultAnswers[i] != difficultQuestions[i].correctAnswer) {
          allCorrect = false;
          break;
        }
      }
      
      // 如果困难题全部答对，解锁成就
      if (allCorrect && !await isAchievementUnlocked(6)) {
        await unlockAchievement(6);
        print('🏆 ✅ 解锁成就：拾光挑战者');
      }
    } catch (e) {
      print('检查拾光挑战者成就失败: $e');
    }
  }
  
  /// 检查拾光全勤人成就（连续7天每天完成1次测试）
  Future<void> checkAttendanceAchievement() async {
    try {
      final testRecordService = TestRecordService();
      final allRecords = await testRecordService.getAllTestRecords();
      
      if (allRecords.length < 7) {
        return; // 记录不足7条，无法达成
      }
      
      // 按日期分组，统计每天完成的次数
      final dailyRecords = <String, int>{};
      for (final record in allRecords) {
        final testTime = record.testTime;
        final dateKey = '${testTime.year}-${testTime.month.toString().padLeft(2, '0')}-${testTime.day.toString().padLeft(2, '0')}';
        dailyRecords[dateKey] = (dailyRecords[dateKey] ?? 0) + 1;
      }
      
      // 检查最近7天是否每天都有记录
      final now = DateTime.now();
      bool allDaysHaveRecord = true;
      for (int i = 0; i < 7; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dateKey = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        if (!dailyRecords.containsKey(dateKey) || dailyRecords[dateKey] == 0) {
          allDaysHaveRecord = false;
          break;
        }
      }
      
      if (allDaysHaveRecord && !await isAchievementUnlocked(8)) {
        await unlockAchievement(8);
        print('🏆 ✅ 解锁成就：拾光全勤人');
      }
    } catch (e) {
      print('检查拾光全勤人成就失败: $e');
    }
  }


  /// 根据ID获取成就
  Future<EchoAchievement?> getAchievementById(int id) async {
    return await _storage.getAchievementById(id);
  }

  /// 检查拾光收藏家成就
  Future<void> checkCollectorAchievement(int collectionCount) async {
    if (collectionCount >= 20 && !await isAchievementUnlocked(7)) {
      await unlockAchievement(7);
      print('🏆 ✅ 解锁成就：拾光收藏家');
    }
  }
  
  /// 检查基于年代的专家成就
  Future<void> checkEraExpertAchievements(
    List<Question> questions,
    List<int> userAnswers,
  ) async {
    // 统计各年代的答题情况
    final eraStats = <String, EraStatistics>{};
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final userAnswer = userAnswers[i];
      final isCorrect = userAnswer == question.correctAnswer;
      
      // 从 echoTheme 中提取年代（如 "80年代影视" -> "80年代"）
      String era = _extractEraFromTheme(question.echoTheme);
      
      if (!eraStats.containsKey(era)) {
        eraStats[era] = EraStatistics();
      }
      
      final stats = eraStats[era]!;
      stats.totalCount++;
      if (isCorrect) {
        stats.correctCount++;
      }
    }
    
    // 检查各年代专家成就
    for (final entry in eraStats.entries) {
      final era = entry.key;
      final stats = entry.value;
      
      if (stats.totalCount > 0) {
        final accuracy = (stats.correctCount / stats.totalCount) * 100;
        
        // 80年代专家 (ID: 9)
        if (era == '80年代' && accuracy >= 90 && !await isAchievementUnlocked(9)) {
          await unlockAchievement(9);
          print('🏆 ✅ 解锁成就：80年代专家');
        }
        
        // 90年代专家 (ID: 10)
        if (era == '90年代' && accuracy >= 90 && !await isAchievementUnlocked(10)) {
          await unlockAchievement(10);
          print('🏆 ✅ 解锁成就：90年代专家');
        }
        
        // 00年代专家 (ID: 11)
        if (era == '00年代' && accuracy >= 90 && !await isAchievementUnlocked(11)) {
          await unlockAchievement(11);
          print('🏆 ✅ 解锁成就：00年代专家');
        }
      }
    }
  }
  
  /// 从主题中提取年代
  String _extractEraFromTheme(String theme) {
    final regex = RegExp(r'(\d+)年代');
    final match = regex.firstMatch(theme);
    if (match != null) {
      return match.group(0)!; // 返回 "80年代"
    }
    return '80年代'; // 默认
  }

  /// 重置所有成就
  Future<void> resetAllAchievements() async {
    try {
      final allAchievements = await getAllAchievements();
      for (final achievement in allAchievements) {
        final resetAchievement = EchoAchievement(
          id: achievement.id,
          achievementName: achievement.achievementName,
          achievementIcon: achievement.achievementIcon,
          reward: achievement.reward,
          condition: achievement.condition,
          isUnlocked: false,
          unlockedAt: DateTime(1970, 1, 1),
        );
        await _storage.updateAchievement(resetAchievement);
      }
      print('🏆 ✅ 所有成就已重置');
    } catch (e) {
      print('🏆 ❌ 重置成就失败: $e');
      rethrow;
    }
  }
}
