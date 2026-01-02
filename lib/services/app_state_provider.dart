import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/test_record.dart';
import '../models/echo_achievement.dart';
import '../services/question_service.dart';
import '../services/test_record_service.dart';
import '../services/echo_achievement_service.dart';
import '../services/echo_collection_service.dart';
import '../services/local_storage_service.dart';
import '../services/json_storage_service.dart';
import '../services/question_update_service.dart';
import '../services/font_size_service.dart';
import '../services/theme_service.dart';
import '../services/performance_service.dart';
import '../services/enhanced_achievement_service.dart';
import '../services/intelligent_analytics_service.dart';
import '../services/recommendation_service.dart';
import '../services/memory_capsule_service.dart';
import '../constants/app_constants.dart';

/// 组题模式枚举
enum QuestionSelectionMode {
  random,    // 随机模式（默认）
  balanced,  // 均衡模式
  smart,     // 智能推荐模式
}

/// 应用状态管理
class AppStateProvider extends ChangeNotifier {
  final QuestionService _questionService = QuestionService();
  final TestRecordService _testRecordService = TestRecordService();
  final EchoAchievementService _achievementService = EchoAchievementService();
  final EchoCollectionService _collectionService = EchoCollectionService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final QuestionUpdateService _updateService = QuestionUpdateService();
  final FontSizeService _fontSizeService = FontSizeService();
  final PerformanceService _performanceService = PerformanceService();
  final EnhancedAchievementSystem _enhancedAchievementSystem = EnhancedAchievementSystem();
  final IntelligentAnalyticsService _analyticsService = IntelligentAnalyticsService();
  final IntelligentRecommendationSystem _recommendationSystem = IntelligentRecommendationSystem();

  // 当前状态
  List<Question> _questions = [];
  List<Question> _currentTestQuestions = [];
  int _currentQuestionIndex = 0;
  List<int> _userAnswers = [];
  List<int> _questionTimes = [];
  DateTime? _testStartTime;
  bool _isTestInProgress = false;
  TestRecord? _currentTestRecord;
  List<EchoAchievement> _achievements = [];
  List<Question> _collectedQuestions = [];
  List<TestRecord> _testRecords = [];
  int _newQuestionCount = 0;
  QuestionSelectionMode _questionSelectionMode = QuestionSelectionMode.random; // 组题模式

  // 用户设置
  String _commentStyle = '通用版';
  String _fontSize = '中';
  bool _elderlyMode = false;

  // Getters
  List<Question> get questions => _questions;
  List<Question> get currentTestQuestions => _currentTestQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  List<int> get userAnswers => _userAnswers;
  List<int> get questionTimes => _questionTimes;
  bool get isTestInProgress => _isTestInProgress;
  TestRecord? get currentTestRecord => _currentTestRecord;
  List<EchoAchievement> get achievements => _achievements;
  List<Question> get collectedQuestions => _collectedQuestions;
  List<TestRecord> get testRecords => _testRecords;
  int get newQuestionCount => _newQuestionCount;
  String get commentStyle => _commentStyle;
  String get fontSize => _fontSizeService.currentFontSize;
  bool get elderlyMode => _elderlyMode;

  // 当前题目
  Question? get currentQuestion {
    if (_currentQuestionIndex < _currentTestQuestions.length) {
      return _currentTestQuestions[_currentQuestionIndex];
    }
    return null;
  }

  // 拾光进度
  double get testProgress {
    if (_currentTestQuestions.isEmpty) return 0.0;
    return (_currentQuestionIndex + 1) / _currentTestQuestions.length;
  }

  // 是否最后一题
  bool get isLastQuestion => _currentQuestionIndex >= _currentTestQuestions.length - 1;

  /// 初始化应用
  Future<void> initializeApp() async {
    print('========== 开始应用初始化 ==========');
    try {
      print('1. 初始化本地存储服务...');
      await _localStorageService.initialize();
      print('   本地存储服务初始化完成');
      
      print('2. 初始化主题服务...');
      await ThemeService().initialize();
      print('   主题服务初始化完成');
      
      print('3. 初始化字体大小服务...');
      await _fontSizeService.initialize();
      print('   字体大小服务初始化完成');
      
      print('4. 自动更新题目数据（确保题库最新）...');
      try {
        final hasUpdate = await _updateService.hasQuestionUpdate();
        if (hasUpdate) {
          print('   检测到新题目，开始自动更新...');
          final updateSuccess = await _updateService.updateQuestionDatabase();
          if (updateSuccess) {
            print('   ✅ 题目自动更新成功，已写入磁盘');
          } else {
            print('   ℹ️ 所有题目已是最新版本');
          }
        } else {
          print('   ℹ️ 没有新题目需要更新');
        }
      } catch (e) {
        print('   ⚠️ 自动更新题目失败: $e');
        // 更新失败不影响应用启动，继续执行
      }
      
      print('5. 加载题目数据（从磁盘加载最新题库）...');
      await _loadQuestions();
      print('   题目数据加载完成，共 ${_questions.length} 题');
      
      print('6. 加载成就数据...');
      await _loadAchievements();
      print('   成就数据加载完成，共 ${_achievements.length} 个成就');
      
      print('7. 加载收藏数据...');
      await _loadCollectedQuestions();
      print('   收藏数据加载完成，共 ${_collectedQuestions.length} 题');
      
      print('8. 加载拾光记录...');
      await _loadTestRecords();
      print('   拾光记录加载完成，共 ${_testRecords.length} 条记录');
      
      print('9. 迁移拾光回忆数据到记忆胶囊...');
      try {
        final memoryCapsuleService = MemoryCapsuleService();
        await memoryCapsuleService.initialize();
        final migratedCount = await memoryCapsuleService.migrateFromMemoryRecords();
        if (migratedCount > 0) {
          print('   ✅ 成功迁移 $migratedCount 条拾光回忆到记忆胶囊');
        } else {
          print('   ℹ️ 没有需要迁移的拾光回忆数据');
        }
      } catch (e) {
        print('   ⚠️ 迁移拾光回忆数据失败: $e');
        // 迁移失败不影响应用启动，继续执行
      }
      
      print('10. 加载新题目数量...');
      await _loadNewQuestionCount();
      print('   新题目数量: $_newQuestionCount');
      
      print('11. 加载用户设置...');
      await _loadUserSettings();
      print('   用户设置加载完成');
      print('    - 评语风格: $_commentStyle');
      print('    - 字体大小: $_fontSize');
      print('    - 老年模式: $_elderlyMode');
      
      print('========== 应用初始化完成 ==========');
    } catch (e) {
      print('应用初始化失败: $e');
      print('错误堆栈: ${StackTrace.current}');
      // 即使初始化失败，也要继续运行
    }
  }

