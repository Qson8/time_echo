import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/memory_capsule.dart';
import '../services/memory_capsule_service.dart';
import '../services/question_service.dart';
import '../models/question.dart';
import '../utils/theme_adapter.dart';

/// 记忆胶囊创建/编辑页面
class MemoryCapsuleCreationScreen extends StatefulWidget {
  final MemoryCapsule? capsule; // 如果为null，则是新建；否则是编辑

  const MemoryCapsuleCreationScreen({
    super.key,
    this.capsule,
  });

  @override
  State<MemoryCapsuleCreationScreen> createState() => _MemoryCapsuleCreationScreenState();
}

class _MemoryCapsuleCreationScreenState extends State<MemoryCapsuleCreationScreen> {
  final MemoryCapsuleService _service = MemoryCapsuleService();
  final QuestionService _questionService = QuestionService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedEra = '80年代';
  String _selectedCategory = '影视';
  String _selectedMood = '怀念';
  DateTime? _selectedMemoryDate;
  List<String> _tags = [];
  int? _relatedQuestionId;
  Question? _relatedQuestion;

  bool _isSaving = false;

  final List<String> _eras = ['80年代', '90年代', '00年代'];
  final List<String> _categories = ['影视', '音乐', '事件'];
  final List<String> _moods = ['怀念', '感动', '开心', '感慨'];

  @override
  void initState() {
    super.initState();
    if (widget.capsule != null) {
      _initializeFromCapsule(widget.capsule!);
    }
  }

  void _initializeFromCapsule(MemoryCapsule capsule) {
    _titleController.text = capsule.title ?? ''; // 标题可能为null
    _contentController.text = capsule.content;
    _selectedEra = capsule.era;
    _selectedCategory = capsule.category;
    _selectedMood = capsule.mood;
    _selectedMemoryDate = capsule.memoryDate;
    _locationController.text = capsule.location ?? '';
    _tags = List.from(capsule.tags);
    _relatedQuestionId = capsule.questionId;

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
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    super.dispose();
  }


