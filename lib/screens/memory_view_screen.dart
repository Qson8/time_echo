import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory_record.dart';
import '../services/question_service.dart';
import '../models/question.dart';
import 'memory_detail_screen.dart';

/// 回忆详情查看页面（只读）
class MemoryViewScreen extends StatefulWidget {
  final MemoryRecord memory;

  const MemoryViewScreen({
    super.key,
    required this.memory,
  });

  @override
  State<MemoryViewScreen> createState() => _MemoryViewScreenState();
}

class _MemoryViewScreenState extends State<MemoryViewScreen> {
  final QuestionService _questionService = QuestionService();
  Question? _relatedQuestion;
  bool _isLoadingQuestion = false;

  @override
  void initState() {
    super.initState();
    if (widget.memory.relatedQuestionId != null) {
      _loadRelatedQuestion();
    }
  }

  Future<void> _loadRelatedQuestion() async {
    if (widget.memory.relatedQuestionId == null) return;
    
    setState(() {
      _isLoadingQuestion = true;
    });
    
    try {
      final question = await _questionService.getQuestionById(widget.memory.relatedQuestionId!);
      if (mounted) {
        setState(() {
          _relatedQuestion = question;
          _isLoadingQuestion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuestion = false;
        });
      }
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case '怀念':
        return Colors.purple;
      case '感动':
        return Colors.blue;
      case '开心':
        return Colors.orange;
      case '感慨':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// 获取更深的颜色（用于文本）
  Color _getDarkerColor(Color color) {
    // 如果已经是MaterialColor，使用shade700
    if (color is MaterialColor) {
      return color.shade700;
    }
    // 否则，手动计算一个更深的颜色
    return Color.fromRGBO(
      (color.red * 0.7).round().clamp(0, 255),
      (color.green * 0.7).round().clamp(0, 255),
      (color.blue * 0.7).round().clamp(0, 255),
      1.0,
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case '怀念':
        return Icons.favorite;
      case '感动':
        return Icons.emoji_emotions;
      case '开心':
        return Icons.mood;
      case '感慨':
        return Icons.auto_awesome;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 自定义AppBar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '记忆胶囊',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade400,
                      Colors.pink.shade300,
                      Colors.orange.shade300,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 装饰性圆圈
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    // 中心图标
                    Center(
                      child: Icon(
                        Icons.photo_library_rounded,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoryDetailScreen(
          memory: widget.memory,
        ),
      ),
    );
    if (result == true) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
                },
                tooltip: '编辑回忆',
              ),
            ],
          ),
          
          // 内容区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 回忆内容卡片
                  _buildContentCard(),
                  
                  const SizedBox(height: 20),
                  
                  // 元信息卡片
                  _buildMetaInfoCard(),
                  
                  const SizedBox(height: 20),
                  
                  // 标签卡片
                  if (widget.memory.tags.isNotEmpty) ...[
                    _buildTagsCard(),
                    const SizedBox(height: 20),
                  ],
                  
                  // 关联题目卡片
                  if (_relatedQuestion != null || _isLoadingQuestion) ...[
                    _buildRelatedQuestionCard(),
                    const SizedBox(height: 20),
                  ],
                  
                  // 时间信息
                  _buildTimeInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容卡片
  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '回忆内容',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.memory.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.8,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建元信息卡片
  Widget _buildMetaInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '回忆信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInfoChip(
                icon: Icons.calendar_today,
                label: widget.memory.era,
                color: Colors.blue,
              ),
              _buildInfoChip(
                icon: Icons.category,
                label: widget.memory.category,
                color: Colors.green,
              ),
              _buildInfoChip(
                icon: _getMoodIcon(widget.memory.mood),
                label: widget.memory.mood,
                color: _getMoodColor(widget.memory.mood),
              ),
              if (widget.memory.location != null && widget.memory.location!.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.location_on,
                  label: widget.memory.location!,
                  color: Colors.red,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建信息标签
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _getDarkerColor(color),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签卡片
  Widget _buildTagsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.label_outline,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '标签',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.memory.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.orange.shade300,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建关联题目卡片
  Widget _buildRelatedQuestionCard() {
    if (_isLoadingQuestion) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_relatedQuestion == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '关联题目',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _relatedQuestion!.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建时间信息卡片
  Widget _buildTimeInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                '时间信息',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimeRow(
            '回忆时间',
            DateFormat('yyyy年MM月dd日').format(widget.memory.memoryDate),
            Icons.calendar_month,
          ),
          const SizedBox(height: 8),
          _buildTimeRow(
            '记录时间',
            DateFormat('yyyy年MM月dd日 HH:mm').format(widget.memory.createTime),
            Icons.edit_calendar,
          ),
        ],
      ),
    );
  }

  /// 构建时间行
  Widget _buildTimeRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