  /// 加载题目
  Future<void> _loadQuestions() async {
    try {
      _questions = await _questionService.getAllQuestions();
      print('✅ 成功加载 ${_questions.length} 道题目');
      notifyListeners();
    } catch (e) {
      print('⚠️ 加载题目失败: $e');
      print('⚠️ 使用示例题目...');
      // 使用示例题目，确保应用可以继续运行
      _questions = _getSampleQuestions();
      notifyListeners();
    }
  }

  /// 加载成就
  Future<void> _loadAchievements() async {
    try {
      _achievements = await _achievementService.getAllAchievements();
      final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
      print('✅ 成功加载 ${_achievements.length} 个成就，其中 ${unlockedCount} 个已解锁');
      if (unlockedCount > 0) {
        print('✅ 已解锁的成就列表:');
        for (final achievement in _achievements.where((a) => a.isUnlocked)) {
          print('   - ${achievement.achievementName} (ID: ${achievement.id})');
        }
      }
      notifyListeners();
    } catch (e) {
      print('⚠️ 加载成就失败: $e');
      _achievements = [];
      notifyListeners();
    }
  }

  /// 加载收藏题目
  Future<void> _loadCollectedQuestions() async {
    try {
      print('📚 _loadCollectedQuestions 开始加载...');
      _collectedQuestions = await _collectionService.getCollectedQuestions();
      print('✅ 成功加载 ${_collectedQuestions.length} 个收藏');
      if (_collectedQuestions.isEmpty) {
        print('📚 ⚠️ 收藏列表为空，但可能存在收藏记录');
        // 检查收藏记录数量
        final collectionCount = await _collectionService.getCollectionCount();
        print('📚 收藏记录总数: $collectionCount');
      }
      notifyListeners();
    } catch (e, stackTrace) {
      print('⚠️ 加载收藏失败: $e');
      print('⚠️ 错误堆栈: $stackTrace');
      _collectedQuestions = [];
      notifyListeners();
    }
  }

  /// 加载拾光记录
  Future<void> _loadTestRecords() async {
    try {
      print('📝 _loadTestRecords 开始加载...');
      _testRecords = await _testRecordService.getAllTestRecords();
      // 按时间倒序排序（最新的在前）
      _testRecords.sort((a, b) => b.testTime.compareTo(a.testTime));
      print('✅ 成功加载 ${_testRecords.length} 条拾光记录');
      notifyListeners();
    } catch (e, stackTrace) {
      print('⚠️ 加载拾光记录失败: $e');
      print('⚠️ 错误堆栈: $stackTrace');
      _testRecords = [];
      notifyListeners();
    }
  }

  /// 加载新题目数量
  Future<void> _loadNewQuestionCount() async {
    try {
      _newQuestionCount = await _updateService.getNewQuestionCount();
      print('✅ 新题目数量: $_newQuestionCount');
      notifyListeners();
    } catch (e) {
      print('⚠️ 加载新题目数量失败: $e');
      _newQuestionCount = 0;
      notifyListeners();
    }
  }