  /// 添加标签
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  /// 删除标签
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  /// 选择记忆日期
  Future<void> _selectMemoryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedMemoryDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: '选择这段记忆的时间',
    );

    if (date != null) {
      setState(() {
        _selectedMemoryDate = date;
      });
    }
  }

  /// 选择关联题目
  Future<void> _selectRelatedQuestion() async {
    // 加载所有题目
    final allQuestions = await _questionService.getAllQuestions();
    
    if (allQuestions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂无题目')),
        );
      }
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

  /// 保存记忆胶囊
  Future<void> _saveCapsule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.initialize();

      // 判断是新建还是编辑：id为0或null表示新建，否则为编辑
      final isNew = widget.capsule == null || widget.capsule!.id == 0;
      
      final capsule = MemoryCapsule(
        id: widget.capsule?.id ?? 0,
        questionId: _relatedQuestionId,
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(), // 标题可选
        content: _contentController.text.trim(),
        imagePath: isNew ? null : widget.capsule?.imagePath, // 新建时无图片，编辑时保留已有图片
        audioPath: isNew ? null : widget.capsule?.audioPath, // 新建时无音频，编辑时保留已有音频
        createdAt: widget.capsule?.createdAt ?? DateTime.now(),
        memoryDate: _selectedMemoryDate,
        tags: _tags,
        era: _selectedEra,
        category: _selectedCategory,
        mood: _selectedMood,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      if (isNew) {
        await _service.addCapsule(capsule);
      } else {
        await _service.updateCapsule(capsule);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.pop(context, true); // 返回true表示保存成功
      }
    } catch (e, stackTrace) {
      print('保存记忆胶囊失败: $e');
      print('错误堆栈: $stackTrace');
      if (mounted) {
        String errorMessage = '保存失败';
        if (e.toString().contains('存储') || e.toString().contains('存储空间')) {
          errorMessage = '存储空间不足，请清理空间后重试';
        } else if (e.toString().contains('权限')) {
          errorMessage = '需要存储权限，请在设置中开启';
        } else {
          errorMessage = '保存失败：${e.toString()}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.capsule == null ? '记忆胶囊' : '编辑胶囊'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 记忆内容
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '记忆内容',
                  hintText: '写下这段让你怀念的时光...',
                  border: OutlineInputBorder(),
                  helperText: '记录下那些珍贵的记忆吧～',
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入记忆内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 标题（可选）
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '记忆标题（可选）',
                  hintText: '给这段记忆起个标题，留空则使用内容预览',
                  border: OutlineInputBorder(),
                ),
                // 标题可选，不需要验证
              ),
              const SizedBox(height: 24),

              // 年代选择
              Builder(
                builder: (context) => Text(
                  '年代',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeAdapter.getTextColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _eras.map((era) {
                  final isSelected = _selectedEra == era;
                  return FilterChip(
                    label: Builder(
                      builder: (context) => Text(
                        era,
                        style: TextStyle(
                          color: isSelected 
                              ? ThemeAdapter.getPrimaryColor(context)
                              : ThemeAdapter.getTextColor(context),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedEra = era;
                        });
                      }
                    },
                    selectedColor: const Color(AppConstants.primaryColor).withOpacity(0.2),
                    backgroundColor: ThemeAdapter.getSurfaceColor(context),
                    checkmarkColor: const Color(AppConstants.primaryColor),
                    side: BorderSide(
                      color: isSelected 
                          ? const Color(AppConstants.primaryColor)
                          : Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 分类选择
              Builder(
                builder: (context) => Text(
                  '分类',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeAdapter.getTextColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return FilterChip(
                    label: Builder(
                      builder: (context) => Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.green : ThemeAdapter.getTextColor(context),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: Colors.green.withOpacity(0.2),
                    backgroundColor: ThemeAdapter.getSurfaceColor(context),
                    checkmarkColor: Colors.green,
                    side: BorderSide(
                      color: isSelected ? Colors.green : Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 心情选择
              Builder(
                builder: (context) => Text(
                  '心情',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeAdapter.getTextColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood;
                  return FilterChip(
                    label: Builder(
                      builder: (context) => Text(
                        mood,
                        style: TextStyle(
                          color: isSelected ? Colors.orange : ThemeAdapter.getTextColor(context),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedMood = mood;
                        });
                      }
                    },
                    selectedColor: Colors.orange.withOpacity(0.2),
                    backgroundColor: ThemeAdapter.getSurfaceColor(context),
                    checkmarkColor: Colors.orange,
                    side: BorderSide(
                      color: isSelected ? Colors.orange : Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 记忆时间
              Builder(
                builder: (context) => ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: ThemeAdapter.getIconColor(context),
                  ),
                  title: Text(
                    '记忆时间',
                    style: TextStyle(
                      color: ThemeAdapter.getTextColor(context),
                    ),
                  ),
                  subtitle: Text(
                    _selectedMemoryDate == null
                        ? '未设置'
                        : DateFormat('yyyy年MM月dd日').format(_selectedMemoryDate!),
                    style: TextStyle(
                      color: ThemeAdapter.getSecondaryTextColor(context),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: ThemeAdapter.getSecondaryTextColor(context),
                  ),
                  onTap: _selectMemoryDate,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),

              // 地点（可选）
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '地点（可选）',
                  hintText: '如：家乡、大学、工作地...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),

              // 标签
              Builder(
                builder: (context) => Text(
                  '标签',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeAdapter.getTextColor(context),
                  ),
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
                    return Builder(
                      builder: (context) => Chip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            color: ThemeAdapter.getTextColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onDeleted: () => _removeTag(tag),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        deleteIconColor: Colors.blue,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),

              // 关联题目
              if (_relatedQuestion != null)
                Builder(
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeAdapter.getAccentColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ThemeAdapter.getAccentColor(context).withOpacity(0.3)),
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
                  ),
                )
              else
                Builder(
                  builder: (context) => OutlinedButton.icon(
                    onPressed: _selectRelatedQuestion,
                    icon: const Icon(Icons.link),
                    label: const Text('关联题目（可选）'),
                  ),
                ),
              const SizedBox(height: 32),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCapsule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '保存记忆胶囊',
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
        return Builder(
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: ThemeAdapter.getSurfaceColor(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  child: Builder(
                    builder: (context) => TextField(
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
                        fillColor: ThemeAdapter.getDividerColor(context).withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: ThemeAdapter.getBorderColor(context).withOpacity(0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                        child: Builder(
                          builder: (context) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: ThemeAdapter.getDividerColor(context).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCategoryFilter,
                              isExpanded: true,
                              hint: Builder(
                                builder: (context) => Text(
                                  '所有分类',
                                  style: TextStyle(
                                    color: ThemeAdapter.getSecondaryTextColor(context),
                                  ),
                                ),
                              ),
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
                      ),
                      const SizedBox(width: 8),
                      // 年代筛选
                      Expanded(
                        child: Builder(
                          builder: (context) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: ThemeAdapter.getDividerColor(context).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedEraFilter,
                              isExpanded: true,
                              hint: Builder(
                                builder: (context) => Text(
                                  '所有年代',
                                  style: TextStyle(
                                    color: ThemeAdapter.getSecondaryTextColor(context),
                                  ),
                                ),
                              ),
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
                      Builder(
                        builder: (context) => Text(
                          '找到 ${filteredQuestions.length} 道题目',
                          style: TextStyle(
                            fontSize: 14,
                            color: ThemeAdapter.getSecondaryTextColor(context),
                          ),
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
                            Builder(
                              builder: (context) => Text(
                                '没有找到相关题目',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ThemeAdapter.getSecondaryTextColor(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) => Text(
                                '试试调整搜索条件',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ThemeAdapter.getSecondaryTextColor(context),
                                ),
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
                                        Builder(
                                          builder: (context) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: ThemeAdapter.getDividerColor(context).withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              question.echoTheme,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: ThemeAdapter.getSecondaryTextColor(context),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // 题目内容
                                    Builder(
                                      builder: (context) => Text(
                                        question.content,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                          color: ThemeAdapter.getTextColor(context),
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                        Builder(
                                          builder: (context) => Text(
                                            question.difficulty,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: ThemeAdapter.getSecondaryTextColor(context),
                                            ),
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
          ),
        );
      },
    );
  }
}
