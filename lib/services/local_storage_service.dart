import 'dart:convert';
import '../constants/app_constants.dart';
import 'json_storage_service.dart';

/// 本地存储服务类（使用JSON文件存储）
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  final _storage = JsonStorageService();

  /// 初始化本地存储
  Future<void> initialize() async {
    try {
      await _storage.initialize();
      print('✅ JSON存储服务初始化成功');
    } catch (e) {
      print('❌ JSON存储服务初始化失败: $e');
      // 不抛出异常，允许应用继续运行
    }
  }

  /// 保存字符串
  Future<bool> setString(String key, String value) async {
    try {
      await _storage.updateSetting(key, value);
      return true;
    } catch (e) {
      print('保存字符串失败: $e');
      return false;
    }
  }

  /// 获取字符串
  Future<String?> getString(String key) async {
    try {
      return await _storage.getSetting<String>(key);
    } catch (e) {
      print('获取字符串失败: $e');
      return null;
    }
  }

  /// 保存整数
  Future<bool> setInt(String key, int value) async {
    try {
      await _storage.updateSetting(key, value);
      return true;
    } catch (e) {
      print('保存整数失败: $e');
      return false;
    }
  }

  /// 获取整数
  Future<int?> getInt(String key) async {
    try {
      return await _storage.getSetting<int>(key);
    } catch (e) {
      print('获取整数失败: $e');
      return null;
    }
  }

  /// 保存布尔值
  Future<bool> setBool(String key, bool value) async {
    try {
      await _storage.updateSetting(key, value);
      return true;
    } catch (e) {
      print('保存布尔值失败: $e');
      return false;
    }
  }

  /// 获取布尔值
  Future<bool?> getBool(String key) async {
    try {
      return await _storage.getSetting<bool>(key);
    } catch (e) {
      print('获取布尔值失败: $e');
      return null;
    }
  }

  /// 保存双精度浮点数
  Future<bool> setDouble(String key, double value) async {
    try {
      await _storage.updateSetting(key, value);
      return true;
    } catch (e) {
      print('保存双精度浮点数失败: $e');
      return false;
    }
  }

  /// 获取双精度浮点数
  Future<double?> getDouble(String key) async {
    try {
      return await _storage.getSetting<double>(key);
    } catch (e) {
      print('获取双精度浮点数失败: $e');
      return null;
    }
  }

  /// 保存字符串列表
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      await _storage.updateSetting(key, value);
      return true;
    } catch (e) {
      print('保存字符串列表失败: $e');
      return false;
    }
  }

  /// 获取字符串列表
  Future<List<String>?> getStringList(String key) async {
    try {
      final value = await _storage.getSetting(key);
      if (value == null) return null;
      if (value is List) {
        return value.cast<String>();
      }
      if (value is String) {
        return value.split(',').where((e) => e.isNotEmpty).toList();
      }
      return null;
    } catch (e) {
      print('获取字符串列表失败: $e');
      return null;
    }
  }

  /// 删除指定键
  Future<bool> remove(String key) async {
    try {
      await _storage.updateSetting(key, null);
      return true;
    } catch (e) {
      print('删除键失败: $e');
      return false;
    }
  }

  /// 清除所有数据
  Future<bool> clear() async {
    try {
      // JSON存储服务提供了清除所有数据的方法
      // 这里只清除设置，不删除其他数据
      final settings = await _storage.getAllSettings();
      for (final key in settings.keys) {
        await _storage.updateSetting(key, null);
      }
      return true;
    } catch (e) {
      print('清除所有数据失败: $e');
      return false;
    }
  }

  /// 检查键是否存在
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.getSetting(key);
      return value != null;
    } catch (e) {
      return false;
    }
  }

  /// 获取所有键
  Future<Set<String>> getKeys() async {
    try {
      final settings = await _storage.getAllSettings();
      return settings.keys.toSet();
    } catch (e) {
      return <String>{};
    }
  }

  /// 保存拾光状态
  Future<void> saveTestState(Map<String, dynamic> testState) async {
    final stateStr = jsonEncode(testState);
    await setString('test_state', stateStr);
  }

  /// 获取拾光状态
  Future<Map<String, dynamic>?> getTestState() async {
    final stateStr = await getString('test_state');
    if (stateStr == null) return null;
    
    try {
      return jsonDecode(stateStr) as Map<String, dynamic>;
    } catch (e) {
      print('解析拾光状态失败: $e');
      return null;
    }
  }

  /// 清除拾光状态
  Future<void> clearTestState() async {
    print('🗑️ 清除拾光状态...');
    try {
      await remove('test_state');
      print('🗑️ ✅ 拾光状态已清除');
    } catch (e) {
      print('🗑️ ⚠️ 清除拾光状态失败: $e');
      // 即使失败也继续执行，不影响拾光完成
    }
  }

  // 应用特定的存储方法

  /// 保存用户设置
  Future<void> saveUserSettings({
    bool? voiceEnabled,
    String? voiceSpeed,
    String? commentStyle,
    String? fontSize,
    bool? elderlyMode,
    String? questionSelectionMode,
  }) async {
    print('保存用户设置到本地存储:');
    if (voiceEnabled != null) {
      print('  保存 voiceEnabled: $voiceEnabled');
      final success = await setBool(AppConstants.keyVoiceEnabled, voiceEnabled);
      print('  保存结果: $success');
    }
    if (voiceSpeed != null) {
      print('  保存 voiceSpeed: $voiceSpeed');
      final success = await setString(AppConstants.keyVoiceSpeed, voiceSpeed);
      print('  保存结果: $success');
    }
    if (commentStyle != null) {
      print('  保存 commentStyle: $commentStyle');
      final success = await setString(AppConstants.keyCommentStyle, commentStyle);
      print('  保存结果: $success');
    }
    if (fontSize != null) {
      print('  保存 fontSize: $fontSize');
      final success = await setString(AppConstants.keyFontSize, fontSize);
      print('  保存结果: $success');
    }
    if (elderlyMode != null) {
      print('  保存 elderlyMode: $elderlyMode');
      final success = await setBool(AppConstants.keyElderlyMode, elderlyMode);
      print('  保存结果: $success');
    }
    if (questionSelectionMode != null) {
      print('  保存 questionSelectionMode: $questionSelectionMode');
      final success = await setString('question_selection_mode', questionSelectionMode);
      print('  保存结果: $success');
    }
  }

  /// 获取用户设置
  Future<Map<String, dynamic>> getUserSettings() async {
    final voiceEnabled = await getBool(AppConstants.keyVoiceEnabled) ?? false;
    final voiceSpeed = await getString(AppConstants.keyVoiceSpeed) ?? '中';
    final commentStyle = await getString(AppConstants.keyCommentStyle) ?? '通用版';
    final fontSize = await getString(AppConstants.keyFontSize) ?? '中';
    final elderlyMode = await getBool(AppConstants.keyElderlyMode) ?? false;
    final questionSelectionMode = await getString('question_selection_mode') ?? 'random';
    
    print('从本地存储读取用户设置:');
    print('  voiceEnabled: $voiceEnabled');
    print('  voiceSpeed: $voiceSpeed');
    print('  commentStyle: $commentStyle');
    print('  fontSize: $fontSize');
    print('  elderlyMode: $elderlyMode');
    print('  questionSelectionMode: $questionSelectionMode');
    
    return {
      'voiceEnabled': voiceEnabled,
      'voiceSpeed': voiceSpeed,
      'commentStyle': commentStyle,
      'fontSize': fontSize,
      'elderlyMode': elderlyMode,
      'questionSelectionMode': questionSelectionMode,
    };
  }

  /// 保存首次启动状态
  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await setBool(AppConstants.keyFirstLaunch, isFirstLaunch);
  }

  /// 获取首次启动状态
  Future<bool> isFirstLaunch() async {
    return await getBool(AppConstants.keyFirstLaunch) ?? true;
  }

  /// 保存最后拾光日期
  Future<void> setLastTestDate(DateTime date) async {
    await setString(AppConstants.keyLastTestDate, date.toIso8601String());
  }

  /// 获取最后拾光日期
  Future<DateTime?> getLastTestDate() async {
    final dateString = await getString(AppConstants.keyLastTestDate);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  /// 保存应用版本
  Future<void> setAppVersion(String version) async {
    await setString('app_version', version);
  }

  /// 获取应用版本
  Future<String?> getAppVersion() async {
    return await getString('app_version');
  }

  /// 检查是否需要显示更新提示
  Future<bool> shouldShowUpdatePrompt() async {
    final currentVersion = AppConstants.appVersion;
    final savedVersion = await getAppVersion();
    
    if (savedVersion == null || savedVersion != currentVersion) {
      await setAppVersion(currentVersion);
      return true;
    }
    
    return false;
  }

  /// 保存题库更新状态
  Future<void> setQuestionUpdateStatus(bool hasUpdate) async {
    await setBool('question_update_status', hasUpdate);
  }

  /// 获取题库更新状态
  Future<bool> getQuestionUpdateStatus() async {
    return await getBool('question_update_status') ?? false;
  }

  /// 保存连续拾光天数
  Future<void> setConsecutiveTestDays(int days) async {
    await setInt('consecutive_test_days', days);
  }

  /// 获取连续拾光天数
  Future<int> getConsecutiveTestDays() async {
    return await getInt('consecutive_test_days') ?? 0;
  }

  /// 保存总拾光次数
  Future<void> setTotalTestCount(int count) async {
    await setInt('total_test_count', count);
  }

  /// 获取总拾光次数
  Future<int> getTotalTestCount() async {
    return await getInt('total_test_count') ?? 0;
  }

  /// 增加拾光次数
  Future<void> incrementTestCount() async {
    final currentCount = await getTotalTestCount();
    await setTotalTestCount(currentCount + 1);
  }

  /// 重置统计数据
  Future<void> resetStatistics() async {
    await remove('consecutive_test_days');
    await remove('total_test_count');
    await remove(AppConstants.keyLastTestDate);
  }

  /// 保存定制题目配置
  Future<void> saveQuizConfig({
    required int questionCount,
    required List<String> categories,
    required List<String> eras,
    required List<String> difficulties,
    required String selectionMode,
  }) async {
    final config = {
      'questionCount': questionCount,
      'categories': categories,
      'eras': eras,
      'difficulties': difficulties,
      'selectionMode': selectionMode,
    };
    await setString('quiz_config', jsonEncode(config));
    print('✅ 定制配置已保存: $config');
  }

  /// 获取定制题目配置
  Future<Map<String, dynamic>?> getQuizConfig() async {
    final configStr = await getString('quiz_config');
    if (configStr == null) {
      print('📋 未找到保存的定制配置');
      return null;
    }
    try {
      final config = jsonDecode(configStr) as Map<String, dynamic>;
      print('📋 读取到定制配置: $config');
      return config;
    } catch (e) {
      print('❌ 解析定制配置失败: $e');
      return null;
    }
  }

  /// 检查是否有保存的定制配置
  Future<bool> hasQuizConfig() async {
    final config = await getQuizConfig();
    return config != null;
  }
}
