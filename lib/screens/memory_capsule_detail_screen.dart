import 'package:flutter/material.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../models/memory_capsule.dart';
import '../services/memory_capsule_service.dart';
import 'memory_capsule_creation_screen.dart';
import 'package:audioplayers/audioplayers.dart';

/// 记忆胶囊详情页面
class MemoryCapsuleDetailScreen extends StatefulWidget {
  final MemoryCapsule capsule;

  const MemoryCapsuleDetailScreen({
    super.key,
    required this.capsule,
  });

  @override
  State<MemoryCapsuleDetailScreen> createState() => _MemoryCapsuleDetailScreenState();
}

class _MemoryCapsuleDetailScreenState extends State<MemoryCapsuleDetailScreen> {
  final MemoryCapsuleService _service = MemoryCapsuleService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 播放音频
  Future<void> _playAudio() async {
    if (widget.capsule.audioPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.play(DeviceFileSource(widget.capsule.audioPath!));
        setState(() => _isPlaying = true);
        
        // 监听播放完成
        _audioPlayer.onPlayerComplete.listen((_) {
          setState(() => _isPlaying = false);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放音频失败: $e')),
        );
      }
    }
  }

  /// 编辑记忆胶囊
  void _editCapsule() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoryCapsuleCreationScreen(
          capsule: widget.capsule,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true); // 返回true表示需要刷新
    }
  }

  /// 删除记忆胶囊
  void _deleteCapsule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个记忆胶囊吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteCapsule(widget.capsule.id);
        if (mounted) {
          Navigator.pop(context, true); // 返回true表示需要刷新
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆胶囊详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCapsule,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCapsule,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              widget.capsule.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 标签和年代
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.capsule.era,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(AppConstants.primaryColor),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.capsule.category,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.capsule.mood.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.capsule.mood,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ...(widget.capsule.tags.isNotEmpty 
                    ? widget.capsule.tags.map((tag) => Chip(
                        label: Text(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList()
                    : []),
              ],
            ),
            const SizedBox(height: 24),

            // 图片
            if (widget.capsule.hasImage)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(widget.capsule.imagePath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (widget.capsule.hasImage) const SizedBox(height: 24),

            // 内容
            Text(
              widget.capsule.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // 音频播放器
            if (widget.capsule.hasAudio)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _playAudio,
                      iconSize: 32,
                      color: const Color(AppConstants.primaryColor),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('播放录音'),
                    ),
                  ],
                ),
              ),
            if (widget.capsule.hasAudio) const SizedBox(height: 24),

            // 位置信息
            if (widget.capsule.location != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    widget.capsule.location!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 记忆时间
            if (widget.capsule.memoryDate != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '记忆时间: ${_formatDate(widget.capsule.memoryDate!)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 创建时间
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '创建于: ${_formatDateTime(widget.capsule.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

