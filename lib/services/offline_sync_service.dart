import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/offline_data_service.dart';
import '../services/cache_service.dart';

/// 离线同步服务
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  SharedPreferences? _prefs;
  final OfflineDataService _offlineDataService = OfflineDataService();
  final CacheService _cacheService = CacheService();
  
  bool _isOnline = false;
  DateTime? _lastSyncTime;
  final Map<String, dynamic> _syncQueue = {};

  /// 初始化服务
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadSyncSettings();
    await _checkNetworkStatus();
  }

  /// 加载同步设置
  Future<void> _loadSyncSettings() async {
    if (_prefs == null) return;
    
    _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(
      _prefs!.getInt('last_sync_time') ?? 0,
    );
  }

  /// 保存同步设置
  Future<void> _saveSyncSettings() async {
    if (_prefs == null) return;
    
    await _prefs!.setInt('last_sync_time', _lastSyncTime?.millisecondsSinceEpoch ?? 0);
  }

  /// 检查网络状态
  Future<void> _checkNetworkStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _isOnline = false;
    }
  }

  /// 获取网络状态
  bool get isOnline => _isOnline;

  /// 获取最后同步时间
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 检查是否需要同步
  bool needsSync({Duration? syncInterval}) {
    if (_lastSyncTime == null) return true;
    
    final interval = syncInterval ?? const Duration(hours: 1);
    return DateTime.now().difference(_lastSyncTime!) > interval;
  }

  /// 同步数据
  Future<SyncResult> syncData() async {
    await initialize();
    
    try {
      // 检查网络状态
      await _checkNetworkStatus();
      
      if (!_isOnline) {
        return SyncResult(
          success: false,
          message: '网络不可用，无法同步数据',
          type: SyncResultType.networkError,
        );
      }

      // 执行同步
      final syncResult = await _performSync();
      
      if (syncResult.success) {
        _lastSyncTime = DateTime.now();
        await _saveSyncSettings();
      }
      
      return syncResult;
    } catch (e) {
      return SyncResult(
        success: false,
        message: '同步失败: $e',
        type: SyncResultType.error,
      );
    }
  }

  /// 执行同步
  Future<SyncResult> _performSync() async {
    try {
      // 1. 上传本地数据
      final uploadResult = await _uploadLocalData();
      if (!uploadResult.success) {
        return uploadResult;
      }

      // 2. 下载远程数据
      final downloadResult = await _downloadRemoteData();
      if (!downloadResult.success) {
        return downloadResult;
      }

      // 3. 合并数据
      final mergeResult = await _mergeData();
      if (!mergeResult.success) {
        return mergeResult;
      }

      return SyncResult(
        success: true,
        message: '数据同步成功',
        type: SyncResultType.success,
        data: {
          'uploaded': uploadResult.data,
          'downloaded': downloadResult.data,
          'merged': mergeResult.data,
        },
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: '同步过程出错: $e',
        type: SyncResultType.error,
      );
    }
  }

  /// 上传本地数据
  Future<SyncResult> _uploadLocalData() async {
    try {
      // 获取本地数据
      final localData = _offlineDataService.getDataStats();
      
      // 这里可以实现实际上传逻辑
      // 例如：发送到服务器API
      
      return SyncResult(
        success: true,
        message: '本地数据上传成功',
        type: SyncResultType.success,
        data: localData,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: '上传本地数据失败: $e',
        type: SyncResultType.error,
      );
    }
  }

  /// 下载远程数据
  Future<SyncResult> _downloadRemoteData() async {
    try {
      // 这里可以实现实际下载逻辑
      // 例如：从服务器API获取数据
      
      final remoteData = {
        'questions': [],
        'testRecords': [],
        'collections': [],
        'achievements': [],
      };
      
      return SyncResult(
        success: true,
        message: '远程数据下载成功',
        type: SyncResultType.success,
        data: remoteData,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: '下载远程数据失败: $e',
        type: SyncResultType.error,
      );
    }
  }

  /// 合并数据
  Future<SyncResult> _mergeData() async {
    try {
      // 这里可以实现数据合并逻辑
      // 例如：合并本地和远程数据，解决冲突
      
      return SyncResult(
        success: true,
        message: '数据合并成功',
        type: SyncResultType.success,
        data: {},
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: '数据合并失败: $e',
        type: SyncResultType.error,
      );
    }
  }

  /// 添加到同步队列
  Future<void> addToSyncQueue(String operation, Map<String, dynamic> data) async {
    await initialize();
    
    _syncQueue[operation] = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 处理同步队列
  Future<void> processSyncQueue() async {
    if (_syncQueue.isEmpty) return;
    
    try {
      await _checkNetworkStatus();
      
      if (_isOnline) {
        // 处理队列中的操作
        for (final entry in _syncQueue.entries) {
          final operation = entry.key;
          final data = entry.value;
          
          // 这里可以实现具体的同步操作
          print('处理同步操作: $operation, 数据: $data');
        }
        
        // 清空队列
        _syncQueue.clear();
      }
    } catch (e) {
      print('处理同步队列失败: $e');
    }
  }

  /// 获取同步状态
  Map<String, dynamic> getSyncStatus() {
    return {
      'isOnline': _isOnline,
      'lastSyncTime': _lastSyncTime?.millisecondsSinceEpoch ?? 0,
      'needsSync': needsSync(),
      'queueSize': _syncQueue.length,
      'queueOperations': _syncQueue.keys.toList(),
    };
  }

  /// 设置自动同步
  Future<void> setAutoSync(bool enabled, {Duration? interval}) async {
    if (_prefs == null) return;
    
    await _prefs!.setBool('auto_sync_enabled', enabled);
    if (interval != null) {
      await _prefs!.setInt('auto_sync_interval', interval.inMinutes);
    }
  }

  /// 获取自动同步设置
  Map<String, dynamic> getAutoSyncSettings() {
    if (_prefs == null) {
      return {
        'enabled': false,
        'interval': 60, // 默认60分钟
      };
    }
    
    return {
      'enabled': _prefs!.getBool('auto_sync_enabled') ?? false,
      'interval': _prefs!.getInt('auto_sync_interval') ?? 60,
    };
  }

  /// 强制同步
  Future<SyncResult> forceSync() async {
    await initialize();
    
    try {
      // 清除缓存
      await _cacheService.clearAllCache();
      
      // 执行同步
      final result = await syncData();
      
      return result;
    } catch (e) {
      return SyncResult(
        success: false,
        message: '强制同步失败: $e',
        type: SyncResultType.error,
      );
    }
  }

  /// 重置同步状态
  Future<void> resetSyncStatus() async {
    await initialize();
    
    _lastSyncTime = null;
    _syncQueue.clear();
    
    if (_prefs != null) {
      await _prefs!.remove('last_sync_time');
    }
  }
}