  /// 加载用户设置
  Future<void> _loadUserSettings() async {
    print('========== 开始加载用户设置 ==========');
    try {
      print('从本地存储读取设置...');
      final settings = await _localStorageService.getUserSettings();
      
      print('1. 从存储加载设置值');
      _commentStyle = settings['commentStyle'] as String;
      _fontSize = settings['fontSize'] as String;
      _elderlyMode = settings['elderlyMode'] as bool? ?? false;
      
      // 加载组题模式
      final modeStr = settings['questionSelectionMode'] as String? ?? 'random';
      _questionSelectionMode = _parseQuestionSelectionMode(modeStr);
      
      print('   加载结果:');
      print('     commentStyle: $_commentStyle');
      print('     fontSize: $_fontSize');
      print('     elderlyMode: $_elderlyMode');
      print('     questionSelectionMode: $_questionSelectionMode');
      
      print('2. 更新字体大小服务');
      FontSizeService().setFontSize(_fontSize);
      print('   字体大小服务已更新');
      
      print('3. 触发UI更新');
      notifyListeners();
      
      print('========== 用户设置加载完成 ==========');
      print('最终状态:');
      print('  questionSelectionMode=$_questionSelectionMode');
    } catch (e, stackTrace) {
      print('加载用户设置失败: $e');
      print('错误堆栈: $stackTrace');
      
      print('使用默认值...');
      // 设置默认值
      _commentStyle = '通用版';
      _fontSize = '中';
      _elderlyMode = false;
      _questionSelectionMode = QuestionSelectionMode.random;
      notifyListeners();
      print('========== 使用默认设置完成 ==========');
    }
  }
  
  /// 解析组题模式字符串
  QuestionSelectionMode _parseQuestionSelectionMode(String modeStr) {
    switch (modeStr) {
      case 'random':
        return QuestionSelectionMode.random;
      case 'balanced':
        return QuestionSelectionMode.balanced;
      case 'smart':
        return QuestionSelectionMode.smart;
      default:
        return QuestionSelectionMode.random;
    }
  }

  /// 开始拾光
  Future<void> startTest({
    int questionCount = 10,
    QuestionSelectionMode? mode,
  }) async {
    // 使用指定的模式，如果没有指定则使用当前模式
    final selectionMode = mode ?? _questionSelectionMode;
    
    try {
      // 先检查是否有足够的题目
      final allQuestions = await _questionService.getAllQuestions();
      if (allQuestions.isEmpty) {
        throw Exception('题库中没有题目，请检查数据文件');
      }
      
      // 根据组题模式选择题目
      switch (selectionMode) {
        case QuestionSelectionMode.balanced:
          // 均衡分布模式
          _currentTestQuestions = await _questionService.getBalancedQuestions(questionCount);
          print('📊 使用均衡分布模式组题，已选择 ${_currentTestQuestions.length} 道题目');
          break;
          
        case QuestionSelectionMode.smart:
          // 智能推荐模式
          try {
            final testRecords = await _testRecordService.getAllTestRecords();
            _currentTestQuestions = _recommendationSystem.recommendQuestionsByPerformance(
              allQuestions,
              testRecords,
              questionCount,
            );
            print('🧠 使用智能推荐模式组题，已选择 ${_currentTestQuestions.length} 道题目');
          } catch (e) {
            print('智能推荐失败，回退到均衡模式: $e');
            _currentTestQuestions = await _questionService.getBalancedQuestions(questionCount);
          }
          break;
          
        case QuestionSelectionMode.random:
        default:
          // 随机模式（默认）
          _currentTestQuestions = await _questionService.getRandomQuestions(questionCount);
          print('🎲 使用随机模式组题，已选择 ${_currentTestQuestions.length} 道题目');
          break;
      }
      
      // 如果仍然没有题目，使用示例题目
      if (_currentTestQuestions.isEmpty) {
        print('⚠️ 警告：未获取到题目，使用示例题目');
        _currentTestQuestions = _getSampleQuestions().take(questionCount).toList();
        if (_currentTestQuestions.isEmpty) {
          throw Exception('无法获取题目，请检查题库数据');
        }
      }
    } catch (e, stackTrace) {
      print('❌ 开始拾光失败: $e');
      print('❌ 错误堆栈: $stackTrace');
      // 尝试使用示例题目作为最后的后备方案
      try {
        _currentTestQuestions = _getSampleQuestions().take(questionCount).toList();
        if (_currentTestQuestions.isEmpty) {
          throw Exception('无法获取题目，请检查题库数据');
        }
        print('✅ 使用示例题目作为后备方案');
      } catch (fallbackError) {
        print('❌ 后备方案也失败: $fallbackError');
        rethrow; // 重新抛出原始错误
      }
    }
    
    _currentQuestionIndex = 0;
    _userAnswers = List.filled(_currentTestQuestions.length, -1);
    _questionTimes = List.filled(_currentTestQuestions.length, 0);
    _testStartTime = DateTime.now();
    _isTestInProgress = true;
    
    // 保存拾光状态
    await _saveTestState();
    notifyListeners();
  }

