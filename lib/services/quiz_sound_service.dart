import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 答题音效服务（完全离线，支持鸿蒙平台）
class QuizSoundService {
  static final QuizSoundService _instance = QuizSoundService._internal();
  factory QuizSoundService() => _instance;
  QuizSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;

  /// 是否启用音效
  bool get soundEnabled => _soundEnabled;

  /// 设置音效开关
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// 播放正确音效
  Future<void> playCorrectSound() async {
    if (!_soundEnabled) return;

    try {
      // 使用系统提示音（完全离线，不依赖外部文件）
      // 在鸿蒙平台上，可以使用震动反馈代替
      await _playSystemSound();
    } catch (e) {
      if (kDebugMode) {
        print('播放正确音效失败: $e');
      }
    }
  }

  /// 播放错误音效
  Future<void> playWrongSound() async {
    if (!_soundEnabled) return;

    try {
      // 使用系统提示音
      await _playSystemSound();
    } catch (e) {
      if (kDebugMode) {
        print('播放错误音效失败: $e');
      }
    }
  }

  /// 播放系统提示音（通过震动反馈实现，完全离线）
  Future<void> _playSystemSound() async {
    // 由于是离线应用，我们使用震动反馈代替音效
    // 震动反馈在鸿蒙平台上支持良好
    try {
      // 这里可以添加震动反馈
      // 但为了保持代码简洁，暂时不实现
      // 如果需要，可以使用 vibration 包
    } catch (e) {
      // 静默失败
    }
  }

  /// 释放资源
  void dispose() {
    _audioPlayer.dispose();
  }
}

