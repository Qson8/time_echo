import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/test_record.dart';
import '../models/echo_collection.dart';
import '../models/echo_achievement.dart';
import '../models/memory_record.dart';
import '../models/nostalgic_story.dart';

/// JSON文件存储服务类（统一的数据持久化方案）
class JsonStorageService {
  static final JsonStorageService _instance = JsonStorageService._internal();
  factory JsonStorageService() => _instance;
  JsonStorageService._internal();

  Directory? _storageDirectory;
  bool _initialized = false;

  /// 数据文件路径
  static const String _questionsFile = 'questions.json';
  static const String _testRecordsFile = 'test_records.json';
  static const String _collectionsFile = 'collections.json';
  static const String _achievementsFile = 'achievements.json';
  static const String _settingsFile = 'settings.json';
  static const String _questionUpdateLogFile = 'question_update_log.json';
  static const String _memoriesFile = 'memories.json';
  static const String _storiesFile = 'stories.json';

  /// 初始化存储服务（支持鸿蒙平台）
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('📁 初始化JSON存储服务...');
      
      // 获取存储目录（多层降级策略，确保鸿蒙平台兼容）
      Directory? directory;
      
      // 策略1：应用支持目录（首选）
      if (!kIsWeb) {
        try {
          directory = await getApplicationSupportDirectory();
          print('✅ 使用应用支持目录: ${directory.path}');
        } catch (e) {
          print('⚠️ 获取应用支持目录失败（可能是不支持的平台如鸿蒙）: $e');
        }
      }

      // 策略2：应用文档目录（备用）
      if (directory == null && !kIsWeb) {
        try {
          directory = await getApplicationDocumentsDirectory();
          print('✅ 使用应用文档目录: ${directory.path}');
        } catch (e) {
          // HarmonyOS 平台可能不支持 path_provider，静默失败，继续尝试其他方案
          print('⚠️ 获取应用文档目录失败（可能是不支持的平台）: $e');
        }
      }

      // 策略3：应用缓存目录（鸿蒙平台备用）
      if (directory == null && !kIsWeb) {
        try {
          directory = await getTemporaryDirectory();
          final appDataDir = Directory(join(directory.path, 'time_echo_data'));
          if (!await appDataDir.exists()) {
            await appDataDir.create(recursive: true);
          }
          directory = appDataDir;
          print('✅ 使用临时目录: ${directory.path}');
        } catch (e) {
          // HarmonyOS 平台可能不支持 path_provider，静默失败，继续尝试系统临时目录
          print('⚠️ 获取临时目录失败（可能是不支持的平台）: $e');
        }
      }

      // 策略4：系统临时目录（最后的降级方案，适用于所有平台包括鸿蒙）
      if (directory == null) {
        try {
          final tempDir = Directory.systemTemp;
          final appDataDir = Directory(join(tempDir.path, 'time_echo_data'));
          if (!await appDataDir.exists()) {
            await appDataDir.create(recursive: true);
          }
          directory = appDataDir;
          print('✅ 使用系统临时目录: ${directory.path}');
        } catch (e) {
          print('⚠️ 系统临时目录也失败: $e');
        }
      }

      // 如果所有策略都失败，抛出异常
      if (directory == null) {
        throw Exception('无法获取任何可用的存储目录，JSON存储服务无法初始化');
      }

      _storageDirectory = directory;
      print('✅ JSON存储目录确定: ${_storageDirectory!.path}');

      // 确保目录存在
      if (!await _storageDirectory!.exists()) {
        await _storageDirectory!.create(recursive: true);
        print('✅ 存储目录已创建');
      }

      // 初始化默认数据
      await _initializeDefaultData();

