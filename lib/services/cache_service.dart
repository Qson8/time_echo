import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// 数据缓存服务
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _defaultCacheDuration = const Duration(hours: 1);

  /// 初始化缓存服务
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 设置缓存
  Future<void> setCache(String key, dynamic value, {Duration? duration}) async {
    await initialize();
    
    final cacheDuration = duration ?? _defaultCacheDuration;
    final expiryTime = DateTime.now().add(cacheDuration);
    
    // 内存缓存
    _memoryCache[key] = value;
    _cacheTimestamps[key] = expiryTime;
    
    // 持久化缓存
    if (_prefs != null) {
      final cacheData = {
        'value': value,
        'expiry': expiryTime.millisecondsSinceEpoch,
      };
      await _prefs!.setString('cache_$key', jsonEncode(cacheData));
    }
  }

  /// 获取缓存
  Future<T?> getCache<T>(String key) async {
    await initialize();
    
    // 检查内存缓存
    if (_memoryCache.containsKey(key)) {
      final expiryTime = _cacheTimestamps[key];
      if (expiryTime != null && DateTime.now().isBefore(expiryTime)) {
        return _memoryCache[key] as T?;
      } else {
        // 缓存过期，清除
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
    
    // 检查持久化缓存
    if (_prefs != null) {
      final cacheString = _prefs!.getString('cache_$key');
      if (cacheString != null) {
        try {
          final cacheData = jsonDecode(cacheString);
          final expiryTime = DateTime.fromMillisecondsSinceEpoch(cacheData['expiry']);
          
          if (DateTime.now().isBefore(expiryTime)) {
            final value = cacheData['value'];
            // 更新内存缓存
            _memoryCache[key] = value;
            _cacheTimestamps[key] = expiryTime;
            return value as T?;
          } else {
            // 缓存过期，清除
            await _prefs!.remove('cache_$key');
          }
        } catch (e) {
          print('解析缓存数据失败: $e');
          await _prefs!.remove('cache_$key');
        }
      }
    }
    
    return null;
  }

  /// 清除指定缓存
  Future<void> removeCache(String key) async {
    await initialize();
    
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    
    if (_prefs != null) {
      await _prefs!.remove('cache_$key');
    }
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    await initialize();
    
    _memoryCache.clear();
    _cacheTimestamps.clear();
    
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          await _prefs!.remove(key);
        }
      }
    }
  }

  /// 清除过期缓存
  Future<void> clearExpiredCache() async {
    await initialize();
    
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    // 清除内存中的过期缓存
    for (final entry in _cacheTimestamps.entries) {
      if (now.isAfter(entry.value)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    // 清除持久化中的过期缓存
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          final cacheString = _prefs!.getString(key);
          if (cacheString != null) {
            try {
              final cacheData = jsonDecode(cacheString);
              final expiryTime = DateTime.fromMillisecondsSinceEpoch(cacheData['expiry']);
              if (now.isAfter(expiryTime)) {
                await _prefs!.remove(key);
              }
            } catch (e) {
              await _prefs!.remove(key);
            }
          }
        }
      }
    }
  }

  /// 获取缓存大小
  Future<int> getCacheSize() async {
    await initialize();
    
    int size = 0;
    
    // 计算内存缓存大小
    for (final value in _memoryCache.values) {
      size += value.toString().length;
    }
    
    // 计算持久化缓存大小
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          final value = _prefs!.getString(key);
          if (value != null) {
            size += value.length;
          }
        }
      }
    }
    
    return size;
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    await initialize();
    
    int memoryCacheCount = _memoryCache.length;
    int persistentCacheCount = 0;
    int totalSize = 0;
    
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          persistentCacheCount++;
          final value = _prefs!.getString(key);
          if (value != null) {
            totalSize += value.length;
          }
        }
      }
    }
    
    return {
      'memoryCacheCount': memoryCacheCount,
      'persistentCacheCount': persistentCacheCount,
      'totalSize': totalSize,
      'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
    };
  }
}

/// 文件缓存服务
class FileCacheService {
  static final FileCacheService _instance = FileCacheService._internal();
  factory FileCacheService() => _instance;
  FileCacheService._internal();

  Directory? _cacheDirectory;
  final Map<String, DateTime> _fileTimestamps = {};

  /// 初始化文件缓存服务
  Future<void> initialize() async {
    if (_cacheDirectory == null) {
      // 鸿蒙平台可能不支持path_provider，使用临时目录
      final tempDir = Directory.systemTemp;
      _cacheDirectory = Directory('${tempDir.path}/cache');
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
    }
  }

