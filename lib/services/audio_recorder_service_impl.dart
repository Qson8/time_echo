import 'audio_recorder_service.dart';
import 'audio_recorder_service_real.dart';

/// 创建录音服务（根据平台自动选择实现）
/// 注意：由于record包在鸿蒙平台不兼容，已完全移除
/// 目前所有平台都使用空实现，录音功能被禁用
/// 如需在Android/iOS使用录音功能，可以在audio_recorder_service_real.dart中实现
AudioRecorderService createAudioRecorderService() {
  // 目前所有平台都使用空实现（record包已移除）
  // 如果将来需要添加录音功能，可以在createRealAudioRecorderService中实现
  return createRealAudioRecorderService();
}

