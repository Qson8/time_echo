import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/memory_capsule.dart';
import 'json_storage_service.dart';

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
          print('⚠️ 获取应用文档目录失败: $e');
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
          print('⚠️ 获取临时目录失败: $e');
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
      await _jsonStorage.writeJsonFile(_capsulesFile, data);
      print('✅ 保存了 ${_capsules.length} 个记忆胶囊');
    } catch (e) {
      print('❌ 保存记忆胶囊失败: $e');
      rethrow;
    }
  }

  /// 获取所有记忆胶囊
  Future<List<MemoryCapsule>> getAllCapsules() async {
    await initialize();
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
  Future<List<MemoryCapsule>> getCapsulesByEra(String era) async {
    await initialize();
    if (_capsules.isEmpty) return [];
    return _capsules.where((capsule) => capsule.era == era).toList();
  }

  /// 根据分类筛选记忆胶囊
  Future<List<MemoryCapsule>> getCapsulesByCategory(String category) async {
    await initialize();
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
      return capsule.title.toLowerCase().contains(lowerKeyword) ||
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

    print('✅ 添加记忆胶囊: ${newCapsule.title}');
    return newCapsule;
  }

  /// 更新记忆胶囊
  Future<void> updateCapsule(MemoryCapsule capsule) async {
    await initialize();

    final index = _capsules.indexWhere((c) => c.id == capsule.id);
    if (index != -1) {
      _capsules[index] = capsule;
      await _saveCapsules();
      print('✅ 更新记忆胶囊: ${capsule.title}');
    } else {
      throw Exception('找不到要更新的记忆胶囊');
    }
  }

  /// 删除记忆胶囊
  Future<void> deleteCapsule(int id) async {
    await initialize();

    final capsule = await getCapsuleById(id);
    if (capsule == null) {
      throw Exception('找不到要删除的记忆胶囊');
    }

    // 删除关联的媒体文件
    if (capsule.imagePath != null) {
      try {
        final imageFile = File(capsule.imagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (e) {
        print('⚠️ 删除图片文件失败: $e');
      }
    }

    if (capsule.audioPath != null) {
      try {
        final audioFile = File(capsule.audioPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } catch (e) {
        print('⚠️ 删除音频文件失败: $e');
      }
    }

    _capsules.removeWhere((c) => c.id == id);
    await _saveCapsules();

    print('✅ 删除记忆胶囊: $id');
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