  /// 缓存文件
  Future<void> cacheFile(String key, List<int> data, {Duration? duration}) async {
    await initialize();
    
    final cacheDuration = duration ?? const Duration(days: 7);
    final expiryTime = DateTime.now().add(cacheDuration);
    
    final file = File('${_cacheDirectory!.path}/$key');
    await file.writeAsBytes(data);
    
    _fileTimestamps[key] = expiryTime;
    
    // 保存时间戳
    final timestampFile = File('${_cacheDirectory!.path}/${key}.timestamp');
    await timestampFile.writeAsString(expiryTime.millisecondsSinceEpoch.toString());
  }

  /// 获取缓存文件
  Future<List<int>?> getCachedFile(String key) async {
    await initialize();
    
    final file = File('${_cacheDirectory!.path}/$key');
    if (!await file.exists()) {
      return null;
    }
    
    // 检查是否过期
    final timestampFile = File('${_cacheDirectory!.path}/${key}.timestamp');
    if (await timestampFile.exists()) {
      try {
        final timestampString = await timestampFile.readAsString();
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestampString));
        
        if (DateTime.now().isAfter(expiryTime)) {
          // 文件过期，删除
          await file.delete();
          await timestampFile.delete();
          _fileTimestamps.remove(key);
          return null;
        }
      } catch (e) {
        // 时间戳文件损坏，删除文件
        await file.delete();
        await timestampFile.delete();
        _fileTimestamps.remove(key);
        return null;
      }
    }
    
    return await file.readAsBytes();
  }

  /// 删除缓存文件
  Future<void> removeCachedFile(String key) async {
    await initialize();
    
    final file = File('${_cacheDirectory!.path}/$key');
    final timestampFile = File('${_cacheDirectory!.path}/${key}.timestamp');
    
    if (await file.exists()) {
      await file.delete();
    }
    if (await timestampFile.exists()) {
      await timestampFile.delete();
    }
    
    _fileTimestamps.remove(key);
  }

  /// 清除所有缓存文件
  Future<void> clearAllCachedFiles() async {
    await initialize();
    
    if (await _cacheDirectory!.exists()) {
      await _cacheDirectory!.delete(recursive: true);
      await _cacheDirectory!.create(recursive: true);
    }
    
    _fileTimestamps.clear();
  }

  /// 清除过期缓存文件
  Future<void> clearExpiredCachedFiles() async {
    await initialize();
    
    if (!await _cacheDirectory!.exists()) return;
    
    final files = await _cacheDirectory!.list().toList();
    final now = DateTime.now();
    
    for (final file in files) {
      if (file is File && !file.path.endsWith('.timestamp')) {
        final key = file.path.split('/').last;
        final timestampFile = File('${file.path}.timestamp');
        
        if (await timestampFile.exists()) {
          try {
            final timestampString = await timestampFile.readAsString();
            final expiryTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestampString));
            
            if (now.isAfter(expiryTime)) {
              await file.delete();
              await timestampFile.delete();
              _fileTimestamps.remove(key);
            }
          } catch (e) {
            // 时间戳文件损坏，删除文件
            await file.delete();
            await timestampFile.delete();
            _fileTimestamps.remove(key);
          }
        }
      }
    }
  }

  /// 获取缓存文件统计信息
  Future<Map<String, dynamic>> getCacheFileStats() async {
    await initialize();
    
    int fileCount = 0;
    int totalSize = 0;
    
    if (await _cacheDirectory!.exists()) {
      final files = await _cacheDirectory!.list().toList();
      
      for (final file in files) {
        if (file is File && !file.path.endsWith('.timestamp')) {
          fileCount++;
          totalSize += await file.length();
        }
      }
    }
    
    return {
      'fileCount': fileCount,
      'totalSize': totalSize,
      'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
    };
  }
}

/// 网络缓存服务
class NetworkCacheService {
  static final NetworkCacheService _instance = NetworkCacheService._internal();
  factory NetworkCacheService() => _instance;
  NetworkCacheService._internal();

  final CacheService _cacheService = CacheService();
  final Duration _defaultCacheDuration = const Duration(hours: 1);

  /// 缓存网络请求结果
  Future<void> cacheNetworkResult(String url, dynamic data, {Duration? duration}) async {
    final cacheKey = 'network_${Uri.encodeComponent(url)}';
    await _cacheService.setCache(cacheKey, data, duration: duration ?? _defaultCacheDuration);
  }

  /// 获取缓存的网络请求结果
  Future<T?> getCachedNetworkResult<T>(String url) async {
    final cacheKey = 'network_${Uri.encodeComponent(url)}';
    return await _cacheService.getCache<T>(cacheKey);
  }

  /// 清除网络缓存
  Future<void> clearNetworkCache() async {
    // 这里可以实现更精确的清除逻辑
    await _cacheService.clearAllCache();
  }
}
