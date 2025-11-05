import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 个性化设置服务
class PersonalizationService {
  static final PersonalizationService _instance = PersonalizationService._internal();
  factory PersonalizationService() => _instance;
  PersonalizationService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _settings = {};

  /// 初始化服务
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    if (_prefs == null) return;
    
    final settingsJson = _prefs!.getString('personalization_settings');
    if (settingsJson != null) {
      try {
        final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings.addAll(settings);
      } catch (e) {
        print('加载个性化设置失败: $e');
      }
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    if (_prefs == null) return;
    
    try {
      final settingsJson = jsonEncode(_settings);
      await _prefs!.setString('personalization_settings', settingsJson);
    } catch (e) {
      print('保存个性化设置失败: $e');
    }
  }

  /// 设置主题颜色
  Future<void> setThemeColor(String colorName, int colorValue) async {
    await initialize();
    _settings['theme_color'] = {
      'name': colorName,
      'value': colorValue,
    };
    await _saveSettings();
  }

  /// 获取主题颜色
  Map<String, dynamic>? getThemeColor() {
    return _settings['theme_color'];
  }

  /// 设置字体样式
  Future<void> setFontStyle(String fontFamily) async {
    await initialize();
    _settings['font_style'] = fontFamily;
    await _saveSettings();
  }

  /// 获取字体样式
  String getFontStyle() {
    return _settings['font_style'] ?? 'default';
  }

  /// 设置动画偏好
  Future<void> setAnimationPreference(bool enabled) async {
    await initialize();
    _settings['animation_enabled'] = enabled;
    await _saveSettings();
  }

  /// 获取动画偏好
  bool getAnimationPreference() {
    return _settings['animation_enabled'] ?? true;
  }

  /// 设置音效偏好
  Future<void> setSoundPreference(bool enabled) async {
    await initialize();
    _settings['sound_enabled'] = enabled;
    await _saveSettings();
  }

  /// 获取音效偏好
  bool getSoundPreference() {
    return _settings['sound_enabled'] ?? true;
  }

  /// 设置振动偏好
  Future<void> setVibrationPreference(bool enabled) async {
    await initialize();
    _settings['vibration_enabled'] = enabled;
    await _saveSettings();
  }

  /// 获取振动偏好
  bool getVibrationPreference() {
    return _settings['vibration_enabled'] ?? true;
  }

  /// 设置答题偏好
  Future<void> setQuizPreference(Map<String, dynamic> preferences) async {
    await initialize();
    _settings['quiz_preferences'] = preferences;
    await _saveSettings();
  }

  /// 获取答题偏好
  Map<String, dynamic> getQuizPreference() {
    return Map<String, dynamic>.from(_settings['quiz_preferences'] ?? {});
  }

  /// 设置通知偏好
  Future<void> setNotificationPreference(Map<String, dynamic> preferences) async {
    await initialize();
    _settings['notification_preferences'] = preferences;
    await _saveSettings();
  }

  /// 获取通知偏好
  Map<String, dynamic> getNotificationPreference() {
    return Map<String, dynamic>.from(_settings['notification_preferences'] ?? {});
  }

  /// 设置学习目标
  Future<void> setLearningGoal(Map<String, dynamic> goal) async {
    await initialize();
    _settings['learning_goal'] = goal;
    await _saveSettings();
  }

  /// 获取学习目标
  Map<String, dynamic>? getLearningGoal() {
    return _settings['learning_goal'];
  }

  /// 设置用户偏好标签
  Future<void> setUserTags(List<String> tags) async {
    await initialize();
    _settings['user_tags'] = tags;
    await _saveSettings();
  }

  /// 获取用户偏好标签
  List<String> getUserTags() {
    return List<String>.from(_settings['user_tags'] ?? []);
  }

  /// 设置自定义快捷方式
  Future<void> setCustomShortcuts(Map<String, dynamic> shortcuts) async {
    await initialize();
    _settings['custom_shortcuts'] = shortcuts;
    await _saveSettings();
  }

  /// 获取自定义快捷方式
  Map<String, dynamic> getCustomShortcuts() {
    return Map<String, dynamic>.from(_settings['custom_shortcuts'] ?? {});
  }

  /// 重置所有设置
  Future<void> resetAllSettings() async {
    await initialize();
    _settings.clear();
    await _saveSettings();
  }

  /// 导出设置
  Map<String, dynamic> exportSettings() {
    return Map<String, dynamic>.from(_settings);
  }

  /// 导入设置
  Future<void> importSettings(Map<String, dynamic> settings) async {
    await initialize();
    _settings.clear();
    _settings.addAll(settings);
    await _saveSettings();
  }

