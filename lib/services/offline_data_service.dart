import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/test_record.dart';
import '../models/echo_collection.dart';
import '../models/echo_achievement.dart';

/// 离线数据管理服务
class OfflineDataService {
  static final OfflineDataService _instance = OfflineDataService._internal();
  factory OfflineDataService() => _instance;
  OfflineDataService._internal();

  SharedPreferences? _prefs;
  Directory? _dataDirectory;
  final Map<String, dynamic> _offlineData = {};

  /// 初始化服务
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _setupDataDirectory();
    await _loadOfflineData();
  }

  /// 设置数据目录
  Future<void> _setupDataDirectory() async {
    // 鸿蒙平台可能不支持path_provider，简化处理
    // 使用SharedPreferences作为主要存储，文件存储作为辅助
    print('离线数据服务初始化完成（使用SharedPreferences）');
  }

  /// 加载离线数据
  Future<void> _loadOfflineData() async {
    if (_prefs == null) return;
    
    final offlineDataJson = _prefs!.getString('offline_data');
    if (offlineDataJson != null) {
      try {
        final data = jsonDecode(offlineDataJson) as Map<String, dynamic>;
        _offlineData.addAll(data);
      } catch (e) {
        print('加载离线数据失败: $e');
      }
    }
  }

  /// 保存离线数据
  Future<void> _saveOfflineData() async {
    if (_prefs == null) return;
    
    try {
      final offlineDataJson = jsonEncode(_offlineData);
      await _prefs!.setString('offline_data', offlineDataJson);
    } catch (e) {
      print('保存离线数据失败: $e');
    }
  }

  /// 备份数据到文件
  Future<bool> backupDataToFile() async {
    await initialize();
    
    try {
      final backupData = {
        'questions': _offlineData['questions'] ?? [],
        'testRecords': _offlineData['testRecords'] ?? [],
        'collections': _offlineData['collections'] ?? [],
        'achievements': _offlineData['achievements'] ?? [],
        'settings': _offlineData['settings'] ?? {},
        'backupTime': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0.0',
      };
      
      final backupFile = File('${_dataDirectory!.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await backupFile.writeAsString(jsonEncode(backupData));
      
      return true;
    } catch (e) {
      print('备份数据失败: $e');
      return false;
    }
  }

  /// 从文件恢复数据
  Future<bool> restoreDataFromFile(String filePath) async {
    await initialize();
    
    try {
      final backupFile = File(filePath);
      if (!await backupFile.exists()) {
        return false;
      }
      
      final backupDataJson = await backupFile.readAsString();
      final backupData = jsonDecode(backupDataJson) as Map<String, dynamic>;
      
      // 验证备份数据格式
      if (!_validateBackupData(backupData)) {
        return false;
      }
      
      // 恢复数据
      _offlineData.clear();
      _offlineData.addAll(backupData);
      await _saveOfflineData();
      
      return true;
    } catch (e) {
      print('恢复数据失败: $e');
      return false;
    }
  }

  /// 验证备份数据格式
  bool _validateBackupData(Map<String, dynamic> data) {
    return data.containsKey('questions') &&
           data.containsKey('testRecords') &&
           data.containsKey('collections') &&
           data.containsKey('achievements') &&
           data.containsKey('backupTime') &&
           data.containsKey('version');
  }

  /// 获取备份文件列表
  Future<List<Map<String, dynamic>>> getBackupFiles() async {
    await initialize();
    
    final backupFiles = <Map<String, dynamic>>[];
    
    if (await _dataDirectory!.exists()) {
      final files = await _dataDirectory!.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.json') && file.path.contains('backup_')) {
          try {
            final content = await file.readAsString();
            final data = jsonDecode(content) as Map<String, dynamic>;
            
            backupFiles.add({
              'filePath': file.path,
              'fileName': file.path.split('/').last,
              'backupTime': data['backupTime'] as int,
              'version': data['version'] as String,
              'fileSize': await file.length(),
            });
          } catch (e) {
            print('读取备份文件失败: ${file.path}, 错误: $e');
          }
        }
      }
    }
    
    // 按备份时间排序
    backupFiles.sort((a, b) => (b['backupTime'] as int).compareTo(a['backupTime'] as int));
    
    return backupFiles;
  }

  /// 删除备份文件
  Future<bool> deleteBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除备份文件失败: $e');
      return false;
    }
  }

  /// 压缩数据
  Future<String?> compressData() async {
    await initialize();
    
    try {
      final dataToCompress = {
        'questions': _offlineData['questions'] ?? [],
        'testRecords': _offlineData['testRecords'] ?? [],
        'collections': _offlineData['collections'] ?? [],
        'achievements': _offlineData['achievements'] ?? [],
        'settings': _offlineData['settings'] ?? {},
        'compressTime': DateTime.now().millisecondsSinceEpoch,
      };
      
      final compressedData = jsonEncode(dataToCompress);
      final compressedFile = File('${_dataDirectory!.path}/compressed_data_${DateTime.now().millisecondsSinceEpoch}.json');
      await compressedFile.writeAsString(compressedData);
      
      return compressedFile.path;
    } catch (e) {
      print('压缩数据失败: $e');
      return null;
    }
  }

  /// 解压数据
  Future<bool> decompressData(String filePath) async {
    await initialize();
    
    try {
      final compressedFile = File(filePath);
      if (!await compressedFile.exists()) {
        return false;
      }
      
      final compressedData = await compressedFile.readAsString();
      final data = jsonDecode(compressedData) as Map<String, dynamic>;
      
      // 合并数据
      for (final entry in data.entries) {
        if (entry.key != 'compressTime') {
          _offlineData[entry.key] = entry.value;
        }
      }
      
      await _saveOfflineData();
      return true;
    } catch (e) {
      print('解压数据失败: $e');
      return false;
    }
  }

  /// 获取数据统计
  Map<String, dynamic> getDataStats() {
    return {
      'questions': (_offlineData['questions'] as List?)?.length ?? 0,
      'testRecords': (_offlineData['testRecords'] as List?)?.length ?? 0,
      'collections': (_offlineData['collections'] as List?)?.length ?? 0,
      'achievements': (_offlineData['achievements'] as List?)?.length ?? 0,
      'lastUpdate': _offlineData['lastUpdate'] as int? ?? 0,
    };
  }

  /// 清理过期数据
  Future<void> cleanupExpiredData({Duration? retentionPeriod}) async {
    await initialize();
    
    final retention = retentionPeriod ?? const Duration(days: 30);
    final cutoffTime = DateTime.now().subtract(retention).millisecondsSinceEpoch;
    
    // 清理过期的测试记录
    final testRecords = _offlineData['testRecords'] as List? ?? [];
    final filteredRecords = testRecords.where((record) {
      final testTime = record['testTime'] as int? ?? 0;
      return testTime > cutoffTime;
    }).toList();
    
    _offlineData['testRecords'] = filteredRecords;
    await _saveOfflineData();
  }

  /// 导出数据
  Future<String?> exportData() async {
    await initialize();
    
    try {
      final exportData = {
        'questions': _offlineData['questions'] ?? [],
        'testRecords': _offlineData['testRecords'] ?? [],
        'collections': _offlineData['collections'] ?? [],
        'achievements': _offlineData['achievements'] ?? [],
        'settings': _offlineData['settings'] ?? {},
        'exportTime': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0.0',
      };
      
      final exportFile = File('${_dataDirectory!.path}/export_${DateTime.now().millisecondsSinceEpoch}.json');
      await exportFile.writeAsString(jsonEncode(exportData));
      
      return exportFile.path;
    } catch (e) {
      print('导出数据失败: $e');
      return null;
    }
  }

  /// 导入数据
  Future<bool> importData(String filePath) async {
    await initialize();
    
    try {
      final importFile = File(filePath);
      if (!await importFile.exists()) {
        return false;
      }
      
      final importDataJson = await importFile.readAsString();
      final importData = jsonDecode(importDataJson) as Map<String, dynamic>;
      
      // 验证导入数据格式
      if (!_validateBackupData(importData)) {
        return false;
      }
      
      // 合并数据
      for (final entry in importData.entries) {
        if (entry.key != 'exportTime' && entry.key != 'version') {
          if (entry.value is List) {
            final existingList = _offlineData[entry.key] as List? ?? [];
            final newList = List<dynamic>.from(entry.value);
            
            // 去重合并
            for (final item in newList) {
              if (!existingList.any((existing) => existing['id'] == item['id'])) {
                existingList.add(item);
              }
            }
            
            _offlineData[entry.key] = existingList;
          } else {
            _offlineData[entry.key] = entry.value;
          }
        }
      }
      
      _offlineData['lastUpdate'] = DateTime.now().millisecondsSinceEpoch;
      await _saveOfflineData();
      
      return true;
    } catch (e) {
      print('导入数据失败: $e');
      return false;
    }
  }

  /// 同步数据
  Future<bool> syncData() async {
    await initialize();
    
    try {
      // 这里可以实现数据同步逻辑
      // 例如：从服务器获取最新数据，合并本地数据
      
      _offlineData['lastSync'] = DateTime.now().millisecondsSinceEpoch;
      await _saveOfflineData();
      
      return true;
    } catch (e) {
      print('同步数据失败: $e');
      return false;
    }
  }

  /// 检查数据完整性
  Map<String, dynamic> checkDataIntegrity() {
    final issues = <String>[];
    
    // 检查题目数据
    final questions = _offlineData['questions'] as List? ?? [];
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i] as Map<String, dynamic>;
      if (question['id'] == null || question['content'] == null) {
        issues.add('题目 $i 数据不完整');
      }
    }
    
    // 检查测试记录
    final testRecords = _offlineData['testRecords'] as List? ?? [];
    for (int i = 0; i < testRecords.length; i++) {
      final record = testRecords[i] as Map<String, dynamic>;
      if (record['id'] == null || record['testTime'] == null) {
        issues.add('测试记录 $i 数据不完整');
      }
    }
    
    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'totalIssues': issues.length,
    };
  }

  /// 修复数据
  Future<bool> repairData() async {
    await initialize();
    
    try {
      final integrityCheck = checkDataIntegrity();
      
      if (integrityCheck['isValid'] as bool) {
        return true;
      }
      
      // 修复数据
      final questions = _offlineData['questions'] as List? ?? [];
      final repairedQuestions = <Map<String, dynamic>>[];
      
      for (final question in questions) {
        if (question is Map<String, dynamic>) {
          // 确保必要字段存在
          final repairedQuestion = Map<String, dynamic>.from(question);
          repairedQuestion['id'] ??= DateTime.now().millisecondsSinceEpoch.toString();
          repairedQuestion['content'] ??= '题目内容缺失';
          repairedQuestion['options'] ??= ['A', 'B', 'C', 'D'];
          repairedQuestion['correctAnswer'] ??= 'A';
          
          repairedQuestions.add(repairedQuestion);
        }
      }
      
      _offlineData['questions'] = repairedQuestions;
      await _saveOfflineData();
      
      return true;
    } catch (e) {
      print('修复数据失败: $e');
      return false;
    }
  }
}