  /// 根据过滤条件开始拾光
  Future<void> startTestWithFilters({
    required int questionCount,
    QuestionSelectionMode? mode,
    List<String>? categories,
    List<String>? eras,
    List<String>? difficulties,
  }) async {
    // 清除旧的拾光状态，确保开始全新的拾光
    _currentTestQuestions = [];
    _currentQuestionIndex = 0;
    _userAnswers = [];
    _questionTimes = [];
    _isTestInProgress = false;
    await _localStorageService.clearTestState();
    
    // 使用指定的模式，如果没有指定则使用当前模式
    final selectionMode = mode ?? _questionSelectionMode;
    
    try {
      // 根据组题模式选择题目
      switch (selectionMode) {
        case QuestionSelectionMode.balanced:
          // 均衡分布模式（带过滤）
          _currentTestQuestions = await _questionService.getBalancedQuestionsWithFilters(
            count: questionCount,
            categories: categories,
            eras: eras,
            difficulties: difficulties,
          );
          print('📊 使用均衡分布模式（带过滤）组题，已选择 ${_currentTestQuestions.length} 道题目');
          break;
          
        case QuestionSelectionMode.smart:
          // 智能推荐模式（先过滤，再推荐）
          try {
            final filteredQuestions = await _questionService.getFilteredQuestions(
              categories: categories,
              eras: eras,
              difficulties: difficulties,
            );
            
            if (filteredQuestions.isEmpty) {
              throw Exception('没有符合条件的题目');
            }
            
            final testRecords = await _testRecordService.getAllTestRecords();
            _currentTestQuestions = _recommendationSystem.recommendQuestionsByPerformance(
              filteredQuestions,
              testRecords,
              questionCount,
            );
            print('🧠 使用智能推荐模式（带过滤）组题，已选择 ${_currentTestQuestions.length} 道题目');
          } catch (e) {
            print('智能推荐失败，回退到均衡模式: $e');
            _currentTestQuestions = await _questionService.getBalancedQuestionsWithFilters(
              count: questionCount,
              categories: categories,
              eras: eras,
              difficulties: difficulties,
            );
          }
          break;
          
        case QuestionSelectionMode.random:
        default:
          // 随机模式（带过滤）
          _currentTestQuestions = await _questionService.getRandomQuestionsWithFilters(
            count: questionCount,
            categories: categories,
            eras: eras,
            difficulties: difficulties,
          );
          print('🎲 使用随机模式（带过滤）组题，已选择 ${_currentTestQuestions.length} 道题目');
          break;
      }
    } catch (e, stackTrace) {
      print('❌ 从数据库获取题目失败: $e');
      print('❌ 错误堆栈: $stackTrace');
      // 提供更详细的错误信息
      String errorMessage = '获取题目失败';
      if (e.toString().contains('没有找到') || e.toString().contains('符合条件的题目')) {
        errorMessage = '没有找到符合条件的题目，请调整筛选条件后重试';
      } else if (e.toString().contains('数据库') || e.toString().contains('存储')) {
        errorMessage = '数据加载失败，请检查应用数据文件';
      } else {
        errorMessage = '获取题目失败：${e.toString()}';
      }
      throw Exception(errorMessage);
    }
    
    // 如果仍然没有题目，抛出异常
    if (_currentTestQuestions.isEmpty) {
      throw Exception('没有找到符合条件的题目，请调整筛选条件后重试');
    }
    
    // 验证定制项是否生效
    if (categories != null && categories.isNotEmpty) {
      final actualCategories = _currentTestQuestions.map((q) => q.category).toSet();
      final invalidCategories = actualCategories.where((c) => !categories.contains(c)).toList();
      if (invalidCategories.isNotEmpty) {
        print('⚠️ 警告：发现了不符合分类要求的题目：$invalidCategories');
        print('   期望的分类：$categories');
        print('   实际的分类：$actualCategories');
      } else {
        print('✅ 分类过滤生效：所有题目都属于选定的分类 $categories');
      }
    }
    
    if (eras != null && eras.isNotEmpty) {
      final actualEras = _currentTestQuestions.map((q) {
        if (q.echoTheme.contains('80年代')) return '80年代';
        if (q.echoTheme.contains('90年代')) return '90年代';
        if (q.echoTheme.contains('00年代')) return '00年代';
        return '';
      }).where((e) => e.isNotEmpty).toSet();
      final invalidEras = actualEras.where((e) => !eras.contains(e)).toList();
      if (invalidEras.isNotEmpty) {
        print('⚠️ 警告：发现了不符合年代要求的题目：$invalidEras');
        print('   期望的年代：$eras');
        print('   实际的年代：$actualEras');
      } else {
        print('✅ 年代过滤生效：所有题目都属于选定的年代 $eras');
      }
    }
    
    if (difficulties != null && difficulties.isNotEmpty) {
      final actualDifficulties = _currentTestQuestions.map((q) => q.difficulty).toSet();
      final invalidDifficulties = actualDifficulties.where((d) => !difficulties.contains(d)).toList();
      if (invalidDifficulties.isNotEmpty) {
        print('⚠️ 警告：发现了不符合难度要求的题目：$invalidDifficulties');
        print('   期望的难度：$difficulties');
        print('   实际的难度：$actualDifficulties');
      } else {
        print('✅ 难度过滤生效：所有题目都属于选定的难度 $difficulties');
      }
    }
    
    // 如果题目数量少于请求的数量，给用户提示
    if (_currentTestQuestions.length < questionCount) {
      print('⚠️ 警告：请求 $questionCount 道题目，但只找到 ${_currentTestQuestions.length} 道符合条件的题目');
      // 注意：这里不抛出异常，而是继续使用找到的题目，但会在控制台打印警告
    }
    
    _currentQuestionIndex = 0;
    _userAnswers = List.filled(_currentTestQuestions.length, -1);
    _questionTimes = List.filled(_currentTestQuestions.length, 0);
    _testStartTime = DateTime.now();
    _isTestInProgress = true;
    
    // 保存拾光状态
    await _saveTestState();
    notifyListeners();
  }
  
  /// 获取当前组题模式
  QuestionSelectionMode get questionSelectionMode => _questionSelectionMode;
  