  /// 更新用户行为
  void updateUserBehavior(dynamic currentQuestion, String userAnswer, String answerTime) {
    // 更新用户行为数据
    final behaviorData = {
      'question_id': currentQuestion.id,
      'user_answer': userAnswer,
      'answer_time': answerTime,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    // 保存到本地存储
    final behaviors = _prefs?.getStringList('user_behaviors') ?? [];
    behaviors.add(behaviorData.toString());
    _prefs?.setStringList('user_behaviors', behaviors);
  }
}

/// 主题颜色配置
class ThemeColorConfig {
  static const Map<String, Map<String, dynamic>> themeColors = {
    '拾光复古': {
      'primary': 0xFF8B4513,
      'secondary': 0xFFF5F5DC,
      'accent': 0xFFD2691E,
    },
    '怀旧蓝调': {
      'primary': 0xFF4169E1,
      'secondary': 0xFFE6F3FF,
      'accent': 0xFF87CEEB,
    },
    '温暖橙黄': {
      'primary': 0xFFFF8C00,
      'secondary': 0xFFFFF8DC,
      'accent': 0xFFFFD700,
    },
    '清新绿色': {
      'primary': 0xFF228B22,
      'secondary': 0xFFF0FFF0,
      'accent': 0xFF90EE90,
    },
    '优雅紫色': {
      'primary': 0xFF9370DB,
      'secondary': 0xFFF8F8FF,
      'accent': 0xFFDDA0DD,
    },
    '经典黑白': {
      'primary': 0xFF000000,
      'secondary': 0xFFFFFFFF,
      'accent': 0xFF808080,
    },
  };

  static List<String> getColorNames() {
    return themeColors.keys.toList();
  }

  static Map<String, dynamic>? getColorConfig(String colorName) {
    return themeColors[colorName];
  }
}

/// 字体样式配置
class FontStyleConfig {
  static const Map<String, String> fontStyles = {
    '默认字体': 'default',
    '思源黑体': 'NotoSansCJK',
    '苹方字体': 'PingFang',
    '微软雅黑': 'MicrosoftYaHei',
    '宋体': 'SimSun',
    '楷体': 'KaiTi',
  };

  static List<String> getFontNames() {
    return fontStyles.keys.toList();
  }

  static String? getFontFamily(String fontName) {
    return fontStyles[fontName];
  }
}

/// 学习目标配置
class LearningGoalConfig {
  static const Map<String, Map<String, dynamic>> learningGoals = {
    '每日一练': {
      'description': '每天完成10道题目',
      'target': 10,
      'period': 'daily',
    },
    '周度挑战': {
      'description': '每周完成100道题目',
      'target': 100,
      'period': 'weekly',
    },
    '月度目标': {
      'description': '每月完成500道题目',
      'target': 500,
      'period': 'monthly',
    },
    '成就收集': {
      'description': '解锁所有成就',
      'target': 8,
      'period': 'unlimited',
    },
    '准确率提升': {
      'description': '保持90%以上准确率',
      'target': 90,
      'period': 'continuous',
    },
  };

  static List<String> getGoalNames() {
    return learningGoals.keys.toList();
  }

  static Map<String, dynamic>? getGoalConfig(String goalName) {
    return learningGoals[goalName];
  }
}

/// 个性化推荐服务
class PersonalizationRecommendationService {
  static final PersonalizationRecommendationService _instance = PersonalizationRecommendationService._internal();
  factory PersonalizationRecommendationService() => _instance;
  PersonalizationRecommendationService._internal();

  final PersonalizationService _personalizationService = PersonalizationService();

  /// 根据用户偏好推荐题目
  List<String> recommendQuestions(List<String> availableQuestions, int count) {
    final userTags = _personalizationService.getUserTags();
    final quizPreferences = _personalizationService.getQuizPreference();
    
    // 这里可以实现更复杂的推荐算法
    // 目前返回随机题目
    final shuffled = List<String>.from(availableQuestions)..shuffle();
    return shuffled.take(count).toList();
  }

  /// 根据用户行为推荐功能
  List<String> recommendFeatures(List<String> availableFeatures) {
    final userTags = _personalizationService.getUserTags();
    final learningGoal = _personalizationService.getLearningGoal();
    
    // 根据用户标签和学习目标推荐功能
    final recommendedFeatures = <String>[];
    
    if (userTags.contains('收藏爱好者')) {
      recommendedFeatures.add('收藏夹管理');
    }
    
    if (userTags.contains('成就收集者')) {
      recommendedFeatures.add('成就系统');
    }
    
    if (learningGoal != null && learningGoal['period'] == 'daily') {
      recommendedFeatures.add('每日提醒');
    }
    
    return recommendedFeatures;
  }

  /// 根据用户偏好推荐主题
  String recommendTheme() {
    final userTags = _personalizationService.getUserTags();
    
    if (userTags.contains('怀旧')) {
      return '拾光复古';
    } else if (userTags.contains('清新')) {
      return '清新绿色';
    } else if (userTags.contains('温暖')) {
      return '温暖橙黄';
    } else {
      return '拾光复古'; // 默认主题
    }
  }
}
