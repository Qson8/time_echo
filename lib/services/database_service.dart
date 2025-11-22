import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
// 条件导入：只在Web平台导入FFI Web
import 'database_service_stub.dart'
    if (dart.library.html) 'database_service_web.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/echo_collection.dart';
import '../models/echo_achievement.dart';
import '../models/test_record.dart';
import '../models/question_update_log.dart';

/// 检测是否为鸿蒙平台
bool get _isHarmonyOS {
  try {
    // 尝试通过环境变量或其他方式检测
    // 如果 sqflite_common_ffi 失败，很可能是鸿蒙平台
    return Platform.isLinux && !kIsWeb;
  } catch (e) {
    // 如果无法确定，返回false，让代码尝试其他方式
    return false;
  }
}

/// 数据库服务类
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'time_echo.db';
  static const int _databaseVersion = 1;
  static bool _initFailed = false; // 标记初始化是否已失败，避免重复尝试
  static Exception? _lastInitError; // 记录最后一次初始化错误

  /// 获取数据库实例
  static Future<Database> get database async {
    if (_database != null) return _database!;
    
    // 如果之前初始化失败，直接抛出错误，避免重复尝试
    if (_initFailed && _lastInitError != null) {
      throw _lastInitError!;
    }
    
    try {
      _database = await _initDatabase();
      _initFailed = false; // 重置失败标志
      return _database!;
    } catch (e) {
      // 特别处理 databaseFactory not initialized 错误
      final errorStr = e.toString();
      if (errorStr.contains('databaseFactory not initialized') ||
          errorStr.contains('Bad state: databaseFactory')) {
        print('🗄️ ❌ 捕获到 databaseFactory 未初始化错误');
        print('🗄️ 💡 这通常发生在鸿蒙等平台上，当 sqflite 试图使用 FFI 但未正确初始化时');
        _initFailed = true;
        _lastInitError = Exception('数据库未初始化：platform不支持当前sqflite配置。请确保在移动平台上使用原生sqflite实现。');
        throw _lastInitError!;
      }
      
      _initFailed = true;
      _lastInitError = e is Exception ? e : Exception(e.toString());
      rethrow;
    }
  }
  
  /// 检查数据库是否可用
  static bool get isDatabaseAvailable => _database != null && !_initFailed;

  /// 初始化数据库
  static Future<Database> _initDatabase() async {
    print('🗄️ 开始初始化数据库...');
    
    // 检测平台类型
    bool useFFI = false;
    String? detectedPlatform;
    
    // 首先检查是否为移动平台（Android/iOS/鸿蒙）
    // 移动平台应该使用原生sqflite，而不是FFI
    bool isMobilePlatform = false;
    try {
      if (!kIsWeb) {
        // 检测是否为移动平台
        isMobilePlatform = Platform.isAndroid || Platform.isIOS;
        // 鸿蒙在Flutter中可能被识别为Linux，需要额外处理
        // 但如果我们看到getDatabasesPath返回/.dart_tool路径，说明可能误用了FFI
      }
    } catch (e) {
      print('🗄️ ⚠️ 平台检测异常: $e');
    }
    
    try {
      if (kIsWeb) {
        detectedPlatform = 'web';
        final ffiWebFactory = getDatabaseFactoryFfiWeb();
        if (ffiWebFactory != null) {
          databaseFactory = ffiWebFactory;
          useFFI = true;
          print('🗄️ 检测到 Web 平台，使用 FFI Web');
        } else {
          // 如果FFI Web不可用，使用标准实现
          useFFI = false;
          print('🗄️ ⚠️ Web平台但FFI Web不可用，使用标准实现');
        }
      } else if (isMobilePlatform) {
        // 移动平台（Android/iOS），明确不使用FFI
        detectedPlatform = 'mobile-native';
        useFFI = false;
        // 确保不设置databaseFactory，使用原生实现
        print('🗄️ 检测为移动平台（Android/iOS），使用原生 sqflite');
      } else {
        // 桌面平台（Linux/macOS/Windows），可能需要FFI
        // 但如果是鸿蒙（可能识别为Linux），应该使用原生sqflite
        detectedPlatform = 'desktop-or-harmonyos';
        useFFI = false; // 默认不使用FFI，避免鸿蒙平台问题
        print('🗄️ 检测为桌面平台或鸿蒙，默认使用原生 sqflite（避免FFI兼容问题）');
      }
    } catch (e) {
      print('🗄️ ⚠️ 平台检测失败: $e，使用标准 sqflite');
      detectedPlatform = 'unknown';
      useFFI = false;
    }
    
    // 确保在移动平台上不设置FFI factory
    if (!useFFI && !kIsWeb) {
      // 移动平台：明确不设置databaseFactory，使用原生实现
      // 如果之前设置过，需要重置（但实际上我们不应该在这里设置）
      print('🗄️ 移动平台：确保使用原生sqflite（不设置FFI factory）');
    }
    
    // 获取正确的数据库路径
    String? databasesPath;
    
    if (kIsWeb) {
      try {
        databasesPath = await getDatabasesPath();
      } catch (e) {
        print('🗄️ ❌ Web平台getDatabasesPath失败: $e');
        rethrow;
      }
    } else if (!useFFI) {
      // 移动平台（Android/iOS/鸿蒙），尝试多种方式获取路径
      // 注意：移动平台上不应该使用 getDatabasesPath()，因为它需要 databaseFactory
      // 而我们不想在移动平台上设置 FFI factory
      databasesPath = null;
      
      // 方案1：尝试使用path_provider（首选，因为它在鸿蒙上可能可用）
      try {
        final Directory appSupportDir = await getApplicationSupportDirectory();
        databasesPath = appSupportDir.path;
        print('🗄️ ✅ 使用path_provider获取路径: $databasesPath');
      } catch (e) {
        print('🗄️ ⚠️ path_provider不可用: $e');
      }
      
      // 方案2：如果path_provider失败，直接使用应用数据目录（跳过getDatabasesPath）
      // 因为getDatabasesPath在移动平台上需要databaseFactory，但我们不想设置FFI
      if (databasesPath == null) {
        try {
          // 尝试使用应用文档目录
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          databasesPath = appDocDir.path;
          print('🗄️ ✅ 使用应用文档目录作为路径: $databasesPath');
        } catch (e) {
          print('🗄️ ⚠️ 应用文档目录不可用: $e');
        }
      }
      
      // 方案3：如果都失败，使用临时目录（最后备用）
      if (databasesPath == null) {
        try {
          final tempDir = Directory.systemTemp;
          databasesPath = join(tempDir.path, 'time_echo_db');
          // 确保目录存在
          final dbDir = Directory(databasesPath!);
          if (!await dbDir.exists()) {
            await dbDir.create(recursive: true);
          }
          print('🗄️ ⚠️ 使用临时目录作为备用路径: $databasesPath');
        } catch (e) {
          print('🗄️ ❌ 临时目录也失败: $e');
          // 所有方案都失败，抛出异常让应用使用内存存储
          throw Exception('无法获取数据库路径：所有路径获取方式都失败。应用将使用内存存储方案。');
        }
      }
    } else {
      // 桌面平台使用FFI，需要手动获取路径
      // 但为了兼容鸿蒙等可能被误识别为桌面平台的移动平台，优先使用path_provider
      // 尝试多种路径获取方式
      databasesPath = null;
      
      // 方案1：尝试使用 path_provider（首选）
      try {
        final Directory appSupportDir = await getApplicationSupportDirectory();
        databasesPath = appSupportDir.path;
        print('🗄️ ✅ 使用 path_provider 获取路径: $databasesPath');
      } catch (e) {
        print('🗄️ ⚠️ path_provider 不可用: $e');
      }
      
      // 方案2：如果path_provider失败，尝试应用文档目录
      if (databasesPath == null) {
        try {
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          databasesPath = appDocDir.path;
          print('🗄️ ✅ 使用应用文档目录: $databasesPath');
        } catch (e2) {
          print('🗄️ ⚠️ 应用文档目录不可用: $e2');
        }
      }
      
      // 方案3：如果都失败，只在FFI已初始化时才尝试getDatabasesPath
      if (databasesPath == null && useFFI) {
        try {
          // 只有在使用FFI的情况下才调用getDatabasesPath
          databasesPath = await getDatabasesPath();
          print('🗄️ ✅ 使用 getDatabasesPath() 获取路径: $databasesPath');
        } catch (e3) {
          print('🗄️ ⚠️ getDatabasesPath() 也失败: $e3');
        }
      }
      
      // 方案4：如果都失败，使用临时目录
      if (databasesPath == null) {
        try {
          final tempDir = Directory.systemTemp;
          databasesPath = join(tempDir.path, 'time_echo_db');
          if (databasesPath != null) {
            final dbDir = Directory(databasesPath!);
            if (!await dbDir.exists()) {
              await dbDir.create(recursive: true);
            }
            print('🗄️ ⚠️ 使用临时目录: $databasesPath');
          }
        } catch (e4) {
          print('🗄️ ⚠️ 临时目录也失败: $e4');
          // 方案5：最后使用当前工作目录
          try {
            databasesPath = Directory.current.path;
            print('🗄️ ⚠️ 使用当前工作目录: $databasesPath');
          } catch (e5) {
            print('🗄️ ❌ 所有路径获取方式都失败: $e5');
          }
        }
      }
      
      // 确保目录存在（仅FFI平台）
      if (useFFI && databasesPath != null) {
        try {
          final dbDir = Directory(databasesPath!);
          if (!await dbDir.exists()) {
            await dbDir.create(recursive: true);
            print('🗄️ ✅ 创建数据库目录成功');
          }
        } catch (e) {
          print('🗄️ ⚠️ 创建数据库目录失败: $e');
          // 继续执行，让数据库自己处理
        }
      }
    }
    
    // 确保databasesPath不为null
    if (databasesPath == null) {
      throw Exception('无法获取数据库路径：所有路径获取方式都失败。应用将使用内存存储方案。');
    }
    
    String path = join(databasesPath, _databaseName);
    print('🗄️ 数据库完整路径: $path');
    print('🗄️ 使用平台: $detectedPlatform, 使用FFI: $useFFI');
    
    try {
      Database db;
      if (!useFFI) {
        // 移动平台使用标准 sqflite（不指定 factory）
        db = await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _onCreate,
        );
      } else {
        // 桌面/Web平台使用FFI
        db = await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _onCreate,
        );
      }
      print('🗄️ ✅ 数据库初始化成功');
      return db;
    } catch (e, stackTrace) {
      print('🗄️ ❌ 数据库初始化失败: $e');
      print('🗄️ ❌ 错误堆栈: $stackTrace');
      
      // 如果是"Unsupported platform"错误，说明是移动平台（如鸿蒙），不应该使用FFI
      if (e.toString().contains('Unsupported platform') || 
          e.toString().contains('Unsupported operation') ||
          e.toString().contains('ohos')) {
        print('🗄️ 🔄 检测到平台不支持FFI（可能是鸿蒙），切换到原生sqflite...');
        
        // 清除任何FFI相关的factory设置
        try {
          // 尝试重置databaseFactory（如果可能）
          // 注意：sqflite的databaseFactory是全局变量，我们需要确保它不被FFI版本占用
          print('🗄️ 确保使用原生sqflite实现（不设置factory）');
        } catch (resetError) {
          print('🗄️ ⚠️ 重置factory时出错: $resetError');
        }
        
        try {
          // 重新获取路径，不使用getDatabasesPath（避免databaseFactory问题）
          print('🗄️ 重新获取数据库路径（原生实现，不使用getDatabasesPath）...');
          
          // 尝试使用path_provider获取路径
          try {
            final Directory appSupportDir = await getApplicationSupportDirectory();
            databasesPath = appSupportDir.path;
            print('🗄️ ✅ 使用path_provider获取路径: $databasesPath');
          } catch (e) {
            print('🗄️ ⚠️ path_provider不可用: $e');
            // 尝试应用文档目录
            try {
              final Directory appDocDir = await getApplicationDocumentsDirectory();
              databasesPath = appDocDir.path;
              print('🗄️ ✅ 使用应用文档目录: $databasesPath');
            } catch (e2) {
              print('🗄️ ⚠️ 应用文档目录也不可用: $e2');
              // 使用临时目录
              final tempDir = Directory.systemTemp;
              databasesPath = join(tempDir.path, 'time_echo_db');
              if (databasesPath != null) {
                final dbDir = Directory(databasesPath!);
                if (!await dbDir.exists()) {
                  await dbDir.create(recursive: true);
                }
                print('🗄️ ⚠️ 使用临时目录: $databasesPath');
              }
            }
          }
          
          if (databasesPath == null) {
            throw Exception('无法获取数据库路径');
          }
          
          path = join(databasesPath, _databaseName);
          print('🗄️ ✅ 获取到原生路径: $path');
          print('🗄️ 尝试使用标准sqflite原生实现打开数据库...');
          
          // 使用openDatabase，不指定factory，让sqflite使用原生实现
          final db = await openDatabase(
            path,
            version: _databaseVersion,
            onCreate: _onCreate,
          );
          print('🗄️ ✅ 使用标准sqflite初始化成功');
          return db;
        } catch (e2, stackTrace2) {
          print('🗄️ ❌ 标准sqflite也失败: $e2');
          print('🗄️ ❌ 错误堆栈: $stackTrace2');
          
          // 如果标准sqflite也失败，说明可能是sqflite插件本身的问题或FFI污染
          print('🗄️ ⚠️ 所有数据库初始化方式都失败');
          print('🗄️ 💡 建议：检查pubspec.yaml，确保在移动平台上不使用sqflite_common_ffi');
          print('🗄️ 💡 应用将继续运行，但将使用内存模式和JSON存储备用方案');
          
          // 抛出有意义的异常，但包含说明，让上层知道数据库不可用
          throw Exception('数据库初始化失败：平台不支持当前配置的sqflite实现。错误：$e2');
        }
      }
      
      rethrow;
    }
  }

  /// 创建数据库表
  static Future<void> _onCreate(Database db, int version) async {
    // 题目表
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        echo_theme TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_answer INTEGER NOT NULL,
        explanation TEXT NOT NULL,
        is_new INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 拾光收藏夹表
    await db.execute('''
      CREATE TABLE echo_collection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        echo_note TEXT DEFAULT '',
        collection_time TEXT NOT NULL,
        FOREIGN KEY (question_id) REFERENCES questions (id)
      )
    ''');

    // 拾光成就表
    await db.execute('''
      CREATE TABLE echo_achievement (
        id INTEGER PRIMARY KEY,
        achievement_name TEXT NOT NULL,
        achievement_icon TEXT NOT NULL,
        reward TEXT NOT NULL,
        condition TEXT NOT NULL,
        is_unlocked INTEGER DEFAULT 0,
        unlocked_at TEXT NOT NULL
      )
    ''');

    // 拾光记录表
    await db.execute('''
      CREATE TABLE test_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_questions INTEGER NOT NULL,
        correct_answers INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        total_time INTEGER NOT NULL,
        echo_age INTEGER NOT NULL,
        comment TEXT NOT NULL,
        test_time TEXT NOT NULL,
        category_scores TEXT NOT NULL
      )
    ''');

    // 题库更新日志表
    await db.execute('''
      CREATE TABLE question_update_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app_name TEXT NOT NULL,
        new_question_count INTEGER NOT NULL,
        version TEXT NOT NULL,
        update_time TEXT NOT NULL,
        is_updated INTEGER DEFAULT 0
      )
    ''');

    // 用户设置表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 插入初始成就数据
    await _insertInitialAchievements(db);
    
    // 插入初始题目数据
    await _insertInitialQuestions(db);
  }

  /// 插入初始成就数据
  static Future<void> _insertInitialAchievements(Database db) async {
    final achievements = [
      {
        'id': 1,
        'achievement_name': '拾光初遇',
        'achievement_icon': 'icons/echo_badge_first.png',
        'reward': '解锁拾光徽章・初遇',
        'condition': '完成首次拾光',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'achievement_name': '影视拾光者',
        'achievement_icon': 'icons/echo_badge_movie.png',
        'reward': '解锁影视徽章・拾光+收藏夹容量+5题',
        'condition': '影视分类题库正确率≥90%',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 3,
        'achievement_name': '音乐回响者',
        'achievement_icon': 'icons/echo_badge_music.png',
        'reward': '解锁音乐徽章・回响+收藏夹容量+5题',
        'condition': '音乐分类题库正确率≥90%',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 4,
        'achievement_name': '时代见证者',
        'achievement_icon': 'icons/echo_badge_event.png',
        'reward': '解锁事件徽章・见证+收藏夹容量+5题',
        'condition': '事件分类题库正确率≥90%',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 5,
        'achievement_name': '拾光速答手',
        'achievement_icon': 'icons/echo_badge_speed.png',
        'reward': '解锁速答徽章・拾光',
        'condition': '单次拾光单题平均耗时≤15秒',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 6,
        'achievement_name': '拾光挑战者',
        'achievement_icon': 'icons/echo_badge_challenge.png',
        'reward': '解锁挑战徽章・拾光',
        'condition': '单次拾光困难题正确率100%',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 7,
        'achievement_name': '拾光收藏家',
        'achievement_icon': 'icons/echo_badge_collector.png',
        'reward': '解锁收藏徽章・拾光+收藏夹容量+10题',
        'condition': '收藏题目数量≥20道',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 8,
        'achievement_name': '拾光全勤人',
        'achievement_icon': 'icons/echo_badge_attendance.png',
        'reward': '解锁全勤徽章・拾光+随机拾光怀旧语录',
        'condition': '连续7天每天完成1次拾光',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 9,
        'achievement_name': '80年代专家',
        'achievement_icon': 'icons/echo_badge_80s.png',
        'reward': '解锁80年代专家徽章・拾光',
        'condition': '单次拾光中80年代题目正确率≥90%',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 10,
        'achievement_name': '90年代专家',
        'achievement_icon': 'icons/echo_badge_90s.png',
        'reward': '解锁90年代专家徽章・拾光',
        'condition': '单次拾光中90年代题目正确率≥90%',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 11,
        'achievement_name': '00年代专家',
        'achievement_icon': 'icons/echo_badge_00s.png',
        'reward': '解锁00年代专家徽章・拾光',
        'condition': '单次拾光中00年代题目正确率≥90%',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 12,
        'achievement_name': '拾光记忆大师',
        'achievement_icon': 'icons/echo_badge_master.png',
        'reward': '解锁记忆大师徽章・拾光',
        'condition': '累计完成拾光≥30次',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 13,
        'achievement_name': '拾光完美主义者',
        'achievement_icon': 'icons/echo_badge_perfect.png',
        'reward': '解锁完美徽章・拾光',
        'condition': '单次拾光获得100%正确率',
        'is_unlocked': 0,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final achievement in achievements) {
      await db.insert('echo_achievement', achievement);
    }
  }

  /// 插入初始题目数据
  static Future<void> _insertInitialQuestions(Database db) async {
    final questions = [
      {
        'id': 1,
        'content': '以下哪部电影是1987年上映的经典爱情片？',
        'category': '影视',
        'difficulty': '简单',
        'echo_theme': '80年代影视',
        'options': '《泰坦尼克号》|《乱世佳人》|《人鬼情未了》|《魂断蓝桥》',
        'correct_answer': 2,
        'explanation': '《人鬼情未了》是1987年上映的经典爱情片，由帕特里克·斯威兹和黛米·摩尔主演。',
        'is_new': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'content': '以下哪位歌手被称为"摇滚之王"？',
        'category': '音乐',
        'difficulty': '简单',
        'echo_theme': '80年代音乐',
        'options': '迈克尔·杰克逊|埃尔维斯·普雷斯利|约翰·列侬|鲍勃·迪伦',
        'correct_answer': 1,
        'explanation': '埃尔维斯·普雷斯利（猫王）被称为"摇滚之王"，是摇滚乐的开创者之一。',
        'is_new': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 3,
        'content': '1989年发生的重大历史事件是？',
        'category': '事件',
        'difficulty': '中等',
        'echo_theme': '80年代事件',
        'options': '柏林墙倒塌|苏联解体|海湾战争|东欧剧变',
        'correct_answer': 0,
        'explanation': '1989年11月9日，柏林墙倒塌，标志着冷战的结束和东西德统一的开始。',
        'is_new': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 4,
        'content': '以下哪部电视剧是1990年代的热门剧集？',
        'category': '影视',
        'difficulty': '中等',
        'echo_theme': '90年代影视',
        'options': '《还珠格格》|《西游记》|《红楼梦》|《水浒传》',
        'correct_answer': 0,
        'explanation': '《还珠格格》是1998年首播的古装剧，在90年代非常受欢迎。',
        'is_new': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 5,
        'content': '以下哪首歌是1990年代的经典流行歌曲？',
        'category': '音乐',
        'difficulty': '简单',
        'echo_theme': '90年代音乐',
        'options': '《月亮代表我的心》|《甜蜜蜜》|《心太软》|《夜来香》',
        'correct_answer': 2,
        'explanation': '《心太软》是任贤齐1996年发行的歌曲，是90年代的代表作之一。',
        'is_new': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final question in questions) {
      await db.insert('questions', question);
    }
  }

  /// 更新或插入设置
  
  static Future<void> updateSetting(String key, dynamic value) async {
    try {
      // 检查数据库是否可用
      if (_initFailed || !isDatabaseAvailable) {
        print('🗄️ ⚠️ 数据库不可用，无法更新设置: $key');
        return;
      }
      
      final db = await database;
      await db.insert(
        'user_settings',
        {'key': key, 'value': value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // 如果是 databaseFactory 未初始化错误，标记为失败并静默返回
      if (e.toString().contains('databaseFactory not initialized') ||
          e.toString().contains('Bad state')) {
        print('🗄️ ⚠️ 数据库未初始化，无法更新设置: $key');
        _initFailed = true;
        return;
      }
      print('🗄️ ⚠️ 更新设置失败: $key, 错误: $e');
      // 不抛出异常，允许应用继续运行，使用JSON存储作为备用
    }
  }

  /// 获取设置
  static Future<String?> getSetting(String key) async {
    try {
      // 检查数据库是否可用
      if (_initFailed || !isDatabaseAvailable) {
        print('🗄️ ⚠️ 数据库不可用，无法获取设置: $key');
        return null;
      }
      
      final db = await database;
      final result = await db.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (result.isNotEmpty) {
        return result.first['value'] as String?;
      }
      return null;
    } catch (e) {
      // 如果是 databaseFactory 未初始化错误，标记为失败并返回null
      if (e.toString().contains('databaseFactory not initialized') ||
          e.toString().contains('Bad state')) {
        print('🗄️ ⚠️ 数据库未初始化，无法获取设置: $key');
        _initFailed = true;
        return null;
      }
      print('🗄️ ⚠️ 获取设置失败: $key, 错误: $e');
      return null;
    }
  }

  /// 关闭数据库
  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