  /// 设置组题模式
  Future<void> setQuestionSelectionMode(QuestionSelectionMode mode) async {
    _questionSelectionMode = mode;
    
    // 保存到本地存储
    try {
      final modeStr = mode.toString().split('.').last; // 'QuestionSelectionMode.random' -> 'random'
      await _localStorageService.saveUserSettings(questionSelectionMode: modeStr);
      print('✅ 组题模式已设置为: $mode 并保存到本地存储');
    } catch (e) {
      print('⚠️ 保存组题模式失败: $e');
    }
    
    notifyListeners();
  }
  
  /// 获取示例题目（当数据库失败时使用）
  List<Question> _getSampleQuestions() {
    return [
      Question(
        id: 1,
        content: '1987年上映的经典电影《红高粱》》的导演是谁？',
        category: '影视',
        difficulty: '中',
        echoTheme: '80年代影视',
        options: ['张艺谋', '陈凯歌', '冯小刚', '姜文'],
        correctAnswer: 0,
        explanation: '《红高粱》是张艺谋的导演处女作，也是中国第五代导演的代表作之一。',
        isNew: false,
        createdAt: DateTime.now(),
      ),
      Question(
        id: 2,
        content: '1990年北京亚运会的主题曲是什么？',
        category: '音乐',
        difficulty: '中',
        echoTheme: '90年代音乐',
        options: ['《亚洲雄风》', '《北京欢迎你》', '《我和你》', '《歌唱祖国》'],
        correctAnswer: 0,
        explanation: '《亚洲雄风》是1990年北京亚运会的主题曲，由韦唯和刘欢演唱。',
        isNew: false,
        createdAt: DateTime.now(),
      ),
      Question(
        id: 3,
        content: '1990年代最流行的通讯工具是什么？',
        category: '科技',
        difficulty: '中',
        echoTheme: '90年代科技',
        options: ['BB机', '大哥大', '小灵通', '智能手机'],
        correctAnswer: 0,
        explanation: 'BB机（寻呼机）在1990年代非常流行，是人们日常通讯的重要工具。',
        isNew: false,
        createdAt: DateTime.now(),
      ),
      Question(
        id: 4,
        content: '1980年代最经典的游戏机是什么？',
        category: '游戏',
        difficulty: '中',
        echoTheme: '80年代游戏',
        options: ['红白机', 'PlayStation', 'Xbox', 'Game Boy'],
        correctAnswer: 0,
        explanation: '红白机（FC/NES）是1980年代最经典的游戏机之一，陪伴了一代人的童年。',
        isNew: false,
        createdAt: DateTime.now(),
      ),
      Question(
        id: 5,
        content: '1990年代最流行的音乐播放设备是什么？',
        category: '科技',
        difficulty: '中',
        echoTheme: '90年代科技',
        options: ['Walkman随身听', 'MP3播放器', 'CD播放器', '手机'],
        correctAnswer: 0,
        explanation: '索尼的Walkman随身听在1990年代风靡全球，是人们听音乐的主要设备。',
        isNew: false,
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// 回答题目
  void answerQuestion(int answerIndex) {
    if (_currentQuestionIndex < _userAnswers.length) {
      _userAnswers[_currentQuestionIndex] = answerIndex;
      _saveTestState(); // 异步保存拾光状态，不等待完成
      notifyListeners();
    }
  }

  /// 下一题
  void nextQuestion() {
    if (_currentQuestionIndex < _currentTestQuestions.length - 1) {
      _currentQuestionIndex++;
      _saveTestState(); // 异步保存拾光状态，不等待完成
      notifyListeners();
    }
  }

  /// 上一题
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      _saveTestState(); // 异步保存拾光状态，不等待完成
      notifyListeners();
    }
  }

  /// 完成拾光
  Future<TestRecord> completeTest() async {
    print('🎯 开始完成拾光流程...');
    if (!_isTestInProgress || _testStartTime == null) {
      throw Exception('拾光未开始');
    }

    print('🎯 计算拾光结果...');
    final totalTime = DateTime.now().difference(_testStartTime!).inSeconds;
    final correctAnswers = _calculateCorrectAnswers();
    // 计算准确率（百分比格式，0-100）
    final accuracy = ((correctAnswers / _currentTestQuestions.length) * 100).clamp(0.0, 100.0);
    
    // 计算各分类得分
    final categoryScores = _calculateCategoryScores();
    
    // 计算拾光年龄（根据各年代题目的答对情况）
    final echoAge = _testRecordService.calculateEchoAge(
      questions: _currentTestQuestions,
      userAnswers: _userAnswers,
    );

    // 生成评语
    final comment = _generateComment(accuracy);

    // 创建拾光记录
    final testRecord = TestRecord(
      id: 0, // 数据库会自动分配ID
      totalQuestions: _currentTestQuestions.length,
      correctAnswers: correctAnswers,
      accuracy: accuracy,
      totalTime: totalTime,
      echoAge: echoAge,
      comment: comment,
      testTime: DateTime.now(),
      categoryScores: categoryScores,
    );

    print('🎯 ========== 保存拾光记录 ==========');
    print('🎯 📝 拾光记录信息:');
    print('   - 初始ID: ${testRecord.id}');
    print('   - 总题目数: ${testRecord.totalQuestions}');
    print('   - 正确答案数: ${testRecord.correctAnswers}');
    print('   - 正确率: ${testRecord.accuracy}%');
    
    // 保存拾光记录
    try {
      print('🎯 💾 调用 TestRecordService.addTestRecord()...');
      final recordId = await _testRecordService.addTestRecord(testRecord);
      print('🎯 ✅ 拾光记录已保存');
      print('🎯 📊 返回的记录ID: $recordId');
      print('🎯 🔍 记录ID验证: ${recordId > 0 ? "有效" : "可能无效"}');
      
      final updatedTestRecord = TestRecord(
        id: recordId,
        totalQuestions: testRecord.totalQuestions,
        correctAnswers: testRecord.correctAnswers,
        accuracy: testRecord.accuracy,
        totalTime: testRecord.totalTime,
        echoAge: testRecord.echoAge,
        comment: testRecord.comment,
        testTime: testRecord.testTime,
        categoryScores: testRecord.categoryScores,
      );
      
      print('🎯 📋 构建更新后的拾光记录对象');
      print('🎯 📊 更新后记录ID: ${updatedTestRecord.id}');

      // 等待一小段时间确保数据库写入完成（特别是鸿蒙平台）
      print('🎯 ⏳ 等待数据库写入完成...');
      await Future.delayed(const Duration(milliseconds: 100));

      print('🎯 ========== 开始检查成就 ==========');
      print('🎯 🎮 传入的参数:');
      print('   - 拾光记录ID: ${updatedTestRecord.id}');
      print('   - 题目数量: ${_currentTestQuestions?.length ?? 0}');
      print('   - 答案数量: ${_userAnswers?.length ?? 0}');
      
      // 检查并解锁成就（传入题目和答案用于检查困难题成就）
      final newAchievements = await _achievementService.checkAndUnlockAchievements(
        updatedTestRecord, // 使用已保存的记录（包含ID）
        questions: _currentTestQuestions,
        userAnswers: _userAnswers,
      );
      
      print('🎯 ========== 成就检查完成 ==========');
      print('🎯 📊 新解锁成就数量: ${newAchievements.length}');
      if (newAchievements.isNotEmpty) {
        print('🎯 🏆 新解锁的成就列表:');
        for (final achievement in newAchievements) {
          print('   - ${achievement.achievementName} (ID: ${achievement.id})');
        }
      } else {
        print('🎯 ℹ️ 本次没有解锁新成就');
      }
      
      print('🎯 清除拾光状态...');
      // 清除保存的拾光状态
      await _localStorageService.clearTestState();
      
      // 更新状态
      _currentTestRecord = updatedTestRecord;
      _isTestInProgress = false;
      
      print('🎯 重新加载成就数据...');
      // 等待一小段时间确保数据库更新已提交（特别是在 HarmonyOS 平台）
      await Future.delayed(const Duration(milliseconds: 100));
      await _loadAchievements(); // 重新加载成就
      
      // 再次验证成就数据
      final finalUnlockedCount = _achievements.where((a) => a.isUnlocked).length;
      print('🎯 ✅ 成就数据重新加载完成，当前已解锁: $finalUnlockedCount 个');
      
      print('🎯 重新加载拾光记录...');
      await _loadTestRecords(); // 重新加载拾光记录，确保首页显示最新记录
      print('🎯 ✅ 拾光记录重新加载完成，当前共 ${_testRecords.length} 条记录');
      
      notifyListeners();
      print('🎯 ✅ 拾光完成流程全部完成');
      return updatedTestRecord;
    } catch (e, stackTrace) {
      print('🎯 ❌ 完成拾光时出错: $e');
      print('🎯 ❌ 错误堆栈: $stackTrace');
      // 即使保存失败，也更新状态，避免拾光无法完成
      _isTestInProgress = false;
      notifyListeners();
      rethrow; // 重新抛出错误，让调用者知道
    }
  }

  /// 计算正确答案数量
  int _calculateCorrectAnswers() {
    int correct = 0;
    for (int i = 0; i < _currentTestQuestions.length; i++) {
      if (_userAnswers[i] == _currentTestQuestions[i].correctAnswer) {
        correct++;
      }
    }
    return correct;
  }

  /// 计算各分类得分
  /// 返回每个分类的题目数量（不是百分比）
  Map<String, int> _calculateCategoryScores() {
    final Map<String, int> categoryScores = {};
    
    for (int i = 0; i < _currentTestQuestions.length; i++) {
      final question = _currentTestQuestions[i];
      final category = question.category;
      // 统计每个分类的题目数量
      categoryScores[category] = (categoryScores[category] ?? 0) + 1;
    }
    
    return categoryScores;
  }

  /// 生成评语
  String _generateComment(double accuracy) {
    String level;
    if (accuracy >= 90) {
      level = 'excellent';
    } else if (accuracy >= 80) {
      level = 'good';
    } else if (accuracy >= 60) {
      level = 'average';
    } else {
      level = 'poor';
    }
    
    if (_commentStyle == '老年友好版') {
      return AppConstants.elderlyFriendlyComments[level] ?? '';
    } else {
      return AppConstants.generalComments[level] ?? '';
    }
  }

  /// 收藏题目
  Future<void> toggleCollection(int questionId) async {
    print('⭐ [AppState] toggleCollection 开始，questionId=$questionId');
    
    final isCollected = await _collectionService.isCollected(questionId);
    print('⭐ [AppState] 当前收藏状态: $isCollected');
    
    if (isCollected) {
      print('⭐ [AppState] 取消收藏 questionId=$questionId');
      await _collectionService.removeCollection(questionId);
    } else {
      print('⭐ [AppState] 添加收藏 questionId=$questionId');
      await _collectionService.addCollection(questionId);
    }
    
    // 验证收藏操作是否成功
    final verifyStatus = await _collectionService.isCollected(questionId);
    print('⭐ [AppState] 操作后验证状态: $verifyStatus (期望: ${!isCollected})');
    
    // 重新加载收藏列表
    print('⭐ [AppState] 重新加载收藏列表...');
    await _loadCollectedQuestions();
    
    // 检查收藏家成就
    final collectionCount = await _collectionService.getCollectionCount();
    print('⭐ [AppState] 当前收藏总数: $collectionCount');
    await _achievementService.checkCollectorAchievement(collectionCount);
    await _loadAchievements();
    
    print('⭐ [AppState] toggleCollection 完成');
  }

  /// 检查是否已收藏
  Future<bool> isQuestionCollected(int questionId) async {
    return await _collectionService.isCollected(questionId);
  }

  /// 刷新收藏数据（供外部调用）
  Future<void> refreshCollections() async {
    await _loadCollectedQuestions();
  }

  /// 诊断收藏数据完整性（供外部调用）
  Future<Map<String, dynamic>> diagnoseCollectionData() async {
    return await _collectionService.diagnoseCollectionData();
  }

  /// 更新评语风格
  Future<void> updateCommentStyle(String style) async {
    print('========== 更新评语风格 ==========');
    print('当前风格: $_commentStyle');
    print('新风格: $style');
    
    _commentStyle = style;
    
    print('保存到本地存储...');
    await _localStorageService.saveUserSettings(commentStyle: style);
    print('评语风格已保存');
    
    notifyListeners();
    print('========== 评语风格更新完成 ==========');
  }

  /// 更新老年友好模式
  Future<void> updateElderlyMode(bool enabled) async {
    print('========== 更新老年友好模式 ==========');
    print('当前状态: elderlyMode=$_elderlyMode, fontSize=$_fontSize, commentStyle=$_commentStyle');
    print('新状态: elderlyMode=$enabled');
    
    _elderlyMode = enabled;
    
    if (enabled) {
      print('开启老年友好模式');
      // 开启老年友好模式：字体特大 + 评语风格改为老年友好版
      _fontSize = '特大';
      if (_commentStyle == '通用版') {
        _commentStyle = '老年友好版';
      }
      print('  更新字体大小: $_fontSize');
      print('  更新评语风格: $_commentStyle');
    } else {
      print('关闭老年友好模式');
      // 关闭老年友好模式：字体改回中 + 评语风格改回通用版
      _fontSize = '中';
      if (_commentStyle == '老年友好版') {
        _commentStyle = '通用版';
      }
      print('  更新字体大小: $_fontSize');
      print('  更新评语风格: $_commentStyle');
    }
    
    print('更新字体大小服务...');
    FontSizeService().setFontSize(_fontSize);
    print('字体大小服务已更新');
    
    print('保存到本地存储...');
    await _localStorageService.saveUserSettings(
      elderlyMode: enabled,
      fontSize: _fontSize,
      commentStyle: _commentStyle,
    );
    print('保存完成');
    
    notifyListeners();
    print('========== 老年友好模式更新完成 ==========');
  }

  /// 重置拾光
  void resetTest() {
    _currentTestQuestions = [];
    _currentQuestionIndex = 0;
    _userAnswers = [];
    _questionTimes = [];
    _testStartTime = null;
    _isTestInProgress = false;
    _currentTestRecord = null;
    notifyListeners();
  }

  /// 获取已解锁成就数量
  int get unlockedAchievementCount {
    return _achievements.where((a) => a.isUnlocked).length;
  }

  /// 获取总成就数量
  int get totalAchievementCount {
    return _achievements.length;
  }

  /// 更新字体大小
  Future<void> updateFontSize(String fontSize) async {
    print('========== 更新字体大小 ==========');
    print('当前大小: $_fontSize');
    print('新大小: $fontSize');
    
    _fontSize = fontSize;
    
    print('更新字体大小服务...');
    await _fontSizeService.updateFontSize(fontSize);
    print('字体大小服务已更新');
    
    print('保存到本地存储...');
    await _localStorageService.saveUserSettings(fontSize: fontSize);
    print('保存完成');
    
    notifyListeners();
    print('========== 字体大小更新完成 ==========');
  }

  /// 更新题库
  Future<bool> updateQuestionDatabase() async {
    try {
      final success = await _updateService.updateQuestionDatabase();
      if (success) {
        await _loadQuestions();
        await _loadNewQuestionCount();
      }
      return success;
    } catch (e) {
      print('更新题库失败: $e');
      return false;
    }
  }

  /// 检查是否有题库更新
  Future<bool> hasQuestionUpdate() async {
    return await _updateService.hasQuestionUpdate();
  }

  /// 获取更新提示信息
  Future<String> getUpdatePromptMessage() async {
    return await _updateService.getUpdatePromptMessage();
  }

  /// 获取最近的拾光记录
  Future<List<TestRecord>> getRecentTestRecords(int limit) async {
    return await _testRecordService.getRecentTestRecords(limit);
  }

  /// 标记新题目为已读
  Future<void> markNewQuestionsAsRead() async {
    await _updateService.markNewQuestionsAsRead();
    await _loadNewQuestionCount();
  }

  /// 清除所有数据
  Future<void> clearAllData() async {
    try {
      print('🗑️ 开始清除所有数据...');
      
      // 先清除所有文件（包括记忆胶囊和故事）
      print('🗑️ 清除所有数据文件（包括记忆胶囊和故事）...');
      await JsonStorageService().clearAllData();
      
      // 清除拾光记录（确保内存中的数据也被清除）
      print('🗑️ 清除拾光记录...');
      await _testRecordService.clearAllRecords();
      
      // 清除收藏
      print('🗑️ 清除收藏...');
      await _collectionService.clearAllCollections();
      
      // 重置成就
      print('🗑️ 重置成就...');
      await _achievementService.resetAllAchievements();
      
      // 清除本地存储（包括拾光状态）
      print('🗑️ 清除本地存储...');
      await _localStorageService.clear();
      
      // 清空内存中的数据列表
      print('🗑️ 清空内存数据...');
      _achievements = [];
      _collectedQuestions = [];
      _testRecords = []; // 清空拾光记录列表
      _newQuestionCount = 0; // 重置新题目数量
      
      // 重置拾光状态
      _currentTestQuestions = [];
      _currentQuestionIndex = 0;
      _userAnswers = [];
      _questionTimes = [];
      _testStartTime = null;
      _isTestInProgress = false;
      _currentTestRecord = null;
      
      // 重新加载数据（确保数据同步）
      print('🗑️ 重新加载数据...');
      await _loadQuestions();
      await _loadAchievements();
      await _loadCollectedQuestions();
      await _loadTestRecords(); // 重新加载拾光记录（应该是空的）
      await _loadNewQuestionCount(); // 重新加载新题目数量
      await _loadUserSettings();
      
      print('🗑️ ✅ 所有数据清除完成');
      
      // 强制通知所有监听者
      notifyListeners();
    } catch (e, stackTrace) {
      print('🗑️ ❌ 清除数据失败: $e');
      print('🗑️ ❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 保存拾光状态
  Future<void> _saveTestState() async {
    if (!_isTestInProgress) return;
    
    try {
      final state = {
        'currentQuestionIndex': _currentQuestionIndex,
        'userAnswers': _userAnswers,
        'questionTimes': _questionTimes,
        'testStartTime': _testStartTime?.toIso8601String(),
        'questionIds': _currentTestQuestions.map((q) => q.id).toList(),
      };
      await _localStorageService.saveTestState(state);
    } catch (e) {
      print('保存拾光状态失败: $e');
    }
  }

  /// 恢复拾光状态
  Future<bool> restoreTestState() async {
    try {
      final state = await _localStorageService.getTestState();
      if (state == null) return false;
      
      final questionIds = (state['questionIds'] as List).cast<int>();
      if (questionIds.isEmpty) return false;
      
      // 通过ID获取题目
      _currentTestQuestions = await _questionService.getQuestionsByIds(questionIds);
      if (_currentTestQuestions.isEmpty) {
        print('未找到题目，清除拾光状态');
        await _localStorageService.clearTestState();
        return false;
      }
      
      _currentQuestionIndex = state['currentQuestionIndex'] as int;
      _userAnswers = (state['userAnswers'] as List).cast<int>();
      _questionTimes = (state['questionTimes'] as List).cast<int>();
      
      // 尝试解析日期，如果有错误则使用当前时间
      final startTimeStr = state['testStartTime'] as String?;
      if (startTimeStr != null) {
        try {
          _testStartTime = DateTime.parse(startTimeStr);
        } catch (e) {
          print('解析拾光开始时间失败: $e，使用当前时间');
          _testStartTime = DateTime.now();
        }
      }
      
      _isTestInProgress = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('恢复拾光状态失败: $e');
      // 清除损坏的状态
      await _localStorageService.clearTestState();
      return false;
    }
  }

  /// 检查是否有未完成的拾光
  Future<bool> hasIncompleteTest() async {
    try {
      final state = await _localStorageService.getTestState();
      if (state == null) return false;
      
      final questionIds = (state['questionIds'] as List).cast<int>();
      final currentIndex = state['currentQuestionIndex'] as int;
      
      // 检查是否完成了所有题目
      return questionIds.isNotEmpty && currentIndex < questionIds.length;
    } catch (e) {
      print('检查未完成拾光失败: $e');
      return false;
    }
  }

  /// 获取未完成拾光进度
  Future<Map<String, dynamic>?> getIncompleteTestProgress() async {
    try {
      final state = await _localStorageService.getTestState();
      if (state == null) return null;
      
      final questionIds = (state['questionIds'] as List).cast<int>();
      final currentIndex = state['currentQuestionIndex'] as int;
      
      return {
        'totalQuestions': questionIds.length,
        'currentIndex': currentIndex,
        'progress': questionIds.isNotEmpty ? (currentIndex + 1) / questionIds.length : 0.0,
      };
    } catch (e) {
      print('获取拾光进度失败: $e');
      return null;
    }
  }
}
