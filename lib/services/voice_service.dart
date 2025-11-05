import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// 语音服务类
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isEnabled = true;
  String _currentSpeed = '中';
  double _currentVolume = 1.0;
  double _currentPitch = 1.0;

  /// 初始化语音服务
  Future<void> initialize({String? initialSpeed}) async {
    if (_isInitialized) return;

    try {
      _flutterTts = FlutterTts();
      
      // 设置语言（某些平台如鸿蒙可能不支持，需要单独处理）
      try {
        await _flutterTts!.setLanguage("zh-CN");
        print('🗣️ ✅ 语言设置成功: zh-CN');
      } catch (e) {
        print('🗣️ ⚠️ 语言设置失败（某些平台不支持）: $e');
        // 继续初始化，不阻止服务使用
      }
      
      // 设置音量
      try {
        await _flutterTts!.setVolume(1.0);
        print('🗣️ ✅ 音量设置成功');
      } catch (e) {
        print('🗣️ ⚠️ 音量设置失败: $e');
        // 继续初始化
      }
      
      // 设置语速（使用传入的速度或默认的"中"速度）
      final speed = initialSpeed ?? '中';
      _currentSpeed = speed;
      try {
        final rate = AppConstants.voiceSpeeds[speed] ?? 0.5;
        await _flutterTts!.setSpeechRate(rate);
        print('🗣️ ✅ 语速设置成功: $speed');
      } catch (e) {
        print('🗣️ ⚠️ 语速设置失败: $e');
        // 继续初始化
      }
      
      // 设置音调
      try {
        await _flutterTts!.setPitch(1.0);
        print('🗣️ ✅ 音调设置成功');
      } catch (e) {
        print('🗣️ ⚠️ 音调设置失败: $e');
        // 继续初始化
      }
      
      // iOS 使用系统默认语音引擎，无需额外设置
      // setEngine 方法在某些版本中不可用，所以不设置引擎
      // 系统会自动使用默认的中文语音引擎
      
      // 监听语音状态（这些方法通常支持更广泛，但也要处理异常）
      try {
        _flutterTts!.setStartHandler(() {
          _isSpeaking = true;
        });
        
        _flutterTts!.setCompletionHandler(() {
          _isSpeaking = false;
        });
        
        _flutterTts!.setErrorHandler((msg) {
          _isSpeaking = false;
          print('🗣️ ❌ 语音播放错误: $msg');
        });
        print('🗣️ ✅ 事件处理器设置成功');
      } catch (e) {
        print('🗣️ ⚠️ 事件处理器设置失败: $e');
        // 继续初始化，即使事件处理失败也可以朗读
      }
      
      _isInitialized = true;
      print('🗣️ ✅ 语音服务初始化完成（部分功能可能不可用，但不影响基本朗读）');
    } catch (e, stackTrace) {
      print('🗣️ ❌ 语音服务初始化失败: $e');
      print('🗣️ ❌ 错误堆栈: $stackTrace');
      _isInitialized = false;
      // 即使初始化失败，也允许后续尝试（某些平台可能不支持某些方法）
    }
  }

  /// 设置语音速度
  Future<void> setSpeechRate(String speed) async {
    _currentSpeed = speed;
    if (!_isInitialized) await initialize(initialSpeed: speed);
    
    try {
      final rate = AppConstants.voiceSpeeds[speed] ?? 0.5;
      await _flutterTts!.setSpeechRate(rate);
    } catch (e) {
      print('设置语音速度失败: $e');
    }
  }

  /// 朗读文本
  Future<void> speak(String text) async {
    if (!_isEnabled) return;
    if (!_isInitialized) {
      await initialize();
      // 如果初始化后仍然未初始化，说明平台不支持，直接返回
      if (!_isInitialized) {
        print('🗣️ ⚠️ 语音服务不可用，跳过朗读');
        return;
      }
    }
    
    // 检查 _flutterTts 是否可用
    if (_flutterTts == null) {
      print('🗣️ ⚠️ FlutterTts 实例不可用，跳过朗读');
      return;
    }
    
    try {
      if (_isSpeaking) {
        await stop();
      }
      
      await _flutterTts!.speak(text);
      print('🗣️ ✅ 开始朗读文本');
    } catch (e) {
      print('🗣️ ❌ 朗读失败: $e');
      _isSpeaking = false;
      // 不抛出异常，静默失败，避免影响应用运行
    }
  }

  /// 启用/禁用语音功能
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled && _isSpeaking) {
      stop();
    }
  }

  /// 获取语音是否启用
  bool get isEnabled => _isEnabled;

  /// 设置音量
  Future<void> setVolume(double volume) async {
    _currentVolume = volume.clamp(0.0, 1.0);
    if (!_isInitialized) await initialize();
    
    try {
      await _flutterTts!.setVolume(_currentVolume);
    } catch (e) {
      print('设置音量失败: $e');
    }
  }

  /// 获取当前音量
  double get volume => _currentVolume;

  /// 设置音调
  Future<void> setPitch(double pitch) async {
    _currentPitch = pitch.clamp(0.5, 2.0);
    if (!_isInitialized) await initialize();
    
    try {
      await _flutterTts!.setPitch(_currentPitch);
    } catch (e) {
      print('设置音调失败: $e');
    }
  }

  /// 获取当前音调
  double get pitch => _currentPitch;

  /// 获取当前语速
  String get currentSpeed => _currentSpeed;

  /// 停止朗读
  Future<void> stop() async {
    if (!_isInitialized || _flutterTts == null) return;
    
    try {
      await _flutterTts!.stop();
      _isSpeaking = false;
    } catch (e) {
      print('🗣️ ⚠️ 停止朗读失败: $e');
      _isSpeaking = false;
    }
  }

  /// 暂停朗读
  Future<void> pause() async {
    if (!_isInitialized || _flutterTts == null) return;
    
    try {
      await _flutterTts!.pause();
    } catch (e) {
      print('🗣️ ⚠️ 暂停朗读失败: $e');
    }
  }

  /// 继续朗读
  Future<void> resume() async {
    if (!_isInitialized || _flutterTts == null) return;
    
    try {
      await _flutterTts!.speak('');
    } catch (e) {
      print('🗣️ ⚠️ 继续朗读失败: $e');
    }
  }

  /// 是否正在朗读
  bool get isSpeaking => _isSpeaking;

  /// 朗读题目
  Future<void> speakQuestion(String question, List<String> options) async {
    if (!_isInitialized) await initialize();
    
    final text = _buildQuestionText(question, options);
    await speak(text);
  }

  /// 构建题目文本
  String _buildQuestionText(String question, List<String> options) {
    final buffer = StringBuffer();
    buffer.write(question);
    buffer.write('。');
    
    for (int i = 0; i < options.length; i++) {
      buffer.write('选项${String.fromCharCode(65 + i)}：');
      buffer.write(options[i]);
      buffer.write('。');
    }
    
    return buffer.toString();
  }

  /// 朗读评语
  Future<void> speakComment(String comment) async {
    if (!_isInitialized) await initialize();
    
    await speak(comment);
  }

  /// 朗读成就解锁
  Future<void> speakAchievementUnlock(String achievementName) async {
    if (!_isInitialized) await initialize();
    
    final text = '恭喜解锁成就：$achievementName';
    await speak(text);
  }

  /// 朗读拾光年龄
  Future<void> speakEchoAge(int echoAge) async {
    if (!_isInitialized) await initialize();
    
    final text = '你的拾光年龄是：$echoAge 岁';
    await speak(text);
  }

  /// 朗读导航信息
  Future<void> speakNavigation(String screenName) async {
    if (!_isInitialized) await initialize();
    
    final text = '已进入$screenName页面';
    await speak(text);
  }

  /// 朗读按钮信息
  Future<void> speakButtonAction(String buttonName, String action) async {
    if (!_isInitialized) await initialize();
    
    final text = '$buttonName按钮，$action';
    await speak(text);
  }

  /// 朗读错误信息
  Future<void> speakError(String errorMessage) async {
    if (!_isInitialized) await initialize();
    
    final text = '错误：$errorMessage';
    await speak(text);
  }

  /// 朗读成功信息
  Future<void> speakSuccess(String successMessage) async {
    if (!_isInitialized) await initialize();
    
    final text = '成功：$successMessage';
    await speak(text);
  }

  /// 朗读提示信息
  Future<void> speakHint(String hintMessage) async {
    if (!_isInitialized) await initialize();
    
    final text = '提示：$hintMessage';
    await speak(text);
  }

  /// 朗读时间信息
  Future<void> speakTime(DateTime time) async {
    if (!_isInitialized) await initialize();
    
    final hour = time.hour;
    final minute = time.minute;
    final text = '当前时间：${hour}点${minute}分';
    await speak(text);
  }

  /// 朗读数字
  Future<void> speakNumber(int number) async {
    if (!_isInitialized) await initialize();
    
    await speak(number.toString());
  }

  /// 朗读百分比
  Future<void> speakPercentage(double percentage) async {
    if (!_isInitialized) await initialize();
    
    final text = '${percentage.toStringAsFixed(1)}%';
    await speak(text);
  }

  /// 朗读列表项
  Future<void> speakListItem(String item, int index, int total) async {
    if (!_isInitialized) await initialize();
    
    final text = '第${index + 1}项，共${total}项：$item';
    await speak(text);
  }

  /// 朗读设置项
  Future<void> speakSetting(String settingName, String value) async {
    if (!_isInitialized) await initialize();
    
    final text = '$settingName：$value';
    await speak(text);
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_isInitialized && _flutterTts != null) {
      try {
        await _flutterTts!.stop();
      } catch (e) {
        print('🗣️ ⚠️ 释放资源时停止失败: $e');
      }
      _isInitialized = false;
    }
  }
}
