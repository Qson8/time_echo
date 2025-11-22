import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 平台工具类
class PlatformUtils {
  static bool? _isHarmonyOSCache;
  
  /// 检测是否为鸿蒙平台
  /// 鸿蒙在Flutter中可能被识别为Linux，需要通过其他方式检测
  static bool get isHarmonyOS {
    if (_isHarmonyOSCache != null) {
      return _isHarmonyOSCache!;
    }
    
    try {
      if (kIsWeb) {
        _isHarmonyOSCache = false;
        return false;
      }
      
      // 方法1：检查是否为Linux（鸿蒙在Flutter中可能被识别为Linux）
      if (Platform.isLinux) {
        // 方法2：检查环境变量或系统属性
        // 鸿蒙系统通常会有特定的环境变量
        final env = Platform.environment;
        if (env.containsKey('OHOS_ARCH') || 
            env.containsKey('OHOS_SDK') ||
            env.containsKey('OHOS_ROOT')) {
          _isHarmonyOSCache = true;
          return true;
        }
        
        // 如果是Linux但不是Web，可能是鸿蒙（需要运行时确认）
        // 但为了安全，先返回false，通过运行时检测确认
        _isHarmonyOSCache = false;
        return false;
      }
      
      _isHarmonyOSCache = false;
      return false;
    } catch (e) {
      _isHarmonyOSCache = false;
      return false;
    }
  }
  
  /// 运行时检测是否为鸿蒙平台（通过MethodChannel）
  /// 这个方法需要在有BuildContext的情况下调用
  static Future<bool> checkHarmonyOSRuntime() async {
    try {
      if (kIsWeb) {
        _isHarmonyOSCache = false;
        return false;
      }
      
      // 首先进行同步检测：在移动设备上，如果是Linux，很可能是鸿蒙
      // 因为真正的Linux桌面系统不会在移动设备上运行
      if (Platform.isLinux) {
        // 检查环境变量
        final env = Platform.environment;
        if (env.containsKey('OHOS_ARCH') || 
            env.containsKey('OHOS_SDK') ||
            env.containsKey('OHOS_ROOT')) {
          _isHarmonyOSCache = true;
          return true;
        }
        
        // 在移动设备上，如果是Linux，很可能是鸿蒙系统
        // 为了安全起见，先假设是鸿蒙（隐藏语音功能）
        // 然后尝试通过MethodChannel确认
        try {
          const channel = MethodChannel('com.time_echo/harmony_tts');
          await channel.invokeMethod('isSpeaking').timeout(
            const Duration(milliseconds: 100),
            onTimeout: () => throw TimeoutException('Timeout'),
          );
          // 如果能调用成功，确认是鸿蒙平台
          _isHarmonyOSCache = true;
          return true;
        } on MissingPluginException {
          // 插件不存在，但在移动设备上的Linux很可能是鸿蒙
          // 为了安全，假设是鸿蒙（隐藏语音功能）
          _isHarmonyOSCache = true;
          return true;
        } catch (e) {
          // 其他错误，可能是鸿蒙平台但方法不存在
          // 在移动设备上的Linux，假设是鸿蒙
          if (e is! TimeoutException) {
            _isHarmonyOSCache = true;
            return true;
          }
          // 超时也假设是鸿蒙（安全起见）
          _isHarmonyOSCache = true;
          return true;
        }
      }
      
      // 不是Linux，肯定不是鸿蒙
      _isHarmonyOSCache = false;
      return false;
    } catch (e) {
      // 出错时，如果是Linux，假设是鸿蒙（安全起见）
      if (!kIsWeb) {
        try {
          if (Platform.isLinux) {
            _isHarmonyOSCache = true;
            return true;
          }
        } catch (_) {
          // 忽略错误
        }
      }
      _isHarmonyOSCache = false;
      return false;
    }
  }
  
  /// 同步检测是否为鸿蒙平台（基于Platform.isLinux）
  /// 这个方法不够准确，但可以在初始化时使用
  static bool get isHarmonyOSSync {
    if (_isHarmonyOSCache != null) {
      return _isHarmonyOSCache!;
    }
    
    try {
      if (kIsWeb) {
        _isHarmonyOSCache = false;
        return false;
      }
      
      // 鸿蒙在Flutter中可能被识别为Linux
      // 但为了准确，我们还需要运行时检测
      // 这里先返回false，让运行时检测来确认
      return false;
    } catch (e) {
      return false;
    }
  }
}