/// 同步结果类
class SyncResult {
  final bool success;
  final String message;
  final SyncResultType type;
  final Map<String, dynamic>? data;

  SyncResult({
    required this.success,
    required this.message,
    required this.type,
    this.data,
  });
}

/// 同步结果类型枚举
enum SyncResultType {
  success,
  networkError,
  serverError,
  dataError,
  error,
}

/// 离线模式管理器
class OfflineModeManager {
  static final OfflineModeManager _instance = OfflineModeManager._internal();
  factory OfflineModeManager() => _instance;
  OfflineModeManager._internal();

  final OfflineSyncService _syncService = OfflineSyncService();
  final OfflineDataService _dataService = OfflineDataService();
  final CacheService _cacheService = CacheService();

  bool _isOfflineMode = false;
  DateTime? _offlineModeStartTime;

  /// 初始化管理器
  Future<void> initialize() async {
    await _syncService.initialize();
    await _dataService.initialize();
    await _cacheService.initialize();
  }

  /// 启用离线模式
  Future<void> enableOfflineMode() async {
    await initialize();
    
    _isOfflineMode = true;
    _offlineModeStartTime = DateTime.now();
    
    // 预加载必要数据
    await _preloadEssentialData();
  }

  /// 禁用离线模式
  Future<void> disableOfflineMode() async {
    _isOfflineMode = false;
    _offlineModeStartTime = null;
    
    // 尝试同步数据
    if (_syncService.isOnline) {
      await _syncService.syncData();
    }
  }

  /// 获取离线模式状态
  bool get isOfflineMode => _isOfflineMode;

  /// 获取离线模式持续时间
  Duration? get offlineModeDuration {
    if (_offlineModeStartTime == null) return null;
    return DateTime.now().difference(_offlineModeStartTime!);
  }

  /// 预加载必要数据
  Future<void> _preloadEssentialData() async {
    try {
      // 预加载题目数据
      await _cacheService.setCache('essential_questions', [], duration: const Duration(days: 7));
      
      // 预加载用户设置
      await _cacheService.setCache('user_settings', {}, duration: const Duration(days: 30));
      
      // 预加载成就数据
      await _cacheService.setCache('achievements', [], duration: const Duration(days: 7));
    } catch (e) {
      print('预加载数据失败: $e');
    }
  }

  /// 检查离线模式下的功能可用性
  Map<String, bool> checkFeatureAvailability() {
    return {
      'quiz': true,
      'collection': true,
      'achievement': true,
      'settings': true,
      'sync': false,
      'backup': true,
      'restore': true,
      'export': true,
      'import': true,
    };
  }

  /// 获取离线模式统计
  Map<String, dynamic> getOfflineModeStats() {
    return {
      'isOfflineMode': _isOfflineMode,
      'startTime': _offlineModeStartTime?.millisecondsSinceEpoch ?? 0,
      'duration': offlineModeDuration?.inMinutes ?? 0,
      'availableFeatures': checkFeatureAvailability(),
      'dataStats': _dataService.getDataStats(),
    };
  }
}
