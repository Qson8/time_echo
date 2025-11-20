import 'audio_recorder_service.dart';

/// 创建真实录音服务
/// 注意：由于record包在鸿蒙平台不兼容，已完全移除
/// 目前所有平台都使用空实现，录音功能被禁用
/// 如需在Android/iOS使用录音功能，可以：
/// 1. 添加其他录音库（如flutter_sound、just_audio等）
/// 2. 在这里实现真实录音功能
AudioRecorderService createRealAudioRecorderService() {
  // 目前所有平台都使用空实现（record包已移除）
  // 如果将来需要添加录音功能，可以在这里实现
  return _NoOpAudioRecorderService();
}

/// 空实现（用于不支持录音的平台）
class _NoOpAudioRecorderService implements AudioRecorderService {
  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> start(String path) async {
    throw UnsupportedError('录音功能在当前平台不可用');
  }

  @override
  Future<String?> stop() async => null;

  @override
  void dispose() {}
}

