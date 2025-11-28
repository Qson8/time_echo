import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/memory_capsule.dart';
import 'json_storage_service.dart';
import 'memory_service.dart'; // 用于数据迁移

/// 记忆胶囊服务类（完全离线，支持鸿蒙平台）
class MemoryCapsuleService {
  static final MemoryCapsuleService _instance = MemoryCapsuleService._internal();
  factory MemoryCapsuleService() => _instance;
  MemoryCapsuleService._internal();

  final JsonStorageService _jsonStorage = JsonStorageService();
  static const String _capsulesFile = 'memory_capsules.json';
  Directory? _mediaDirectory;
  bool _initialized = false;

  /// 初始化服务（支持鸿蒙平台）
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('📦 初始化记忆胶囊服务...');
      
      // 确保JSON存储服务已初始化
      await _jsonStorage.initialize();

      // 初始化媒体文件存储目录（用于存储图片和音频）
      await _initializeMediaDirectory();

      // 加载现有数据
      await _loadCapsules();

      _initialized = true;
      print('✅ 记忆胶囊服务初始化成功');
    } catch (e) {
      print('❌ 记忆胶囊服务初始化失败: $e');
      rethrow;
    }
  }

  /// 初始化媒体文件存储目录（支持鸿蒙平台）
  Future<void> _initializeMediaDirectory() async {
    try {
      Directory? directory;

      // 策略1：应用支持目录
      if (!kIsWeb) {
        try {
          final appSupportDir = await getApplicationSupportDirectory();
          directory = Directory(path.join(appSupportDir.path, 'memory_capsules'));
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          print('✅ 使用应用支持目录存储媒体文件: ${directory.path}');
        } catch (e) {
          print('⚠️ 获取应用支持目录失败: $e');
        }
      }

      // 策略2：应用文档目录
      if (directory == null && !kIsWeb) {
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          directory = Directory(path.join(appDocDir.path, 'memory_capsules'));
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          print('✅ 使用应用文档目录存储媒体文件: ${directory.path}');
        } catch (e) {
          // HarmonyOS 平台可能不支持 path_provider，静默失败，继续尝试其他方案
          print('⚠️ 获取应用文档目录失败（可能是不支持的平台）: $e');
        }
      }

      // 策略3：临时目录（鸿蒙平台备用）
      if (directory == null && !kIsWeb) {
        try {
          final tempDir = await getTemporaryDirectory();
          directory = Directory(path.join(tempDir.path, 'time_echo_data', 'memory_capsules'));
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          print('✅ 使用临时目录存储媒体文件: ${directory.path}');
        } catch (e) {
          // HarmonyOS 平台可能不支持 path_provider，静默失败，继续尝试系统临时目录
          print('⚠️ 获取临时目录失败（可能是不支持的平台）: $e');
        }
      }

      // 策略4：系统临时目录（最后的降级方案）
      if (directory == null) {
        final tempDir = Directory.systemTemp;
        directory = Directory(path.join(tempDir.path, 'time_echo_data', 'memory_capsules'));
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        print('✅ 使用系统临时目录存储媒体文件: ${directory.path}');
      }

      _mediaDirectory = directory;
    } catch (e) {
      print('❌ 初始化媒体目录失败: $e');
      // 不抛出异常，允许在没有媒体目录的情况下继续运行
    }
  }

  List<MemoryCapsule> _capsules = [];

  /// 加载所有记忆胶囊
  Future<void> _loadCapsules() async {
    try {
      final data = await _jsonStorage.readJsonFile(_capsulesFile);
      if (data != null && data is List) {
        // 安全地转换数据，过滤掉null值
        _capsules = (data as List)
            .where((item) => item != null)
            .map((item) {
              try {
                return MemoryCapsule.fromMap(item as Map<String, dynamic>);
              } catch (e) {
                print('⚠️ 跳过无效的记忆胶囊数据: $e');
                return null;
              }
            })
            .where((capsule) => capsule != null)
            .cast<MemoryCapsule>()
            .toList();
        print('✅ 加载了 ${_capsules.length} 个记忆胶囊');
      } else {
        _capsules = [];
        print('📦 没有找到记忆胶囊数据，使用空列表');
      }
    } catch (e) {
      print('⚠️ 加载记忆胶囊失败: $e，使用空列表');
      _capsules = [];
    }
    
    // 确保_capsules不为null
    if (_capsules.isEmpty) {
      _capsules = [];
    }
  }

  /// 保存所有记忆胶囊
  Future<void> _saveCapsules() async {
    try {
      final data = _capsules.map((capsule) => capsule.toMap()).toList();
      print('💾 准备保存 ${_capsules.length} 个记忆胶囊到文件...');
      await _jsonStorage.writeJsonFile(_capsulesFile, data);
      print('✅ 保存了 ${_capsules.length} 个记忆胶囊到文件');
      
      // 验证保存是否成功：立即读取验证
      try {
        final verifyData = await _jsonStorage.readJsonFile(_capsulesFile);
        if (verifyData != null && verifyData is List) {
          final verifyCount = verifyData.length;
          if (verifyCount == _capsules.length) {
            print('✅ 验证成功：文件中的数量 ($verifyCount) 与内存中的数量 (${_capsules.length}) 一致');
          } else {
            print('⚠️ 警告：文件中的数量 ($verifyCount) 与内存中的数量 (${_capsules.length}) 不一致');
          }
        } else if (verifyData == null && _capsules.isEmpty) {
          print('✅ 验证成功：文件为空，内存列表也为空');
        } else {
          print('⚠️ 警告：验证数据格式不正确或为空');
        }
      } catch (verifyError) {
        print('⚠️ 验证保存结果时出错: $verifyError');
        // 不抛出异常，因为保存可能已经成功
      }
    } catch (e, stackTrace) {
      print('❌ 保存记忆胶囊失败: $e');
      print('❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 获取所有记忆胶囊（强制从文件重新加载）
  Future<List<MemoryCapsule>> getAllCapsules({bool forceReload = false}) async {
    await initialize();
    // 如果需要强制重新加载，或者列表为空，则从文件重新加载
    if (forceReload || _capsules.isEmpty) {
      await _loadCapsules();
    }
    // 确保返回非null列表
    if (_capsules.isEmpty) return [];
    return List.unmodifiable(_capsules);
  }

  /// 根据ID获取记忆胶囊
  Future<MemoryCapsule?> getCapsuleById(int id) async {
    await initialize();
    try {
      return _capsules.firstWhere((capsule) => capsule.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据题目ID获取关联的记忆胶囊
  Future<List<MemoryCapsule>> getCapsulesByQuestionId(int questionId) async {
    await initialize();
    if (_capsules.isEmpty) return [];
    return _capsules.where((capsule) => capsule.questionId == questionId).toList();
  }

  /// 根据年代筛选记忆胶囊
  Future<List<MemoryCapsule>> getCapsulesByEra(String era, {bool forceReload = false}) async {
    await initialize();
    // 如果需要强制重新加载，则从文件重新加载
    if (forceReload) {
      await _loadCapsules();
    }
    if (_capsules.isEmpty) return [];
    return _capsules.where((capsule) => capsule.era == era).toList();
  }

  /// 根据分类筛选记忆胶囊
  Future<List<MemoryCapsule>> getCapsulesByCategory(String category, {bool forceReload = false}) async {
    await initialize();
    // 如果需要强制重新加载，则从文件重新加载
    if (forceReload) {
      await _loadCapsules();
    }
    if (_capsules.isEmpty) return [];
    return _capsules.where((capsule) => capsule.category == category).toList();
  }

  /// 根据标签筛选记忆胶囊
  Future<List<MemoryCapsule>> getCapsulesByTag(String tag) async {
    await initialize();
    if (_capsules.isEmpty) return [];
    return _capsules.where((capsule) => capsule.hasTag(tag)).toList();
  }

  /// 搜索记忆胶囊
  Future<List<MemoryCapsule>> searchCapsules(String keyword) async {
    await initialize();
    if (_capsules.isEmpty) return [];
    final lowerKeyword = keyword.toLowerCase();
    return _capsules.where((capsule) {
      return (capsule.title?.toLowerCase().contains(lowerKeyword) ?? false) ||
          capsule.content.toLowerCase().contains(lowerKeyword) ||
          (capsule.tags.isNotEmpty && capsule.tags.any((tag) => tag.toLowerCase().contains(lowerKeyword)));
    }).toList();
  }

  /// 添加记忆胶囊
  Future<MemoryCapsule> addCapsule(MemoryCapsule capsule) async {
    await initialize();

    // 生成新ID
    final newId = _capsules.isEmpty
        ? 1
        : _capsules.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;

    final newCapsule = capsule.copyWith(id: newId);
    _capsules.add(newCapsule);
    await _saveCapsules();

    print('✅ 添加记忆胶囊: ${newCapsule.getDisplayTitle()}');
    return newCapsule;
  }

  /// 更新记忆胶囊
  Future<void> updateCapsule(MemoryCapsule capsule) async {
    await initialize();

    final index = _capsules.indexWhere((c) => c.id == capsule.id);
    if (index != -1) {
      _capsules[index] = capsule;
      await _saveCapsules();
      print('✅ 更新记忆胶囊: ${capsule.getDisplayTitle()}');
    } else {
      throw Exception('找不到要更新的记忆胶囊');
    }
  }

  /// 从拾光回忆迁移数据到记忆胶囊
  Future<int> migrateFromMemoryRecords() async {
    await initialize();
    
    try {
      print('🔄 开始迁移拾光回忆数据到记忆胶囊...');
      
      // 导入拾光回忆服务
      final memoryService = MemoryService();
      final memoryRecords = await memoryService.getAllMemories();
      
      if (memoryRecords.isEmpty) {
        print('ℹ️ 没有拾光回忆数据需要迁移');
        return 0;
      }
      
      print('📦 找到 ${memoryRecords.length} 条拾光回忆，开始迁移...');
      
      int migratedCount = 0;
      final List<int> recordsToDelete = []; // 记录需要删除的拾光回忆ID
      
      for (final record in memoryRecords) {
        // 检查是否已经迁移过（通过检查是否存在相同内容的记忆胶囊）
        final existingCapsules = await getAllCapsules();
        final alreadyMigrated = existingCapsules.any((c) => 
          c.content == record.content && 
          c.questionId == record.relatedQuestionId &&
          c.memoryDate == record.memoryDate
        );
        
        if (alreadyMigrated) {
          print('⏭️ 跳过已迁移的回忆: ${record.content.substring(0, record.content.length > 30 ? 30 : record.content.length)}...');
          // 标记为需要删除（因为已经迁移过了，即使后来被删除，也不应该再次迁移）
          recordsToDelete.add(record.id);
          continue;
        }
        
        // 转换为记忆胶囊（标题为空，使用内容预览作为显示标题）
        final capsule = MemoryCapsule(
          id: 0, // 会自动生成新ID
          questionId: record.relatedQuestionId,
          title: null, // 快速创建的回忆没有标题
          content: record.content,
          imagePath: null,
          audioPath: null,
          createdAt: record.createTime,
          memoryDate: record.memoryDate,
          tags: record.tags,
          era: record.era,
          category: record.category,
          mood: record.mood,
          location: record.location,
        );
        
        await addCapsule(capsule);
        migratedCount++;
        
        // 标记为需要删除（迁移成功后，从拾光回忆中删除，避免重复迁移）
        recordsToDelete.add(record.id);
      }
      
      // 删除已迁移的拾光回忆，避免重复迁移
      if (recordsToDelete.isNotEmpty) {
        print('🗑️ 删除 ${recordsToDelete.length} 条已迁移的拾光回忆，避免重复迁移...');
        for (final recordId in recordsToDelete) {
          try {
            await memoryService.removeMemory(recordId);
            print('   ✅ 已删除拾光回忆 ID: $recordId');
          } catch (e) {
            print('   ⚠️ 删除拾光回忆失败 ID: $recordId, 错误: $e');
            // 继续删除其他记录，不因单个失败而中断
          }
        }
        print('✅ 已清理 ${recordsToDelete.length} 条拾光回忆');
      }
      
      print('✅ 成功迁移 $migratedCount 条拾光回忆到记忆胶囊');
      return migratedCount;
    } catch (e) {
      print('❌ 迁移拾光回忆数据失败: $e');
      rethrow;
    }
  }

  /// 删除记忆胶囊
  Future<void> deleteCapsule(int id) async {
    await initialize();

    print('🗑️ 开始删除记忆胶囊: $id');
    print('🗑️ 删除前，当前有 ${_capsules.length} 个记忆胶囊');

    final capsule = await getCapsuleById(id);
    if (capsule == null) {
      print('❌ 找不到要删除的记忆胶囊: $id');
      throw Exception('找不到要删除的记忆胶囊');
    }

    // 删除关联的媒体文件
    if (capsule.imagePath != null) {
      try {
        final imageFile = File(capsule.imagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
          print('✅ 已删除图片文件: ${capsule.imagePath}');
        } else {
          print('ℹ️ 图片文件不存在，跳过: ${capsule.imagePath}');
        }
      } catch (e) {
        print('⚠️ 删除图片文件失败: $e');
        // 继续删除，不因为媒体文件删除失败而中断
      }
    }

    if (capsule.audioPath != null) {
      try {
        final audioFile = File(capsule.audioPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
          print('✅ 已删除音频文件: ${capsule.audioPath}');
        } else {
          print('ℹ️ 音频文件不存在，跳过: ${capsule.audioPath}');
        }
      } catch (e) {
        print('⚠️ 删除音频文件失败: $e');
        // 继续删除，不因为媒体文件删除失败而中断
      }
    }

    // 从列表中移除
    final beforeCount = _capsules.length;
    _capsules.removeWhere((c) => c.id == id);
    final afterCount = _capsules.length;
    
    if (beforeCount == afterCount) {
      print('❌ 警告：删除后列表数量未变化，可能未找到要删除的胶囊');
    } else {
      print('✅ 已从内存列表中移除，数量从 $beforeCount 变为 $afterCount');
    }

    // 保存到文件
    try {
      await _saveCapsules();
      print('✅ 已保存到文件，当前有 ${_capsules.length} 个记忆胶囊');
      
      // 验证保存是否成功：重新加载检查
      await _loadCapsules();
      final reloadedCount = _capsules.length;
      if (reloadedCount == afterCount) {
        print('✅ 验证成功：重新加载后数量正确 ($reloadedCount)');
      } else {
        print('⚠️ 警告：重新加载后数量不匹配，期望 $afterCount，实际 $reloadedCount');
      }
    } catch (e) {
      print('❌ 保存记忆胶囊失败: $e');
      print('错误堆栈: ${StackTrace.current}');
      rethrow;
    }

    print('✅ 删除记忆胶囊完成: $id');
  }

  /// 保存图片文件（从临时路径移动到永久存储）
  Future<String?> saveImageFile(String sourcePath) async {
    if (_mediaDirectory == null) {
      await _initializeMediaDirectory();
    }

    if (_mediaDirectory == null) {
      print('⚠️ 无法保存图片：媒体目录未初始化');
      return null;
    }

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('⚠️ 源图片文件不存在: $sourcePath');
        return null;
      }

      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = path.join(_mediaDirectory!.path, fileName);
      final targetFile = File(targetPath);

      // 复制文件
      await sourceFile.copy(targetPath);

      print('✅ 图片已保存: $targetPath');
      return targetPath;
    } catch (e) {
      print('❌ 保存图片失败: $e');
      return null;
    }
  }

  /// 保存音频文件（从临时路径移动到永久存储）
  Future<String?> saveAudioFile(String sourcePath) async {
    if (_mediaDirectory == null) {
      await _initializeMediaDirectory();
    }

    if (_mediaDirectory == null) {
      print('⚠️ 无法保存音频：媒体目录未初始化');
      return null;
    }

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('⚠️ 源音频文件不存在: $sourcePath');
        return null;
      }

      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final targetPath = path.join(_mediaDirectory!.path, fileName);
      final targetFile = File(targetPath);

      // 复制文件
      await sourceFile.copy(targetPath);

      print('✅ 音频已保存: $targetPath');
      return targetPath;
    } catch (e) {
      print('❌ 保存音频失败: $e');
      return null;
    }
  }

  /// 获取媒体文件目录
  Directory? get mediaDirectory => _mediaDirectory;

  /// 获取统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    await initialize();

    final total = _capsules.length;
    final withImage = _capsules.where((c) => c.hasImage).length;
    final withAudio = _capsules.where((c) => c.hasAudio).length;
    final byEra = <String, int>{};
    final byCategory = <String, int>{};

    for (final capsule in _capsules) {
      byEra[capsule.era] = (byEra[capsule.era] ?? 0) + 1;
      byCategory[capsule.category] = (byCategory[capsule.category] ?? 0) + 1;
    }

    return {
      'total': total,
      'withImage': withImage,
      'withAudio': withAudio,
      'byEra': byEra,
      'byCategory': byCategory,
    };
  }
}