      _initialized = true;
      print('✅ JSON存储服务初始化完成（适用于所有平台包括鸿蒙）');
    } catch (e, stackTrace) {
      print('❌ JSON存储服务初始化失败: $e');
      print('❌ 错误堆栈: $stackTrace');
      // 尝试最后降级：使用内存存储（数据不会持久化，但不影响应用启动）
      print('⚠️ 警告：JSON存储初始化失败，应用将继续运行但数据可能不会持久化');
      // 不抛出异常，允许应用继续运行
      _initialized = true; // 标记为已初始化，避免重复尝试
    }
  }

  /// 获取文件路径
  String _getFilePath(String fileName) {
    if (_storageDirectory == null) {
      throw Exception('存储服务未初始化');
    }
    return join(_storageDirectory!.path, fileName);
  }

  /// 读取JSON文件（公共方法，用于自定义文件）
  Future<dynamic> readJsonFile(String fileName) async {
    await _ensureInitialized();
    try {
      final file = File(_getFilePath(fileName));
      if (!await file.exists()) {
        return null;
      }
      final content = await file.readAsString();
      if (content.isEmpty) {
        return null;
      }
      return jsonDecode(content);
    } catch (e) {
      print('⚠️ 读取JSON文件失败 $fileName: $e');
      return null;
    }
  }

  /// 写入JSON文件（公共方法，用于自定义文件）
  Future<void> writeJsonFile(String fileName, dynamic data) async {
    await _ensureInitialized();
    try {
      final filePath = _getFilePath(fileName);
      final file = File(filePath);
      print('📁 [JsonStorage] 写入文件: $fileName');
      print('📁 [JsonStorage] 文件路径: $filePath');
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString);
      
      // 验证文件是否确实存在
      if (await file.exists()) {
        final fileSize = await file.length();
        print('📁 [JsonStorage] ✅ 文件写入成功，文件大小: $fileSize 字节');
      } else {
        print('📁 [JsonStorage] ⚠️ 警告：文件写入后不存在');
      }
    } catch (e, stackTrace) {
      print('❌ 写入JSON文件失败 $fileName: $e');
      print('❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 读取JSON文件（私有方法，内部使用）
  Future<Map<String, dynamic>> _readJsonFile(String fileName) async {
    try {
      final file = File(_getFilePath(fileName));
      if (!await file.exists()) {
        return {};
      }
      final content = await file.readAsString();
      if (content.isEmpty) {
        return {};
      }
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      print('⚠️ 读取JSON文件失败 $fileName: $e');
      return {};
    }
  }

  /// 写入JSON文件
  Future<void> _writeJsonFile(String fileName, Map<String, dynamic> data) async {
    try {
      final filePath = _getFilePath(fileName);
      final file = File(filePath);
      print('📁 [JsonStorage] 写入文件: $fileName');
      print('📁 [JsonStorage] 文件路径: $filePath');
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString);
      
      // 验证文件是否确实存在并可以读取
      if (await file.exists()) {
        final fileSize = await file.length();
        print('📁 [JsonStorage] ✅ 文件写入成功，文件大小: $fileSize 字节');
        
          // 尝试读取验证
          try {
            final verifyContent = await file.readAsString();
            final verifyData = jsonDecode(verifyContent) as Map<String, dynamic>;
            if (fileName == _collectionsFile) {
              final collectionsCount = (verifyData['collections'] as List?)?.length ?? 0;
              print('📁 [JsonStorage] ✅ 验证读取：文件包含 $collectionsCount 条收藏记录');
            }
        } catch (e) {
          print('📁 [JsonStorage] ⚠️ 验证读取失败: $e');
        }
      } else {
        print('📁 [JsonStorage] ⚠️ 警告：文件写入后不存在');
      }
    } catch (e, stackTrace) {
      print('❌ 写入JSON文件失败 $fileName: $e');
      print('❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 初始化默认数据
  Future<void> _initializeDefaultData() async {
    // 初始化成就数据（如果不存在）
    final achievementsData = await _readJsonFile(_achievementsFile);
    if (achievementsData.isEmpty || achievementsData['achievements'] == null) {
      await _initializeDefaultAchievements();
    }
    
    // 初始化故事数据（如果不存在）
    final storiesData = await _readJsonFile(_storiesFile);
    final storiesList = storiesData['stories'] as List? ?? [];
    if (storiesList.isEmpty) {
      await _initializeDefaultStories();
    }
  }

  /// 初始化默认成就
  Future<void> _initializeDefaultAchievements() async {
    final achievements = [
      {
        'id': 1,
        'achievement_name': '拾光初遇',
        'achievement_icon': 'icons/echo_badge_first.png',
        'reward': '解锁「拾光初遇」称号',
        'condition': '完成首次拾光',
        'is_unlocked': false,
        'unlocked_at': '',
      },
      {
        'id': 2,
        'achievement_name': '影视拾光者',
        'achievement_icon': 'icons/echo_badge_movie.png',
        'reward': '解锁「影视拾光者」称号',
        'condition': '影视分类题库正确率≥90%',
        'is_unlocked': false,
        'unlocked_at': '',
      },
      {
        'id': 3,
        'achievement_name': '音乐回响者',
        'achievement_icon': 'icons/echo_badge_music.png',
        'reward': '解锁「音乐回响者」称号',
        'condition': '音乐分类题库正确率≥90%',
        'is_unlocked': false,
        'unlocked_at': '',
      },
      {
        'id': 4,
        'achievement_name': '时代见证者',
        'achievement_icon': 'icons/echo_badge_event.png',
        'reward': '解锁「时代见证者」称号',
        'condition': '事件分类题库正确率≥90%',
        'is_unlocked': false,
        'unlocked_at': '',
      },
      {
        'id': 5,
        'achievement_name': '拾光速答手',
        'achievement_icon': 'icons/echo_badge_speed.png',
        'reward': '解锁「拾光速答手」称号',
        'condition': '单题平均耗时≤15秒',
        'is_unlocked': false,
        'unlocked_at': '',
      },
      {
        'id': 6,
        'achievement_name': '拾光挑战者',
        'achievement_icon': 'icons/echo_badge_challenge.png',
        'reward': '解锁「拾光挑战者」称号',
        'condition': '困难题正确率100%',
        'is_unlocked': false,
        'unlocked_at': '',
      },
      {
        'id': 7,
        'achievement_name': '拾光收藏家',
        'achievement_icon': 'icons/echo_badge_collector.png',
        'reward': '解锁「拾光收藏家」称号',
        'condition': '收藏题目≥20道',
        'is_unlocked': false,
        'unlocked_at': '',
      },
      {
        'id': 8,
        'achievement_name': '拾光全勤人',
        'achievement_icon': 'icons/echo_badge_attendance.png',
        'reward': '解锁「拾光全勤人」称号',
        'condition': '连续7天每天拾光',
        'is_unlocked': false,
        'unlocked_at': '',
      },
      {
        'id': 9,
        'achievement_name': '80年代专家',
        'achievement_icon': 'icons/echo_badge_80s.png',
        'reward': '解锁「80年代专家」称号',
        'condition': '单次拾光中80年代题目正确率≥90%',
        'is_unlocked': false,
        'unlocked_at': '',
      },
      {
        'id': 10,
        'achievement_name': '90年代专家',
        'achievement_icon': 'icons/echo_badge_90s.png',
        'reward': '解锁「90年代专家」称号',
        'condition': '单次拾光中90年代题目正确率≥90%',
        'is_unlocked': false,
        'unlocked_at': '',
      },
      {
        'id': 11,
        'achievement_name': '00年代专家',
        'achievement_icon': 'icons/echo_badge_00s.png',
        'reward': '解锁「00年代专家」称号',
        'condition': '单次拾光中00年代题目正确率≥90%',
        'is_unlocked': false,
        'unlocked_at': '',
      },
    ];

    await _writeJsonFile(_achievementsFile, {
      'achievements': achievements,
      'last_updated': DateTime.now().toIso8601String(),
    });
    print('✅ 默认成就数据初始化完成');
  }

  /// 初始化默认故事
  Future<void> _initializeDefaultStories() async {
    try {
      print('📖 开始初始化默认故事数据...');
      
      // 从 assets 加载模板文件
      final String jsonString = await rootBundle.loadString('assets/data/stories_template.json');
      final Map<String, dynamic> templateData = json.decode(jsonString);
      final List<dynamic> storiesList = templateData['stories'] ?? [];
      
      print('📖 从模板文件加载了 ${storiesList.length} 个故事');
      
      // 验证并转换故事数据
      final List<Map<String, dynamic>> validStories = [];
      for (final storyData in storiesList) {
        try {
          // 确保数据格式正确
          final story = NostalgicStory.fromMap(storyData as Map<String, dynamic>);
          validStories.add(story.toMap());
        } catch (e) {
          print('📖 ⚠️ 跳过无效故事数据: $e');
        }
      }
      
      // 保存故事数据
      await _writeJsonFile(_storiesFile, {
        'stories': validStories,
        'last_updated': DateTime.now().toIso8601String(),
      });
      
      print('📖 ✅ 默认故事数据初始化完成，共 ${validStories.length} 个故事');
    } catch (e, stackTrace) {
      print('📖 ❌ 初始化默认故事数据失败: $e');
      print('📖 ❌ 错误堆栈: $stackTrace');
      // 如果加载模板失败，创建空的故事文件
      await _writeJsonFile(_storiesFile, {
        'stories': [],
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
  }

  // ========== 题目相关方法 ==========

  /// 获取所有题目
  Future<List<Question>> getAllQuestions() async {
    await _ensureInitialized();
    final data = await _readJsonFile(_questionsFile);
    final questionsList = data['questions'] as List? ?? [];
    return questionsList
        .map((q) => Question.fromMap(q as Map<String, dynamic>))
        .toList();
  }

  /// 添加题目
  Future<void> addQuestion(Question question) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_questionsFile);
    final questionsList = (data['questions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    // 检查是否已存在
    if (!questionsList.any((q) => q['id'] == question.id)) {
      questionsList.add(question.toMap());
      await _writeJsonFile(_questionsFile, {
        'questions': questionsList,
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
  }

  /// 批量添加题目
  Future<void> addQuestions(List<Question> questions) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_questionsFile);
    final questionsList = (data['questions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    final existingIds = questionsList.map((q) => q['id'] as int).toSet();
    for (final question in questions) {
      if (!existingIds.contains(question.id)) {
        questionsList.add(question.toMap());
        existingIds.add(question.id);
      }
    }
    
    await _writeJsonFile(_questionsFile, {
      'questions': questionsList,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  /// 根据ID获取题目
  Future<Question?> getQuestionById(int id) async {
    final questions = await getAllQuestions();
    try {
      return questions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 更新题目
  Future<void> updateQuestion(Question question) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_questionsFile);
    final questionsList = (data['questions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    final index = questionsList.indexWhere((q) => q['id'] == question.id);
    if (index >= 0) {
      questionsList[index] = question.toMap();
      await _writeJsonFile(_questionsFile, {
        'questions': questionsList,
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
  }

  // ========== 拾光记录相关方法 ==========

  /// 获取所有拾光记录
  Future<List<TestRecord>> getAllTestRecords() async {
    await _ensureInitialized();
    final data = await _readJsonFile(_testRecordsFile);
    final recordsList = data['records'] as List? ?? [];
    return recordsList
        .map((r) => TestRecord.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// 添加拾光记录
  Future<int> addTestRecord(TestRecord record) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_testRecordsFile);
    final recordsList = (data['records'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    // 生成ID（如果记录没有ID，自动生成）
    int newId = record.id;
    if (newId == 0) {
      if (recordsList.isEmpty) {
        newId = 1;
      } else {
        final maxId = recordsList
            .map((r) => r['id'] as int)
            .reduce((a, b) => a > b ? a : b);
        newId = maxId + 1;
      }
    }
    
    final recordMap = record.toMap();
    recordMap['id'] = newId;
    recordsList.add(recordMap);
    
    await _writeJsonFile(_testRecordsFile, {
      'records': recordsList,
      'last_updated': DateTime.now().toIso8601String(),
    });
    
    return newId;
  }

  /// 根据ID获取拾光记录
  Future<TestRecord?> getTestRecordById(int id) async {
    final records = await getAllTestRecords();
    try {
      return records.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 删除指定的拾光记录
  Future<void> deleteTestRecord(int id) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_testRecordsFile);
    final recordsList = (data['records'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    recordsList.removeWhere((r) => r['id'] == id);
    
    await _writeJsonFile(_testRecordsFile, {
      'records': recordsList,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  /// 清除所有拾光记录
  Future<void> clearAllTestRecords() async {
    await _ensureInitialized();
    await _writeJsonFile(_testRecordsFile, {
      'records': <Map<String, dynamic>>[],
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  // ========== 收藏相关方法 ==========

  /// 获取所有收藏
  Future<List<EchoCollection>> getAllCollections() async {
    await _ensureInitialized();
    try {
      final data = await _readJsonFile(_collectionsFile);
      final collectionsList = data['collections'] as List? ?? [];
      print('📚 [JsonStorage] 读取收藏文件：找到 ${collectionsList.length} 条记录');
      
      final collections = collectionsList
          .map((c) {
            try {
              return EchoCollection.fromMap(c as Map<String, dynamic>);
            } catch (e) {
              print('📚 [JsonStorage] ⚠️ 解析收藏记录失败: $e, 数据: $c');
              return null;
            }
          })
          .whereType<EchoCollection>()
          .toList();
      
      print('📚 [JsonStorage] 成功解析 ${collections.length} 条收藏记录');
      if (collections.isNotEmpty) {
        print('📚 [JsonStorage] 收藏记录详情:');
        for (final c in collections) {
          print('📚   - ID=${c.id}, questionId=${c.questionId}, time=${c.collectionTime}');
        }
      }
      
      return collections;
    } catch (e, stackTrace) {
      print('📚 [JsonStorage] ❌ 获取所有收藏失败: $e');
      print('📚 [JsonStorage] ❌ 错误堆栈: $stackTrace');
      return [];
    }
  }

  /// 添加收藏（如果已存在则更新）
  Future<void> addCollection(EchoCollection collection) async {
    await _ensureInitialized();
    print('📚 [JsonStorage] 添加收藏: id=${collection.id}, questionId=${collection.questionId}');
    
    final data = await _readJsonFile(_collectionsFile);
    final collectionsList = (data['collections'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    print('📚 [JsonStorage] 当前收藏列表长度: ${collectionsList.length}');
    
    // 检查是否已存在（按 collection.id 检查）
    final index = collectionsList.indexWhere((c) => c['id'] == collection.id);
    if (index >= 0) {
      // 已存在，更新
      print('📚 [JsonStorage] 收藏已存在，更新索引 $index');
      collectionsList[index] = collection.toMap();
    } else {
      // 不存在，添加
      print('📚 [JsonStorage] 收藏不存在，添加到列表');
      collectionsList.add(collection.toMap());
      print('📚 [JsonStorage] 添加后列表长度: ${collectionsList.length}');
    }
    
    // 写入文件
    final writeData = {
      'collections': collectionsList,
      'last_updated': DateTime.now().toIso8601String(),
    };
    
    try {
      await _writeJsonFile(_collectionsFile, writeData);
      print('📚 [JsonStorage] ✅ 收藏数据已写入文件');
      
      // 验证写入是否成功
      final verifyData = await _readJsonFile(_collectionsFile);
      final verifyList = (verifyData['collections'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();
      print('📚 [JsonStorage] 验证：写入后文件中的收藏数量: ${verifyList.length}');
      
      final verifyCollection = verifyList.firstWhere(
        (c) => c['id'] == collection.id,
        orElse: () => {},
      );
      if (verifyCollection.isNotEmpty) {
        print('📚 [JsonStorage] ✅ 验证成功：收藏已正确保存');
      } else {
        print('📚 [JsonStorage] ⚠️ 验证失败：未找到刚保存的收藏');
      }
    } catch (e, stackTrace) {
      print('📚 [JsonStorage] ❌ 写入收藏失败: $e');
      print('📚 [JsonStorage] ❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 删除收藏
  Future<void> removeCollection(int collectionId) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_collectionsFile);
    final collectionsList = (data['collections'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    collectionsList.removeWhere((c) => c['id'] == collectionId);
    
    await _writeJsonFile(_collectionsFile, {
      'collections': collectionsList,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  // ========== 成就相关方法 ==========

  /// 获取所有成就
  Future<List<EchoAchievement>> getAllAchievements() async {
    await _ensureInitialized();
    final data = await _readJsonFile(_achievementsFile);
    final achievementsList = data['achievements'] as List? ?? [];
    return achievementsList.map((a) {
      final map = Map<String, dynamic>.from(a as Map<String, dynamic>);
      // 将JSON格式（bool）转换为模型期望的格式（int）
      if (map['is_unlocked'] is bool) {
        map['is_unlocked'] = map['is_unlocked'] ? 1 : 0;
      } else if (map['is_unlocked'] == null) {
        map['is_unlocked'] = 0;
      }
      return EchoAchievement.fromMap(map);
    }).toList();
  }

  /// 更新成就
  Future<void> updateAchievement(EchoAchievement achievement) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_achievementsFile);
    final achievementsList = (data['achievements'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    final index = achievementsList.indexWhere((a) => a['id'] == achievement.id);
    if (index >= 0) {
      final achievementMap = achievement.toMap();
      // 将 is_unlocked 转为 bool（而不是 int）以保持JSON格式一致性
      achievementMap['is_unlocked'] = achievement.isUnlocked;
      achievementsList[index] = achievementMap;
    } else {
      // 如果不存在，添加新成就
      final achievementMap = achievement.toMap();
      achievementMap['is_unlocked'] = achievement.isUnlocked;
      achievementsList.add(achievementMap);
    }
    
    await _writeJsonFile(_achievementsFile, {
      'achievements': achievementsList,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  /// 根据ID获取成就
  Future<EchoAchievement?> getAchievementById(int id) async {
    final achievements = await getAllAchievements();
    try {
      return achievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== 设置相关方法 ==========

  /// 获取设置
  Future<T?> getSetting<T>(String key) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_settingsFile);
    final settings = data['settings'] as Map<String, dynamic>? ?? {};
    final value = settings[key];
    
    if (value == null) return null;
    
    // 类型转换
    if (T == bool && value is bool) {
      return value as T;
    } else if (T == int && value is int) {
      return value as T;
    } else if (T == double && value is num) {
      return value.toDouble() as T;
    } else if (T == String && value is String) {
      return value as T;
    } else if (T == String && value != null) {
      // 尝试转换其他类型为字符串
      return value.toString() as T;
    }
    
    return value as T?;
  }

  /// 更新设置
  Future<void> updateSetting(String key, dynamic value) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_settingsFile);
    final settings = (data['settings'] as Map<String, dynamic>? ?? {});
    
    settings[key] = value;
    
    await _writeJsonFile(_settingsFile, {
      'settings': settings,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  /// 获取所有设置
  Future<Map<String, dynamic>> getAllSettings() async {
    await _ensureInitialized();
    final data = await _readJsonFile(_settingsFile);
    return data['settings'] as Map<String, dynamic>? ?? {};
  }

  // ========== 工具方法 ==========

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// 获取存储目录路径
  String? getStoragePath() => _storageDirectory?.path;

  /// 清除所有数据
  Future<void> clearAllData() async {
    await _ensureInitialized();
    final files = [
      _questionsFile,
      _testRecordsFile,
      _collectionsFile,
      _achievementsFile,
      _settingsFile,
      _questionUpdateLogFile,
      _memoriesFile,  // 记忆胶囊文件
      _storiesFile,   // 故事文件
    ];
    
    for (final file in files) {
      try {
        final filePath = File(_getFilePath(file));
        if (await filePath.exists()) {
          await filePath.delete();
        }
      } catch (e) {
        print('⚠️ 删除文件失败 $file: $e');
      }
    }
    
    // 重新初始化默认数据
    await _initializeDefaultData();
  }

  /// 导出所有数据
  Future<Map<String, dynamic>> exportAllData() async {
    await _ensureInitialized();
    return {
      'questions': (await getAllQuestions()).map((q) => q.toMap()).toList(),
      'test_records': (await getAllTestRecords()).map((r) => r.toMap()).toList(),
      'collections': (await getAllCollections()).map((c) => c.toMap()).toList(),
      'achievements': (await getAllAchievements()).map((a) => a.toMap()).toList(),
      'memories': (await getAllMemories()).map((m) => m.toMap()).toList(),
      'stories': (await getAllStories()).map((s) => s.toMap()).toList(),
      'settings': await getAllSettings(),
      'export_time': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// 导入所有数据
  Future<void> importAllData(Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    if (data.containsKey('questions')) {
      final questions = (data['questions'] as List)
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList();
      await _writeJsonFile(_questionsFile, {
        'questions': questions.map((q) => q.toMap()).toList(),
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
    
    if (data.containsKey('test_records')) {
      await _writeJsonFile(_testRecordsFile, {
        'records': data['test_records'],
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
    
    if (data.containsKey('collections')) {
      await _writeJsonFile(_collectionsFile, {
        'collections': data['collections'],
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
    
    if (data.containsKey('achievements')) {
      await _writeJsonFile(_achievementsFile, {
        'achievements': data['achievements'],
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
    
    if (data.containsKey('settings')) {
      await _writeJsonFile(_settingsFile, {
        'settings': data['settings'],
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
    
    if (data.containsKey('memories')) {
      await _writeJsonFile(_memoriesFile, {
        'memories': data['memories'],
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
    
    if (data.containsKey('stories')) {
      await _writeJsonFile(_storiesFile, {
        'stories': data['stories'],
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
  }

  // ========== 回忆相关方法 ==========

  /// 获取所有回忆
  Future<List<MemoryRecord>> getAllMemories() async {
    await _ensureInitialized();
    try {
      final data = await _readJsonFile(_memoriesFile);
      final memoriesList = data['memories'] as List? ?? [];
      print('💝 [JsonStorage] 读取回忆文件：找到 ${memoriesList.length} 条记录');
      
      final memories = memoriesList
          .map((m) {
            try {
              return MemoryRecord.fromMap(m as Map<String, dynamic>);
            } catch (e) {
              print('💝 [JsonStorage] ⚠️ 解析回忆记录失败: $e, 数据: $m');
              return null;
            }
          })
          .whereType<MemoryRecord>()
          .toList();
      
      print('💝 [JsonStorage] 成功解析 ${memories.length} 条回忆记录');
      return memories;
    } catch (e, stackTrace) {
      print('💝 [JsonStorage] ❌ 获取所有回忆失败: $e');
      print('💝 [JsonStorage] ❌ 错误堆栈: $stackTrace');
      return [];
    }
  }

  /// 添加回忆（如果已存在则更新）
  Future<void> addMemory(MemoryRecord memory) async {
    await _ensureInitialized();
    print('💝 [JsonStorage] 添加回忆: id=${memory.id}, era=${memory.era}');
    
    final data = await _readJsonFile(_memoriesFile);
    final memoriesList = (data['memories'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    // 检查是否已存在（按 memory.id 检查）
    final index = memoriesList.indexWhere((m) => m['id'] == memory.id);
    if (index >= 0) {
      // 已存在，更新
      print('💝 [JsonStorage] 回忆已存在，更新索引 $index');
      memoriesList[index] = memory.toMap();
    } else {
      // 不存在，添加
      print('💝 [JsonStorage] 回忆不存在，添加到列表');
      memoriesList.add(memory.toMap());
    }
    
    // 写入文件
    final writeData = {
      'memories': memoriesList,
      'last_updated': DateTime.now().toIso8601String(),
    };
    
    try {
      await _writeJsonFile(_memoriesFile, writeData);
      print('💝 [JsonStorage] ✅ 回忆数据已写入文件');
    } catch (e, stackTrace) {
      print('💝 [JsonStorage] ❌ 写入回忆失败: $e');
      print('💝 [JsonStorage] ❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 删除回忆
  Future<void> removeMemory(int memoryId) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_memoriesFile);
    final memoriesList = (data['memories'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    memoriesList.removeWhere((m) => m['id'] == memoryId);
    
    await _writeJsonFile(_memoriesFile, {
      'memories': memoriesList,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  // ========== 故事相关方法 ==========

  /// 获取所有故事
  Future<List<NostalgicStory>> getAllStories() async {
    await _ensureInitialized();
    try {
      final data = await _readJsonFile(_storiesFile);
      final storiesList = data['stories'] as List? ?? [];
      print('📖 [JsonStorage] 读取故事文件：找到 ${storiesList.length} 条记录');
      
      final stories = storiesList
          .map((s) {
            try {
              return NostalgicStory.fromMap(s as Map<String, dynamic>);
            } catch (e) {
              print('📖 [JsonStorage] ⚠️ 解析故事记录失败: $e, 数据: $s');
              return null;
            }
          })
          .whereType<NostalgicStory>()
          .toList();
      
      print('📖 [JsonStorage] 成功解析 ${stories.length} 条故事记录');
      return stories;
    } catch (e, stackTrace) {
      print('📖 [JsonStorage] ❌ 获取所有故事失败: $e');
      print('📖 [JsonStorage] ❌ 错误堆栈: $stackTrace');
      return [];
    }
  }

  /// 添加故事（如果已存在则更新）
  Future<void> addStory(NostalgicStory story) async {
    await _ensureInitialized();
    print('📖 [JsonStorage] 添加故事: id=${story.id}, title=${story.title}');
    
    final data = await _readJsonFile(_storiesFile);
    final storiesList = (data['stories'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    // 检查是否已存在（按 story.id 检查）
    final index = storiesList.indexWhere((s) => s['id'] == story.id);
    if (index >= 0) {
      // 已存在，更新
      print('📖 [JsonStorage] 故事已存在，更新索引 $index');
      storiesList[index] = story.toMap();
    } else {
      // 不存在，添加
      print('📖 [JsonStorage] 故事不存在，添加到列表');
      storiesList.add(story.toMap());
    }
    
    // 写入文件
    final writeData = {
      'stories': storiesList,
      'last_updated': DateTime.now().toIso8601String(),
    };
    
    try {
      await _writeJsonFile(_storiesFile, writeData);
      print('📖 [JsonStorage] ✅ 故事数据已写入文件');
    } catch (e, stackTrace) {
      print('📖 [JsonStorage] ❌ 写入故事失败: $e');
      print('📖 [JsonStorage] ❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 删除故事
  Future<void> removeStory(int storyId) async {
    await _ensureInitialized();
    final data = await _readJsonFile(_storiesFile);
    final storiesList = (data['stories'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    
    storiesList.removeWhere((s) => s['id'] == storyId);
    
    await _writeJsonFile(_storiesFile, {
      'stories': storiesList,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }
}

