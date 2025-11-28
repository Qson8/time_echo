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
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: const Text('记忆胶囊详情'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCapsule,
            tooltip: '编辑',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteCapsule,
            tooltip: '删除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部信息卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    widget.capsule.getDisplayTitle(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(AppConstants.textPrimaryColor),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // 标签行
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // 年代标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(AppConstants.primaryColor).withOpacity(0.15),
                              const Color(AppConstants.primaryColor).withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(AppConstants.primaryColor).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: const Color(AppConstants.primaryColor),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.capsule.era,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(AppConstants.primaryColor),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 分类标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.accentColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(AppConstants.accentColor).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.capsule.category,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(AppConstants.accentColor),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // 心情标签
                      if (widget.capsule.mood.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _getMoodColor(widget.capsule.mood).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getMoodColor(widget.capsule.mood).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getMoodIcon(widget.capsule.mood),
                                size: 14,
                                color: _getMoodColor(widget.capsule.mood),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.capsule.mood,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _getMoodColor(widget.capsule.mood),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 内容卡片
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(AppConstants.primaryColor).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 内容标题
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description,
                          size: 20,
                          color: Color(AppConstants.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '记忆内容',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(AppConstants.textPrimaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 内容文本
                  Text(
                    widget.capsule.content,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.8,
                      color: Color(AppConstants.textPrimaryColor),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // 图片卡片
            if (widget.capsule.hasImage)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.capsule.imagePath!),
                    fit: BoxFit.cover,
                    height: 300,
                    width: double.infinity,
                  ),
                ),
              ),
            if (widget.capsule.hasImage) const SizedBox(height: 16),

            // 音频播放器卡片
            if (widget.capsule.hasAudio)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 40,
                          color: Colors.orange,
                        ),
                        onPressed: _playAudio,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '录音',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(AppConstants.textPrimaryColor),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '点击播放按钮收听',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.capsule.hasAudio) const SizedBox(height: 16),

            // 标签卡片
            if (widget.capsule.tags.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '标签',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConstants.textPrimaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.capsule.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            if (widget.capsule.tags.isNotEmpty) const SizedBox(height: 16),

            // 信息卡片
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // 位置信息
                  if (widget.capsule.location != null) ...[
                    _buildInfoRow(
                      icon: Icons.location_on,
                      iconColor: Colors.red,
                      label: '地点',
                      value: widget.capsule.location!,
                    ),
                    const Divider(height: 24),
                  ],
                  // 记忆时间
                  if (widget.capsule.memoryDate != null) ...[
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      iconColor: Colors.blue,
                      label: '记忆时间',
                      value: _formatDate(widget.capsule.memoryDate!),
                    ),
                    const Divider(height: 24),
                  ],
                  // 创建时间
                  _buildInfoRow(
                    icon: Icons.access_time,
                    iconColor: Colors.grey,
                    label: '创建时间',
                    value: _formatDateTime(widget.capsule.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(AppConstants.textPrimaryColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 获取心情颜色
  Color _getMoodColor(String mood) {
    switch (mood) {
      case '怀念':
        return Colors.purple;
      case '开心':
        return Colors.orange;
      case '感动':
        return Colors.red;
      case '平静':
        return Colors.blue;
      case '兴奋':
        return Colors.green;
      default:
        return const Color(AppConstants.primaryColor);
    }
  }

  /// 获取心情图标
  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case '怀念':
        return Icons.favorite;
      case '开心':
        return Icons.mood;
      case '感动':
        return Icons.favorite_border;
      case '平静':
        return Icons.wb_sunny;
      case '兴奋':
        return Icons.celebration;
      default:
        return Icons.sentiment_satisfied;
    }
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

