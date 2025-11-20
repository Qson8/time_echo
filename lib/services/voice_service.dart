import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

/// 平台不支持异常
class PlatformUnsupportedException implements Exception {
  final String message;
  PlatformUnsupportedException(this.message);
  @override
  String toString() => message;
}

/// 语音服务类
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  FlutterTts? _flutterTts;
  static const MethodChannel _harmonyTtsChannel = MethodChannel('com.time_echo/harmony_tts');
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isEnabled = true;
  String _currentSpeed = '中';
  double _currentVolume = 1.0;
  double _currentPitch = 1.0;
  bool _isPlatformSupported = true; // 平台是否支持TTS
  bool _hasCheckedPlatformSupport = false; // 是否已检查平台支持
  bool _useHarmonyTts = false; // 是否使用鸿蒙原生TTS
  bool _pluginDefinitelyMissing = false; // 插件是否确实不存在（通过MissingPluginException确认）

  /// 检测平台是否支持TTS
  Future<bool> _checkPlatformSupport({bool forceRecheck = false}) async {
    // 如果需要强制重新检查，先重置所有标志
    // 这样如果插件后来注册了，还能重新尝试
    if (forceRecheck) {
      print('🗣️ 强制重新检查平台支持...');
      _hasCheckedPlatformSupport = false;
      _isPlatformSupported = true; // 重置为默认值
      _pluginDefinitelyMissing = false; // 允许重新尝试检测插件
    } else {
      // 如果插件确实不存在，且不是强制重新检查，不再重新检查
      if (_pluginDefinitelyMissing) {
        print('🗣️ 插件已确认不存在，跳过检查');
        return false;
      }
      
      if (_hasCheckedPlatformSupport) {
        print('🗣️ 平台支持已检查过，返回缓存结果: $_isPlatformSupported');
        return _isPlatformSupported;
      }
    }
    
    print('🗣️ 开始检测平台TTS支持...');
    _hasCheckedPlatformSupport = true;
    
    // 首先尝试使用鸿蒙原生TTS（不依赖平台检测，直接尝试调用）
    // 这样可以确保如果插件已注册，就能使用
    // 如果第一次失败（可能是插件还在注册中），等待一小段时间后重试一次
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        if (attempt > 0) {
          print('🗣️ 等待插件注册完成，500ms后重试...');
          await Future.delayed(const Duration(milliseconds: 500));
        }
        print('🗣️ 尝试初始化鸿蒙原生TTS（尝试 ${attempt + 1}/2）...');
        print('🗣️ 调用MethodChannel: com.time_echo/harmony_tts, method: initialize');
        final result = await _harmonyTtsChannel.invokeMethod<bool>('initialize').timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('🗣️ ⚠️ 鸿蒙原生TTS初始化超时（3秒）');
            return false;
          },
        );
        print('🗣️ 鸿蒙原生TTS初始化返回结果: $result');
        if (result == true) {
          _useHarmonyTts = true;
          _isPlatformSupported = true;
          print('🗣️ ✅ 鸿蒙原生TTS初始化成功，将使用鸿蒙原生TTS');
          return true;
        } else {
          print('🗣️ ⚠️ 鸿蒙原生TTS初始化返回false');
        }
        // 如果返回false，不再重试，直接跳出循环
        break;
      } catch (e, stackTrace) {
        final errorStr = e.toString();
        print('🗣️ ⚠️ 鸿蒙原生TTS初始化异常（尝试 ${attempt + 1}/2）: $e');
        print('🗣️ ⚠️ 错误堆栈: $stackTrace');
        // 如果是MissingPluginException，说明插件未注册
        if (errorStr.contains('MissingPluginException') || 
            errorStr.contains('No implementation found') ||
            errorStr.contains('MethodChannel') ||
            errorStr.contains('Method not found')) {
          if (attempt == 0) {
            // 第一次失败，可能是插件还在注册中，重试一次
            print('🗣️ ⚠️ 鸿蒙原生TTS插件未注册（可能是注册中），将重试...');
            continue;
          } else {
            // 第二次也失败，说明插件确实未注册
            print('🗣️ ⚠️ 鸿蒙原生TTS插件未注册或不可用，尝试flutter_tts');
            break;
          }
        } else {
          // 其他错误，不再重试
          print('🗣️ ⚠️ 鸿蒙原生TTS初始化失败，尝试flutter_tts');
          break;
        }
      }
    }
    
    // 尝试创建FlutterTts实例来检测是否支持
    try {
      final testTts = FlutterTts();
      // 尝试调用一个简单的方法来检测插件是否可用
      try {
        await testTts.setLanguage("zh-CN");
        _useHarmonyTts = false;
        _isPlatformSupported = true;
        print('🗣️ ✅ 平台支持flutter_tts');
      } catch (e) {
        // 如果setLanguage失败，检查是否是插件未实现
        final errorStr = e.toString();
        if (errorStr.contains('MissingPluginException') || 
            errorStr.contains('No implementation found') ||
            errorStr.contains('Method not found')) {
          _isPlatformSupported = false;
          _pluginDefinitelyMissing = true; // 确认插件不存在
          print('🗣️ ⚠️ 平台不支持TTS功能（插件未实现）: $e');
        } else {
          // 其他错误，可能只是语言设置失败，但插件可用
          // 尝试调用speak方法来进一步确认
          try {
            await testTts.speak('test');
            await testTts.stop();
            _isPlatformSupported = true;
            print('🗣️ ✅ 语言设置失败，但插件可用（通过speak测试）');
          } catch (speakError) {
            final speakErrorStr = speakError.toString();
            if (speakErrorStr.contains('MissingPluginException') || 
                speakErrorStr.contains('No implementation found') ||
                speakErrorStr.contains('Method not found')) {
              _isPlatformSupported = false;
              _pluginDefinitelyMissing = true; // 确认插件不存在
              print('🗣️ ⚠️ 平台不支持TTS功能（speak方法不可用）: $speakError');
            } else {
              _isPlatformSupported = true;
              print('🗣️ ⚠️ speak测试失败，但可能是其他原因: $speakError');
            }
          }
        }
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('MissingPluginException') || 
          errorStr.contains('No implementation found') ||
          errorStr.contains('Method not found')) {
        _isPlatformSupported = false;
        _pluginDefinitelyMissing = true; // 确认插件不存在
        print('🗣️ ❌ 无法创建TTS实例，平台不支持: $e');
      } else {
        // 其他异常，可能是其他问题，但先标记为不支持
        _isPlatformSupported = false;
        print('🗣️ ❌ 创建TTS实例时发生异常: $e');
      }
    }
    
    return _isPlatformSupported;
  }

  /// 初始化语音服务
  Future<void> initialize({String? initialSpeed}) async {
    print('🗣️ initialize() 被调用，initialSpeed: $initialSpeed');
    print('🗣️ 当前状态: _isInitialized=$_isInitialized, _useHarmonyTts=$_useHarmonyTts, _hasCheckedPlatformSupport=$_hasCheckedPlatformSupport');
    
    if (_isInitialized) {
      if (_useHarmonyTts || (!_useHarmonyTts && _flutterTts != null)) {
        print('🗣️ 语音服务已初始化，跳过重复初始化');
        return;
      }
    }

    // 首先检查平台支持
    // 如果插件已确认不存在，但在应用启动时（未初始化），允许重新尝试一次
    // 因为插件可能在应用启动时已经注册了
    bool shouldForceRecheck = false;
    if (_pluginDefinitelyMissing) {
      if (!_isInitialized) {
        // 应用启动时，即使之前检测失败，也允许重新尝试一次
        print('🗣️ 插件之前检测失败，但在应用启动时允许重新尝试一次...');
        shouldForceRecheck = true;
      } else {
        print('🗣️ ⚠️ 插件已确认不存在，跳过初始化');
        _isInitialized = false;
        _flutterTts = null;
        return;
      }
    } else {
      // 如果之前检查失败，且当前未初始化，允许重新检查一次
      shouldForceRecheck = !_isInitialized && _hasCheckedPlatformSupport && !_isPlatformSupported;
      if (shouldForceRecheck) {
        print('🗣️ 检测到之前检查失败，尝试强制重新检查...');
      }
    }
    
    print('🗣️ 调用 _checkPlatformSupport()...');
    final isSupported = await _checkPlatformSupport(forceRecheck: shouldForceRecheck);
    print('🗣️ _checkPlatformSupport() 返回结果: $isSupported');
    if (!isSupported) {
      print('🗣️ ⚠️ 当前平台不支持TTS功能，跳过初始化');
      _isInitialized = false;
      _flutterTts = null;
      return;
    }

    try {
      if (_useHarmonyTts) {
        // 使用鸿蒙原生TTS
        print('🗣️ 使用鸿蒙原生TTS初始化...');
        await _harmonyTtsChannel.invokeMethod('initialize');
        // 设置语速
        final speed = initialSpeed ?? '中';
        final rate = AppConstants.voiceSpeeds[speed] ?? 0.5;
        await _harmonyTtsChannel.invokeMethod('setSpeechRate', rate);
        _currentSpeed = speed;
        _isInitialized = true;
        print('🗣️ ✅ 鸿蒙原生TTS初始化完成');
        return;
      }
      
      print('🗣️ 开始初始化flutter_tts...');
      _flutterTts = FlutterTts();
      
      // 设置语言（某些平台如鸿蒙可能不支持，需要单独处理）
      try {
        await _flutterTts!.setLanguage("zh-CN");
        print('🗣️ ✅ 语言设置成功: zh-CN');
      } catch (e) {
        print('🗣️ ⚠️ 语言设置失败（某些平台不支持）: $e');
        // 尝试使用默认语言
        try {
          await _flutterTts!.setLanguage("zh");
          print('🗣️ ✅ 使用备用语言设置: zh');
        } catch (e2) {
          print('🗣️ ⚠️ 备用语言设置也失败: $e2');
        }
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
      print('🗣️ ✅ 语音服务状态: isEnabled=$_isEnabled, isInitialized=$_isInitialized');
    } catch (e, stackTrace) {
      print('🗣️ ❌ 语音服务初始化失败: $e');
      print('🗣️ ❌ 错误堆栈: $stackTrace');
      
      // 检查是否是MissingPluginException（插件未实现）
      if (e.toString().contains('MissingPluginException') || 
          e.toString().contains('No implementation found')) {
        print('🗣️ ⚠️ 检测到插件未实现，标记平台不支持TTS');
        _isPlatformSupported = false;
        _hasCheckedPlatformSupport = true;
        _pluginDefinitelyMissing = true; // 确认插件不存在
      }
      
      _isInitialized = false;
      _flutterTts = null;
      // 即使初始化失败，也允许后续尝试（某些平台可能不支持某些方法）
    }
  }
  
  /// 检查平台是否支持TTS
  bool get isPlatformSupported {
    // 如果还没有检查过，返回true（默认支持，等待实际检查）
    if (!_hasCheckedPlatformSupport) {
      print('🗣️ isPlatformSupported被调用，但尚未检查，返回默认值true');
      return true;
    }
    print('🗣️ isPlatformSupported被调用，返回检查结果: $_isPlatformSupported');
    return _isPlatformSupported;
  }

  /// 设置语音速度
  Future<void> setSpeechRate(String speed) async {
    _currentSpeed = speed;
    if (!_isInitialized) await initialize(initialSpeed: speed);
    
    try {
      final rate = AppConstants.voiceSpeeds[speed] ?? 0.5;
      if (_useHarmonyTts) {
        await _harmonyTtsChannel.invokeMethod('setSpeechRate', rate);
      } else if (_flutterTts != null) {
        await _flutterTts!.setSpeechRate(rate);
      }
    } catch (e) {
      print('设置语音速度失败: $e');
    }
  }

  /// 朗读文本
  /// [throwOnUnsupported] 如果为 true，平台不支持时会抛出异常；如果为 false，则静默返回
  Future<void> speak(String text, {bool throwOnUnsupported = false}) async {
    if (!_isEnabled) {
      print('🗣️ ⚠️ 语音功能未启用，跳过朗读');
      return;
    }
    
    if (text.isEmpty) {
      print('🗣️ ⚠️ 文本为空，跳过朗读');
      return;
    }
    
    // 确保服务已初始化（这会检查平台支持）
    if (!_isInitialized || (!_useHarmonyTts && _flutterTts == null)) {
      print('🗣️ 语音服务未初始化或实例不可用，开始初始化...');
      await initialize();
      // 如果初始化后仍然未初始化或不支持，说明平台不支持
      if (!_isInitialized || (!_useHarmonyTts && _flutterTts == null) || !_isPlatformSupported) {
        print('🗣️ ⚠️ 语音服务不可用，平台不支持TTS功能');
        if (throwOnUnsupported) {
          throw PlatformUnsupportedException('当前平台不支持语音读题功能');
        }
        return; // 静默返回，不抛出异常
      }
    }
    
    // 再次检查平台支持（可能在初始化过程中被标记为不支持）
    if (!_isPlatformSupported) {
      print('🗣️ ⚠️ 当前平台不支持TTS功能，跳过朗读');
      if (throwOnUnsupported) {
        throw PlatformUnsupportedException('当前平台不支持语音读题功能');
      }
      return; // 静默返回，不抛出异常
    }
    
    try {
      if (_isSpeaking) {
        print('🗣️ 正在播放中，先停止当前播放');
        await stop();
        // 等待一小段时间确保停止完成
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      print('🗣️ 准备朗读文本: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      
      if (_useHarmonyTts) {
        // 使用鸿蒙原生TTS
        await _harmonyTtsChannel.invokeMethod('speak', text);
        _isSpeaking = true;
        print('🗣️ ✅ 鸿蒙TTS开始朗读文本');
      } else {
        // 使用flutter_tts
        await _flutterTts!.speak(text);
        print('🗣️ ✅ 开始朗读文本');
      }
      
      // 设置一个超时检查，如果3秒后仍然没有开始播放，重置状态
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isSpeaking && _flutterTts != null) {
          print('🗣️ ⚠️ 3秒后仍未开始播放，可能存在问题');
        }
      });
    } catch (e, stackTrace) {
      print('🗣️ ❌ 朗读失败: $e');
      print('🗣️ ❌ 错误堆栈: $stackTrace');
      
      // 如果是MissingPluginException，标记平台不支持
      if (e.toString().contains('MissingPluginException') || 
          e.toString().contains('No implementation found')) {
        print('🗣️ ⚠️ 检测到插件未实现，标记平台不支持TTS');
        _isPlatformSupported = false;
        _hasCheckedPlatformSupport = true;
        _pluginDefinitelyMissing = true; // 确认插件不存在
        if (throwOnUnsupported) {
          throw PlatformUnsupportedException('当前平台不支持语音读题功能');
        }
        // 静默返回，不抛出异常
        return;
      }
      
      _isSpeaking = false;
      // 如果是手动调用（需要错误提示），重新抛出异常
      if (throwOnUnsupported) {
        rethrow;
      }
      // 否则静默返回
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
      if (_useHarmonyTts) {
        await _harmonyTtsChannel.invokeMethod('setVolume', _currentVolume);
      } else if (_flutterTts != null) {
        await _flutterTts!.setVolume(_currentVolume);
      }
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
      if (_useHarmonyTts) {
        await _harmonyTtsChannel.invokeMethod('setPitch', _currentPitch);
      } else if (_flutterTts != null) {
        await _flutterTts!.setPitch(_currentPitch);
      }
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
    if (!_isInitialized) return;
    
    try {
      if (_useHarmonyTts) {
        await _harmonyTtsChannel.invokeMethod('stop');
      } else if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
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
  /// [throwOnUnsupported] 如果为 true，平台不支持时会抛出异常；如果为 false，则静默返回
  Future<void> speakQuestion(String question, List<String> options, {bool throwOnUnsupported = false}) async {
    if (!_isInitialized) await initialize();
    
    final text = _buildQuestionText(question, options);
    await speak(text, throwOnUnsupported: throwOnUnsupported);
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
