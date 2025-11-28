import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/memory_record.dart';
import '../services/memory_service.dart';
import '../services/question_service.dart';
import '../models/question.dart';

/// 回忆详情/编辑页面
class MemoryDetailScreen extends StatefulWidget {
  final MemoryRecord? memory; // 如果为null，则是新建；否则是编辑

  const MemoryDetailScreen({super.key, this.memory});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final MemoryService _memoryService = MemoryService();
  final QuestionService _questionService = QuestionService();
  
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  
  String _selectedEra = '80年代';
  String _selectedCategory = '影视';
  String _selectedMood = '怀念';
  DateTime _selectedMemoryDate = DateTime.now();
  String? _location;
  List<String> _tags = [];
  final _tagController = TextEditingController();
  int? _relatedQuestionId;
  Question? _relatedQuestion;

  final List<String> _eras = ['80年代', '90年代', '00年代'];
  final List<String> _categories = ['影视', '音乐', '事件'];
  final List<String> _moods = ['怀念', '感动', '开心', '感慨'];

  @override
  void initState() {
    super.initState();
    if (widget.memory != null) {
      _initializeFromMemory(widget.memory!);
    }
  }

  void _initializeFromMemory(MemoryRecord memory) {
    _contentController.text = memory.content;
    _selectedEra = memory.era;
    _selectedCategory = memory.category;
    _selectedMood = memory.mood;
    _selectedMemoryDate = memory.memoryDate;
    _location = memory.location;
    _tags = List.from(memory.tags);
    _relatedQuestionId = memory.relatedQuestionId;
    
    if (_relatedQuestionId != null) {
      _loadRelatedQuestion();
    }
  }

