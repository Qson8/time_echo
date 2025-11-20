// 导出创建函数（从实现文件导入）
export 'audio_recorder_service_impl.dart' show createAudioRecorderService;

/// 录音服务抽象类
abstract class AudioRecorderService {
  /// 检查是否有录音权限
  Future<bool> hasPermission();

  /// 开始录音
  Future<void> start(String path);

  /// 停止录音并返回文件路径
  Future<String?> stop();

  /// 释放资源
  void dispose();
}

