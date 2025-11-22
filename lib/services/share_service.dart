import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// 分享服务（完全离线，支持鸿蒙平台）
/// 注意：由于screenshot包在鸿蒙平台不兼容，使用Flutter原生方式生成图片
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final GlobalKey _shareCardKey = GlobalKey();

  /// 生成成绩分享卡片
  Future<String?> generateScoreShareImage({
    required int echoAge,
    required double accuracy,
    required int totalQuestions,
    required int correctAnswers,
    List<String>? achievements,
  }) async {
    try {
      // 使用Flutter原生方式生成图片
      // 注意：这需要在Widget树中渲染，所以暂时返回null
      // 实际使用时，需要在Widget树中使用RepaintBoundary包装
      print('⚠️ 图片生成功能在鸿蒙平台暂时不可用（screenshot包不兼容）');
      return null;
    } catch (e) {
      print('生成成绩分享图失败: $e');
      return null;
    }
  }

  /// 使用RepaintBoundary生成图片（需要在Widget树中使用）
  Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        return null;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) {
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      print('捕获Widget失败: $e');
      return null;
    }
  }

  /// 构建成绩分享卡片Widget
  Widget _buildScoreShareCard({
    required int echoAge,
    required double accuracy,
    required int totalQuestions,
    required int correctAnswers,
    required List<String> achievements,
  }) {
    return Container(
      width: 400,
      height: 600,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF8DC),
            const Color(0xFFFFE4B5),
            const Color(0xFFFFD700),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '拾光机',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '我的拾光年龄',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$echoAge 岁',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildStatRow('总题数', '$totalQuestions'),
                const SizedBox(height: 12),
                _buildStatRow('正确数', '$correctAnswers'),
                const SizedBox(height: 12),
                // accuracy已经是百分比格式（0-100），不需要再乘以100
                _buildStatRow('准确率', '${accuracy.clamp(0.0, 100.0).toInt()}%'),
              ],
            ),
          ),
          if (achievements.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              '成就',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: achievements.take(3).map((achievement) {
                return Chip(
                  label: Text(achievement),
                  backgroundColor: Colors.orange.withOpacity(0.2),
                );
              }).toList(),
            ),
          ],
          const Spacer(),
          Text(
            '让每一份时光记忆都值得珍藏',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 分享图片到系统分享菜单
  Future<void> shareImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: '来自拾光机的分享',
        );
      }
    } catch (e) {
      print('分享图片失败: $e');
      rethrow;
    }
  }

  /// 保存图片到相册
  Future<bool> saveImageToGallery(String imagePath) async {
    try {
      // 注意：保存到相册需要额外权限，这里只是示例
      // 实际使用时可能需要使用 image_gallery_saver 等包
      final file = File(imagePath);
      if (await file.exists()) {
        // 复制到公共目录（需要权限）
        // 这里暂时只返回成功，实际实现需要平台特定代码
        return true;
      }
      return false;
    } catch (e) {
      print('保存图片失败: $e');
      return false;
    }
  }

  /// 生成二维码（用于本地数据导入）
  Widget generateQRCode(String data) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: 200.0,
      backgroundColor: Colors.white,
    );
  }

  /// 获取分享卡片的GlobalKey（用于外部使用）
  GlobalKey get shareCardKey => _shareCardKey;

  /// 生成分享文本（作为图片生成的替代方案）
  String generateShareText({
    required int echoAge,
    required double accuracy,
    required int totalQuestions,
    required int correctAnswers,
    List<String>? achievements,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🎉 拾光机 - 我的拾光年龄');
    buffer.writeln('');
    buffer.writeln('我的拾光年龄：$echoAge 岁');
    buffer.writeln('');
    buffer.writeln('📊 答题统计：');
    buffer.writeln('总题数：$totalQuestions');
    buffer.writeln('正确数：$correctAnswers');
    // accuracy已经是百分比格式（0-100），不需要再乘以100
    buffer.writeln('准确率：${accuracy.clamp(0.0, 100.0).toInt()}%');
    
    if (achievements != null && achievements.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('🏆 成就：');
      for (final achievement in achievements) {
        buffer.writeln('• $achievement');
      }
    }
    
    buffer.writeln('');
    buffer.writeln('让每一份时光记忆都值得珍藏');
    
    return buffer.toString();
  }
}

