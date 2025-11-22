import '../models/test_record.dart';
import '../models/question.dart';
import '../models/era_statistics.dart';
import 'json_storage_service.dart';

/// 拾光记录服务类（使用JSON文件存储）
class TestRecordService {
  static final TestRecordService _instance = TestRecordService._internal();
  factory TestRecordService() => _instance;
  TestRecordService._internal();

  final _storage = JsonStorageService();

  /// 添加拾光记录
  Future<int> addTestRecord(TestRecord record) async {
    print('📝 ========== 添加拾光记录 ==========');
    print('📝 📋 记录信息:');
    print('   - 初始ID: ${record.id}');
    print('   - 总题目数: ${record.totalQuestions}');
    print('   - 正确数: ${record.correctAnswers}');
    print('   - 正确率: ${record.accuracy}%');
    
    try {
      print('📝 💾 使用JSON存储保存...');
      final beforeRecords = await _storage.getAllTestRecords();
      final beforeTotal = beforeRecords.length;
      print('📝 📊 保存前拾光记录总数: $beforeTotal');
      
      final insertedId = await _storage.addTestRecord(record);
      print('📝 ✅ JSON存储保存成功');
      print('📝 📊 返回的记录ID: $insertedId');
      
      final afterRecords = await _storage.getAllTestRecords();
      final afterTotal = afterRecords.length;
      print('📝 📊 保存后拾光记录总数: $afterTotal');
      
      print('📝 ========== 拾光记录保存完成 ==========');
      return insertedId;
    } catch (e, stackTrace) {
      print('📝 ❌ JSON存储保存失败: $e');
      print('📝 ❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 获取所有拾光记录
  Future<List<TestRecord>> getAllTestRecords() async {
    try {
      final records = await _storage.getAllTestRecords();
      // 按拾光时间降序排序
      records.sort((a, b) => b.testTime.compareTo(a.testTime));
      return records;
    } catch (e) {
      print('获取拾光记录失败: $e');
      return [];
    }
  }

  /// 获取最近的拾光记录
  Future<List<TestRecord>> getRecentTestRecords(int limit) async {
    final allRecords = await getAllTestRecords();
    return allRecords.take(limit).toList();
  }

  /// 根据ID获取拾光记录
  Future<TestRecord?> getTestRecordById(int id) async {
    try {
      return await _storage.getTestRecordById(id);
    } catch (e) {
      print('获取拾光记录失败: $e');
      return null;
    }
  }

  /// 获取拾光记录总数
  Future<int> getTestRecordCount() async {
    final records = await getAllTestRecords();
    return records.length;
  }

  /// 获取平均准确率
  Future<double> getAverageAccuracy() async {
    final records = await getAllTestRecords();
    if (records.isEmpty) return 0.0;
    
    final totalAccuracy = records.fold<double>(0.0, (sum, record) => sum + record.accuracy);
    return totalAccuracy / records.length;
  }

  /// 获取平均拾光年龄
  Future<double> getAverageEchoAge() async {
    final records = await getAllTestRecords();
    if (records.isEmpty) return 0.0;
    
    final totalAge = records.fold<int>(0, (sum, record) => sum + record.echoAge);
    return totalAge / records.length;
  }

  /// 获取最佳成绩
  Future<TestRecord?> getBestScore() async {
    final records = await getAllTestRecords();
    if (records.isEmpty) return null;
    
    // 按准确率降序，时间升序排序
    records.sort((a, b) {
      final accuracyCompare = b.accuracy.compareTo(a.accuracy);
      if (accuracyCompare != 0) return accuracyCompare;
      return a.totalTime.compareTo(b.totalTime);
    });
    
    return records.first;
  }

  /// 获取连续拾光天数
  Future<int> getConsecutiveTestDays() async {
    final records = await getAllTestRecords();
    if (records.isEmpty) return 0;
    
    int consecutiveDays = 0;
    DateTime? lastTestDate;
    
    for (final record in records) {
      final testDate = record.testTime.toLocal();
      final testDay = DateTime(testDate.year, testDate.month, testDate.day);
      
      if (lastTestDate == null) {
        lastTestDate = testDay;
        consecutiveDays = 1;
      } else {
        final daysDifference = lastTestDate.difference(testDay).inDays;
        if (daysDifference == 1) {
          consecutiveDays++;
          lastTestDate = testDay;
        } else if (daysDifference > 1) {
          break;
        }
      }
    }
    
    return consecutiveDays;
  }

  /// 计算拾光年龄（根据各年代题目的答对情况）
  /// 对某个年代题目答对越多，说明记忆越接近那个年代，年龄也接近那个年代
  int calculateEchoAge({
    required List<Question> questions,
    required List<int> userAnswers,
  }) {
    if (questions.isEmpty || userAnswers.isEmpty) {
      return 35; // 默认年龄
    }

    // 提取年代并统计各年代的答题情况
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
    
    // 计算加权年龄：根据各年代的答对率加权
    // 逻辑修正：
    // 1. 答对率越高，说明对那个年代越熟悉，年龄应该更接近那个年代
    // 2. 如果整体准确率很低，说明用户对所有年代都不熟悉，应该返回默认年龄或较低年龄
    // 3. 只考虑答对率较高的年代参与计算，避免低准确率年代影响结果
    double weightedAge = 0.0;
    double totalWeight = 0.0;
    
    // 计算整体准确率
    int totalQuestions = 0;
    int totalCorrect = 0;
    eraStats.forEach((era, stats) {
      totalQuestions += stats.totalCount;
      totalCorrect += stats.correctCount;
    });
    final overallAccuracy = totalQuestions > 0 ? totalCorrect / totalQuestions : 0.0;
    
    print('📊 开始计算拾光年龄，各年代统计：');
    print('📊 整体准确率: ${(overallAccuracy * 100).toStringAsFixed(1)}%');
    
    // 如果整体准确率太低（<25%），说明用户对所有年代都不熟悉，返回默认年龄
    if (overallAccuracy < 0.25) {
      print('📊 ⚠️ 整体准确率过低（<25%），返回默认年龄35岁');
      return 35;
    }
    
    // 设置最低准确率阈值（40%），只有超过此阈值的年代才参与计算
    // 这样可以确保只有用户真正熟悉的年代才会影响年龄计算
    const minAccuracyThreshold = 0.4;
    
    eraStats.forEach((era, stats) {
      if (stats.totalCount > 0) {
        final accuracy = stats.correctCount / stats.totalCount;
        final eraAge = _getAgeForEra(era);
        
        // 优化权重计算：
        // 1. 只考虑准确率 >= 40% 的年代参与主要计算
        // 2. 权重 = (准确率 - 阈值)² * 题目数量
        //    这样确保：准确率越高权重越大，且准确率必须明显超过阈值才有意义
        double weight = 0.0;
        if (accuracy >= minAccuracyThreshold) {
          // 对于超过阈值的年代，使用调整后的准确率计算权重
          final adjustedAccuracy = (accuracy - minAccuracyThreshold) / (1.0 - minAccuracyThreshold); // 归一化到0-1
          weight = adjustedAccuracy * adjustedAccuracy * stats.totalCount; // 使用调整后的准确率平方
        }
        // 低于阈值的年代不参与计算（weight = 0）
        
        if (weight > 0) {
          weightedAge += eraAge * weight;
          totalWeight += weight;
          print('📊 $era: 答对 ${stats.correctCount}/${stats.totalCount} = ${(accuracy * 100).toStringAsFixed(1)}%, 对应年龄=$eraAge岁, 权重=$weight');
        } else {
          print('📊 $era: 答对 ${stats.correctCount}/${stats.totalCount} = ${(accuracy * 100).toStringAsFixed(1)}%, 对应年龄=$eraAge岁, 权重=0 (低于阈值${(minAccuracyThreshold * 100).toInt()}%)');
        }
      }
    });
    
    if (totalWeight == 0 || totalWeight < 0.1) {
      print('📊 ⚠️ 没有符合条件的年代（准确率>=40%），根据整体准确率返回调整后的默认年龄');
      // 如果整体准确率在25%-40%之间，返回一个基于整体准确率调整的年龄
      // 准确率越低，年龄越接近默认值35岁
      final adjustedDefaultAge = (35 + (overallAccuracy - 0.25) * 20).round(); // 25%时35岁，40%时38岁
      return adjustedDefaultAge.clamp(15, 80);
    }
    
    // 计算最终年龄
    final calculatedAge = (weightedAge / totalWeight).round();
    print('📊 ✅ 计算完成：加权年龄 = $calculatedAge岁 (总权重=$totalWeight)');
    
    // 根据整体准确率进一步调整年龄：
    // 整体准确率越高，年龄越接近计算结果；整体准确率越低，年龄越接近默认值
    // 这样可以避免：即使某个年代准确率高，但整体准确率低时，年龄也不会异常偏高
    final accuracyFactor = overallAccuracy.clamp(0.4, 1.0); // 只考虑40%以上的准确率
    final adjustedAge = (calculatedAge * accuracyFactor + 35 * (1 - accuracyFactor)).round();
    print('📊 ✅ 根据整体准确率(${(overallAccuracy * 100).toStringAsFixed(1)}%)调整后年龄 = $adjustedAge岁');
    
    // 确保年龄在合理范围内（15-80岁）
    return adjustedAge.clamp(15, 80);
  }
  
  /// 从主题中提取年代
  String _extractEraFromTheme(String theme) {
    // 提取数字部分（如 "80年代影视" -> "80年代"）
    final regex = RegExp(r'(\d+)年代');
    final match = regex.firstMatch(theme);
    if (match != null) {
      return match.group(0)!; // 返回 "80年代"
    }
    // 如果没有匹配，返回默认值
    return '80年代';
  }
  
  /// 获取某个年代对应的年龄
  /// 如果对某个年代的题目答对率高，说明在那个年代是青少年时期（10-20岁），记忆最深刻
  /// 例如：对80年代的题熟悉 → 说明80年代时10-20岁 → 现在约40-50岁
  int _getAgeForEra(String era) {
    // 提取年代数字（如 "80年代" -> 80）
    final regex = RegExp(r'(\d+)年代');
    final match = regex.firstMatch(era);
    if (match != null) {
      final eraDecade = int.parse(match.group(1)!); // 80, 90, 00等
      final currentYear = DateTime.now().year;
      
      // 如果对某个年代的题熟悉，说明在那个年代的10-20岁时期（记忆最深刻的时期）
      // 计算方法：该年代中期年份 + 15（假设15岁是最有记忆的年龄） = 出生年份
      // 现在年龄 = 当前年份 - 出生年份
      // 80年代中期约为1985年，如果是15岁，则出生年份约1970，现在年龄约54岁
      // 90年代中期约为1995年，如果是15岁，则出生年份约1980，现在年龄约44岁
      // 00年代中期约为2005年，如果是15岁，则出生年份约1990，现在年龄约34岁
      final eraMidYear = 1900 + eraDecade + 5; // 年代中期，如1985, 1995, 2005
      final birthYear = eraMidYear - 15; // 假设在那个年代时15岁
      final calculatedAge = currentYear - birthYear;
      
      // 确保年龄在合理范围内
      return calculatedAge.clamp(15, 80);
    }
    return 35; // 默认年龄
  }

  /// 删除指定的拾光记录
  Future<bool> deleteTestRecord(int id) async {
    try {
      await _storage.deleteTestRecord(id);
      return true;
    } catch (e) {
      print('删除拾光记录失败: $e');
      return false;
    }
  }

  /// 清除所有拾光记录
  Future<void> clearAllRecords() async {
    try {
      await _storage.clearAllTestRecords();
      print('✅ 所有拾光记录已清除');
    } catch (e) {
      print('❌ 清除拾光记录失败: $e');
      rethrow;
    }
  }
}
