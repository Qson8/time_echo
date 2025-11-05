import '../models/test_record.dart';
import '../models/question.dart';
import '../models/era_statistics.dart';
import 'json_storage_service.dart';

/// 测试记录服务类（使用JSON文件存储）
class TestRecordService {
  static final TestRecordService _instance = TestRecordService._internal();
  factory TestRecordService() => _instance;
  TestRecordService._internal();

  final _storage = JsonStorageService();

  /// 添加测试记录
  Future<int> addTestRecord(TestRecord record) async {
    print('📝 ========== 添加测试记录 ==========');
    print('📝 📋 记录信息:');
    print('   - 初始ID: ${record.id}');
    print('   - 总题目数: ${record.totalQuestions}');
    print('   - 正确数: ${record.correctAnswers}');
    print('   - 正确率: ${record.accuracy}%');
    
    try {
      print('📝 💾 使用JSON存储保存...');
      final beforeRecords = await _storage.getAllTestRecords();
      final beforeTotal = beforeRecords.length;
      print('📝 📊 保存前测试记录总数: $beforeTotal');
      
      final insertedId = await _storage.addTestRecord(record);
      print('📝 ✅ JSON存储保存成功');
      print('📝 📊 返回的记录ID: $insertedId');
      
      final afterRecords = await _storage.getAllTestRecords();
      final afterTotal = afterRecords.length;
      print('📝 📊 保存后测试记录总数: $afterTotal');
      
      print('📝 ========== 测试记录保存完成 ==========');
      return insertedId;
    } catch (e, stackTrace) {
      print('📝 ❌ JSON存储保存失败: $e');
      print('📝 ❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 获取所有测试记录
  Future<List<TestRecord>> getAllTestRecords() async {
    try {
      final records = await _storage.getAllTestRecords();
      // 按测试时间降序排序
      records.sort((a, b) => b.testTime.compareTo(a.testTime));
      return records;
    } catch (e) {
      print('获取测试记录失败: $e');
      return [];
    }
  }

  /// 获取最近的测试记录
  Future<List<TestRecord>> getRecentTestRecords(int limit) async {
    final allRecords = await getAllTestRecords();
    return allRecords.take(limit).toList();
  }

  /// 根据ID获取测试记录
  Future<TestRecord?> getTestRecordById(int id) async {
    try {
      return await _storage.getTestRecordById(id);
    } catch (e) {
      print('获取测试记录失败: $e');
      return null;
    }
  }

  /// 获取测试记录总数
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

  /// 获取连续测试天数
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
    // 权重 = 答对率 * 该年代题目数量
    // 如果对某个年代答对率高，说明记忆更深刻，应该更倾向于那个年代的年龄
    double weightedAge = 0.0;
    double totalWeight = 0.0;
    
    print('📊 开始计算拾光年龄，各年代统计：');
    
    eraStats.forEach((era, stats) {
      if (stats.totalCount > 0) {
        final accuracy = stats.correctCount / stats.totalCount;
        final eraAge = _getAgeForEra(era);
        
        // 权重计算：答对率越高、题目越多，权重越大
        // 答对率高的年代，说明记忆更清晰，应该更偏向那个年代的年龄
        final weight = accuracy * accuracy * stats.totalCount; // 答对率平方，让高答对率的影响更大
        
        weightedAge += eraAge * weight;
        totalWeight += weight;
        
        print('📊 $era: 答对 ${stats.correctCount}/${stats.totalCount} = ${(accuracy * 100).toStringAsFixed(1)}%, 对应年龄=$eraAge岁, 权重=$weight');
      }
    });
    
    if (totalWeight == 0) {
      print('📊 没有有效统计数据，返回默认年龄35岁');
      return 35; // 默认年龄
    }
    
    // 计算最终年龄
    final calculatedAge = (weightedAge / totalWeight).round();
    print('📊 ✅ 计算完成：加权年龄 = $calculatedAge岁');
    
    // 确保年龄在合理范围内（15-80岁）
    return calculatedAge.clamp(15, 80);
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

  /// 删除指定的测试记录
  Future<bool> deleteTestRecord(int id) async {
    try {
      await _storage.deleteTestRecord(id);
      return true;
    } catch (e) {
      print('删除测试记录失败: $e');
      return false;
    }
  }

  /// 清除所有测试记录
  Future<void> clearAllRecords() async {
    try {
      await _storage.clearAllTestRecords();
      print('✅ 所有测试记录已清除');
    } catch (e) {
      print('❌ 清除测试记录失败: $e');
      rethrow;
    }
  }
}