  Future<void> _loadRelatedQuestion() async {
    if (_relatedQuestionId != null) {
      final question = await _questionService.getQuestionById(_relatedQuestionId!);
      setState(() {
        _relatedQuestion = question;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _selectMemoryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMemoryDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: '选择这段回忆的时间',
    );
    
    if (picked != null) {
      setState(() {
        _selectedMemoryDate = picked;
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _selectRelatedQuestion() async {
    // 加载所有题目
    final allQuestions = await _questionService.getAllQuestions();
    
    if (allQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无题目')),
      );
      return;
    }

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionSelectionDialog(
        questions: allQuestions,
        selectedCategory: _selectedCategory,
        selectedEra: _selectedEra,
      ),
    );

    if (selected != null) {
      setState(() {
        _relatedQuestionId = selected;
      });
      await _loadRelatedQuestion();
    }
  }

  Future<void> _saveMemory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // 如果memory存在且id不为0，则是更新；否则是新建
      if (widget.memory != null && widget.memory!.id != 0) {
        // 更新现有回忆
        final updatedMemory = widget.memory!.copyWith(
          content: _contentController.text.trim(),
          era: _selectedEra,
          category: _selectedCategory,
          mood: _selectedMood,
          memoryDate: _selectedMemoryDate,
          location: _location,
          tags: _tags,
          relatedQuestionId: _relatedQuestionId,
        );
        await _memoryService.updateMemory(updatedMemory);
      } else {
        // 创建新回忆
        await _memoryService.createMemory(
          content: _contentController.text.trim(),
          relatedQuestionId: _relatedQuestionId,
          era: _selectedEra,
          category: _selectedCategory,
          tags: _tags,
          memoryDate: _selectedMemoryDate,
          mood: _selectedMood,
          location: _location,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('回忆已保存'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // 返回true表示保存成功
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMemory() async {
    if (widget.memory == null || widget.memory!.id == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除回忆'),
        content: const Text('确定要删除这段回忆吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _memoryService.removeMemory(widget.memory!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('回忆已删除'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败：$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memory == null ? '记忆胶囊' : '编辑胶囊'),
        centerTitle: true,
        actions: [
          if (widget.memory != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteMemory,
              tooltip: '删除',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 回忆内容
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '回忆内容',
                  hintText: '写下这段让你怀念的时光...',
                  border: OutlineInputBorder(),
                  helperText: '记录下那些珍贵的回忆吧～',
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入回忆内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 年代选择
              const Text(
                '年代',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _eras.map((era) {
                  final isSelected = _selectedEra == era;
                  return FilterChip(
                    label: Text(era),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedEra = era;
                        });
                      }
                    },
                    selectedColor: const Color(AppConstants.primaryColor)
                        .withOpacity(0.2),
                    checkmarkColor: const Color(AppConstants.primaryColor),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 分类选择
              const Text(
                '分类',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: Colors.green.withOpacity(0.2),
                    checkmarkColor: Colors.green,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 心情选择
              const Text(
                '心情',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood;
                  return FilterChip(
                    label: Text(mood),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedMood = mood;
                        });
                      }
                    },
                    selectedColor: Colors.orange.withOpacity(0.2),
                    checkmarkColor: Colors.orange,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 回忆时间
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('回忆时间'),
                subtitle: Text(DateFormat('yyyy年MM月dd日').format(_selectedMemoryDate)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectMemoryDate,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // 地点（可选）
              TextFormField(
                initialValue: _location,
                decoration: const InputDecoration(
                  labelText: '地点（可选）',
                  hintText: '如：家乡、大学、工作地...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                onChanged: (value) {
                  _location = value.trim().isEmpty ? null : value.trim();
                },
              ),
              const SizedBox(height: 24),

              // 标签
              const Text(
                '标签',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: '输入标签，如：初恋、大学、青春...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTag,
                    tooltip: '添加标签',
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      deleteIconColor: Colors.blue,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),

              // 关联题目
              if (_relatedQuestion != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '关联题目',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _relatedQuestionId = null;
                                _relatedQuestion = null;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _relatedQuestion!.content,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _selectRelatedQuestion,
                  icon: const Icon(Icons.link),
                  label: const Text('关联题目（可选）'),
                ),
              const SizedBox(height: 32),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMemory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '保存回忆',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 题目选择弹窗组件
class _QuestionSelectionDialog extends StatefulWidget {
  final List<Question> questions;
  final String selectedCategory;
  final String selectedEra;

  const _QuestionSelectionDialog({
    required this.questions,
    required this.selectedCategory,
    required this.selectedEra,
  });

  @override
  State<_QuestionSelectionDialog> createState() => _QuestionSelectionDialogState();
}

class _QuestionSelectionDialogState extends State<_QuestionSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryFilter;
  String? _selectedEraFilter;

  @override
  void initState() {
    super.initState();
    _selectedCategoryFilter = widget.selectedCategory;
    _selectedEraFilter = widget.selectedEra;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Question> get _filteredQuestions {
    return widget.questions.where((question) {
      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesContent = question.content.toLowerCase().contains(query);
        final matchesTheme = question.echoTheme.toLowerCase().contains(query);
        final matchesCategory = question.category.toLowerCase().contains(query);
        if (!matchesContent && !matchesTheme && !matchesCategory) {
          return false;
        }
      }
      
      // 分类过滤
      if (_selectedCategoryFilter != null && _selectedCategoryFilter!.isNotEmpty) {
        if (question.category != _selectedCategoryFilter) {
          return false;
        }
      }
      
      // 年代过滤
      if (_selectedEraFilter != null && _selectedEraFilter!.isNotEmpty) {
        if (!question.echoTheme.contains(_selectedEraFilter!.substring(0, 2))) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '影视':
        return Colors.purple;
      case '音乐':
        return Colors.blue;
      case '事件':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuestions = _filteredQuestions;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(AppConstants.primaryColor),
                      const Color(AppConstants.primaryColor).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.quiz, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '选择关联题目',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // 搜索框
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索题目内容、分类或主题...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              
              // 筛选器
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // 分类筛选
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCategoryFilter,
                          isExpanded: true,
                          hint: const Text('所有分类'),
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('所有分类'),
                            ),
                            ...['影视', '音乐', '事件'].map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryFilter = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 年代筛选
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedEraFilter,
                          isExpanded: true,
                          hint: const Text('所有年代'),
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('所有年代'),
                            ),
                            ...['80年代', '90年代', '00年代'].map((era) {
                              return DropdownMenuItem<String>(
                                value: era,
                                child: Text(era),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedEraFilter = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 结果统计
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '找到 ${filteredQuestions.length} 道题目',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 题目列表
              Expanded(
                child: filteredQuestions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '没有找到相关题目',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '试试调整搜索条件',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredQuestions.length,
                        itemBuilder: (context, index) {
                          final question = filteredQuestions[index];
                          final categoryColor = _getCategoryColor(question.category);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => Navigator.pop(context, question.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 分类和主题标签
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: categoryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            question.category,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: categoryColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            question.echoTheme,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // 题目内容
                                    Text(
                                      question.content,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    // 难度标签
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: question.difficulty == '困难'
                                              ? Colors.orange
                                              : question.difficulty == '中等'
                                                  ? Colors.amber
                                                  : Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          question.difficulty,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

