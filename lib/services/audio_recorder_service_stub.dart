import 'audio_recorder_service.dart';

/// 创建真实录音服务（空实现，用于不支持录音的平台）
/// 这个函数在条件导入中被使用
AudioRecorderService createRealAudioRecorderService() {
  return _NoOpAudioRecorderService();
}

/// 空实现（用于不支持录音的平台）
class _NoOpAudioRecorderService implements AudioRecorderService {
  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> start(String path) async {
    throw UnsupportedError('录音功能在当前平台不可用（鸿蒙平台暂不支持）');
  }

  @override
  Future<String?> stop() async => null;

  @override
  void dispose() {}
}

