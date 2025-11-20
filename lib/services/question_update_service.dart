import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/question_update_log.dart';
import '../services/question_service.dart';
import '../services/json_storage_service.dart';
import '../constants/app_constants.dart';

/// 题库更新服务类
class QuestionUpdateService {
  static final QuestionUpdateService _instance = QuestionUpdateService._internal();
  factory QuestionUpdateService() => _instance;
  QuestionUpdateService._internal();

  final QuestionService _questionService = QuestionService();
  final _storage = JsonStorageService();

  /// 检查是否有题库更新
  Future<bool> hasQuestionUpdate() async {
    try {
      // 检查是否有新的题目数据文件
      final newQuestions = await _loadNewQuestionsFromAssets();
      if (newQuestions.isEmpty) {
        return false;
      }

      // 检查是否有数据库中不存在的题目
      for (final question in newQuestions) {
        final existingQuestion = await _questionService.getQuestionById(question.id);
        if (existingQuestion == null) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('检查题库更新失败: $e');
      return false;
    }
  }

  /// 获取新题目数量
  Future<int> getNewQuestionCount() async {
    try {
      final newQuestions = await _loadNewQuestionsFromAssets();
      
      // 统计数据库中不存在的题目数量
      int count = 0;
      for (final question in newQuestions) {
        final existingQuestion = await _questionService.getQuestionById(question.id);
        if (existingQuestion == null) {
          count++;
        }
      }
      
      return count;
    } catch (e) {
      print('获取新题目数量失败: $e');
      return 0;
    }
  }

  /// 更新题库
  Future<bool> updateQuestionDatabase() async {
    try {
      final newQuestions = await _loadNewQuestionsFromAssets();
      if (newQuestions.isEmpty) {
        print('没有新题目需要更新');
        return false;
      }

      // 过滤出数据库中不存在的题目
      final List<Question> questionsToAdd = [];
      for (final question in newQuestions) {
        final existingQuestion = await _questionService.getQuestionById(question.id);
        if (existingQuestion == null) {
          questionsToAdd.add(question);
        }
      }

      if (questionsToAdd.isEmpty) {
        print('所有题目已存在，无需更新');
        return false;
      }

      // 添加新题目到数据库
      await _questionService.addQuestions(questionsToAdd);

      // 记录更新日志
      await _recordUpdateLog(questionsToAdd.length);

      print('成功更新 ${questionsToAdd.length} 道新题目');
      return true;
    } catch (e) {
      print('更新题库失败: $e');
      rethrow;
    }
  }

  /// 从资源文件加载新题目
  Future<List<Question>> _loadNewQuestionsFromAssets() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/sample_questions.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      final List<Question> questions = jsonList.map((json) {
        // 使用 fromMap 确保新字段能正确解析
        final question = Question.fromMap(json as Map<String, dynamic>);
        // 标记为新题
        return question.copyWith(isNew: true);
      }).toList();

      return questions;
    } catch (e) {
      print('加载题目数据失败: $e');
      return [];
    }
  }

  /// 记录更新日志（使用JSON存储）
  Future<void> _recordUpdateLog(int newQuestionCount) async {
    try {
      final allLogs = await getUpdateLogs();
      int newId = allLogs.isEmpty ? 1 : allLogs.map((l) => l.id).reduce((a, b) => a > b ? a : b) + 1;
      
      final updateLog = QuestionUpdateLog(
        id: newId,
        appName: AppConstants.appName,
        newQuestionCount: newQuestionCount,
        version: AppConstants.appVersion,
        updateTime: DateTime.now(),
        isUpdated: true,
      );

      // 将日志保存到设置中（作为列表）
      final logsKey = 'question_update_logs';
      final logsJson = await _storage.getSetting<String>(logsKey);
      List<Map<String, dynamic>> logsList;
      
      if (logsJson != null) {
        logsList = List<Map<String, dynamic>>.from(jsonDecode(logsJson));
      } else {
        logsList = [];
      }
      
      logsList.add(updateLog.toMap());
      await _storage.updateSetting(logsKey, jsonEncode(logsList));
    } catch (e) {
      print('记录更新日志失败: $e');
    }
  }

  /// 获取更新日志
  Future<List<QuestionUpdateLog>> getUpdateLogs() async {
    try {
      final logsKey = 'question_update_logs';
      final logsJson = await _storage.getSetting<String>(logsKey);
      
      if (logsJson == null) return [];
      
      final logsList = List<Map<String, dynamic>>.from(jsonDecode(logsJson));
      final logs = logsList.map((m) => QuestionUpdateLog.fromMap(m)).toList();
      
      // 按更新时间降序排序
      logs.sort((a, b) => b.updateTime.compareTo(a.updateTime));
      
      return logs;
    } catch (e) {
      print('获取更新日志失败: $e');
      return [];
    }
  }

  /// 标记新题目为已读
  Future<void> markNewQuestionsAsRead() async {
    await _questionService.markNewQuestionsAsRead();
  }

  /// 检查是否需要显示更新提示
  Future<bool> shouldShowUpdatePrompt() async {
    try {
      // 检查是否有未更新的新题目
      final newQuestionCount = await _questionService.getNewQuestionCount();
      return newQuestionCount > 0;
    } catch (e) {
      print('检查更新提示失败: $e');
      return false;
    }
  }

  /// 获取更新提示信息
  Future<String> getUpdatePromptMessage() async {
    final newQuestionCount = await getNewQuestionCount();
    return '发现 $newQuestionCount 道新怀旧题目，是否更新本地题库？更新不消耗流量，仅占用少量存储空间';
  }

  /// 模拟版本更新（用于测试）
  Future<void> simulateVersionUpdate() async {
    try {
      // 创建一些新的测试题目
      final newQuestions = [
        Question(
          id: 100,
          content: '以下哪个是1990年代流行的游戏机？',
          category: '事件',
          difficulty: '简单',
          echoTheme: '90年代事件',
          options: ['任天堂64', 'PlayStation', '世嘉土星', 'Game Boy'],
          correctAnswer: 1,
          explanation: 'PlayStation是1994年索尼推出的游戏机，在90年代非常流行。',
          isNew: true,
          createdAt: DateTime.now(),
        ),
        Question(
          id: 101,
          content: '以下哪部电影是1997年上映的？',
          category: '影视',
          difficulty: '中等',
          echoTheme: '90年代影视',
          options: ['《泰坦尼克号》', '《阿甘正传》', '《肖申克的救赎》', '《狮子王》'],
          correctAnswer: 0,
          explanation: '《泰坦尼克号》是1997年上映的经典爱情电影，获得了11项奥斯卡奖。',
          isNew: true,
          createdAt: DateTime.now(),
        ),
      ];

      // 添加到数据库
      await _questionService.addQuestions(newQuestions);

      // 记录更新日志
      await _recordUpdateLog(newQuestions.length);

      print('模拟版本更新完成，新增 ${newQuestions.length} 道题目');
    } catch (e) {
      print('模拟版本更新失败: $e');
    }
  }

  /// 重置题库（用于测试）
  Future<void> resetQuestionDatabase() async {
    try {
      // 清空所有题目
      final allQuestions = await _questionService.getAllQuestions();
      for (final question in allQuestions) {
        // 这里需要删除题目的方法，暂时跳过
        print('重置题库功能：清空题目（需要实现删除功能）');
      }
      
      // 重新插入初始题目
      await _insertInitialQuestions();
      
      print('题库重置完成');
    } catch (e) {
      print('重置题库失败: $e');
    }
  }

  /// 插入初始题目（使用JSON存储）
  Future<void> _insertInitialQuestions() async {
    final questions = [
      Question(
        id: 1,
        content: '以下哪部电影是1987年上映的经典爱情片？',
        category: '影视',
        difficulty: '简单',
        echoTheme: '80年代影视',
        options: ['《泰坦尼克号》', '《乱世佳人》', '《人鬼情未了》', '《魂断蓝桥》'],
        correctAnswer: 2,
        explanation: '《人鬼情未了》是1987年上映的经典爱情片，由帕特里克·斯威兹和黛米·摩尔主演。',
        isNew: false,
        createdAt: DateTime.now(),
      ),
      Question(
        id: 2,
        content: '以下哪位歌手被称为"摇滚之王"？',
        category: '音乐',
        difficulty: '简单',
        echoTheme: '80年代音乐',
        options: ['迈克尔·杰克逊', '埃尔维斯·普雷斯利', '约翰·列侬', '鲍勃·迪伦'],
        correctAnswer: 1,
        explanation: '埃尔维斯·普雷斯利（猫王）被称为"摇滚之王"，是摇滚乐的开创者之一。',
        isNew: false,
        createdAt: DateTime.now(),
      ),
      Question(
        id: 3,
        content: '1989年发生的重大历史事件是？',
        category: '事件',
        difficulty: '中等',
        echoTheme: '80年代事件',
        options: ['柏林墙倒塌', '苏联解体', '海湾战争', '东欧剧变'],
        correctAnswer: 0,
        explanation: '1989年11月9日，柏林墙倒塌，标志着冷战的结束和东西德统一的开始。',
        isNew: false,
        createdAt: DateTime.now(),
      ),
    ];

    await _questionService.addQuestions(questions);
  }
}
