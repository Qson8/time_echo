import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/nostalgic_story.dart';
import '../models/memory_record.dart';
import '../services/story_service.dart';
import '../services/memory_service.dart';
import 'memory_detail_screen.dart';
import 'question_detail_screen.dart';
import '../services/question_service.dart';

/// 时光故事馆页面
class StoryLibraryScreen extends StatefulWidget {
  const StoryLibraryScreen({super.key});

  @override
  State<StoryLibraryScreen> createState() => _StoryLibraryScreenState();
}

class _StoryLibraryScreenState extends State<StoryLibraryScreen>
    with SingleTickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  final QuestionService _questionService = QuestionService();
  final MemoryService _memoryService = MemoryService();
  
  List<NostalgicStory> _stories = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0: 全部, 1: 年代, 2: 分类, 3: 收藏
  String? _selectedEra;
  String? _selectedCategory;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
          _selectedEra = null;
          _selectedCategory = null;
        });
      }
    });
    _loadStories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final stories = await _storyService.getAllStories();
      if (!mounted) return;
      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      print('📖 [StoryLibrary] 加载故事失败: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载故事失败：${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: '重试',
            textColor: Colors.white,
            onPressed: _loadStories,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('时光故事馆'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: '搜索故事',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStories,
            tooltip: '刷新',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
              _selectedEra = null;
              _selectedCategory = null;
            });
          },
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: '全部故事'),
            Tab(text: '80年代'),
            Tab(text: '90年代'),
            Tab(text: '我的收藏'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              '故事馆还是空的',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '精彩的故事正在路上...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    List<NostalgicStory> filteredStories = _stories;

    // 根据选中的Tab筛选故事
    if (_selectedTabIndex == 1) {
      // 80年代
      filteredStories = _stories.where((s) => s.era == '80年代').toList();
    } else if (_selectedTabIndex == 2) {
      // 90年代
      filteredStories = _stories.where((s) => s.era == '90年代').toList();
    } else if (_selectedTabIndex == 3) {
      // 我的收藏
      filteredStories = _stories.where((s) => s.isFavorite).toList();
    }

    if (filteredStories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.book_outlined,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _selectedTabIndex == 3
                    ? '还没有收藏的故事'
                    : '暂无相关故事',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStories.length,
      itemBuilder: (context, index) {
        final story = filteredStories[index];
        return _buildStoryCard(story);
      },
    );
  }

  /// 构建故事卡片
  Widget _buildStoryCard(NostalgicStory story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.photoPaperDecoration,
      child: InkWell(
        onTap: () => _navigateToStoryDetail(context, story),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部信息
              Row(
                children: [
                  // 年代标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(AppConstants.primaryColor)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      story.era,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(AppConstants.primaryColor),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 分类标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      story.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 收藏按钮
                  IconButton(
                    icon: Icon(
                      story.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: story.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(story),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 故事标题
              Text(
                story.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              
              // 故事预览
              Text(
                story.getPreviewText(maxLength: 120),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // 标签
              if (story.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: story.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: Colors.green.withOpacity(0.1),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // 底部信息
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('yyyy-MM-dd').format(story.publishTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (story.author != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      story.author!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (story.relatedQuestionIds.isNotEmpty) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showRelatedQuestions(story),
                      icon: const Icon(Icons.link, size: 14),
                      label: Text(
                        '${story.relatedQuestionIds.length}道相关题目',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(NostalgicStory story) async {
    try {
      await _storyService.toggleFavorite(story.id);
      await _loadStories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 导航到故事详情
  void _navigateToStoryDetail(
    BuildContext context,
    NostalgicStory story,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryDetailScreen(story: story),
      ),
    );
  }

  /// 显示相关题目
  Future<void> _showRelatedQuestions(NostalgicStory story) async {
    if (!mounted) return;
    
    try {
      final questions = await _questionService.getQuestionsByIds(
        story.relatedQuestionIds,
      );

      if (!mounted) return;

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂无相关题目')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    '相关题目',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          question.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(question.echoTheme),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  QuestionDetailScreen(question: question),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载相关题目失败：${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示搜索对话框
  void _showSearchDialog() {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索故事'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: '输入关键词搜索...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) async {
            Navigator.pop(context);
            await _searchStories(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _searchStories(searchController.text);
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  /// 搜索故事
  Future<void> _searchStories(String keyword) async {
    if (keyword.trim().isEmpty) {
      await _loadStories();
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _storyService.searchStories(keyword);
      if (!mounted) return;
      setState(() {
        _stories = results;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('找到 ${results.length} 个相关故事'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('搜索失败：${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// 故事详情页面
class StoryDetailScreen extends StatefulWidget {
  final NostalgicStory story;

  const StoryDetailScreen({super.key, required this.story});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final StoryService _storyService = StoryService();
  final MemoryService _memoryService = MemoryService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.story.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    try {
      await _storyService.toggleFavorite(widget.story.id);
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? '已收藏' : '已取消收藏'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recordMemoryFromStory() async {
    // 根据故事推断年代和分类
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MemoryDetailScreen(
          memory: MemoryRecord(
            id: 0,
            content: '阅读《${widget.story.title}》让我想起了...',
            era: widget.story.era,
            category: widget.story.category,
            memoryDate: DateTime.now(),
            createTime: DateTime.now(),
            mood: '怀念',
            tags: ['故事', ...widget.story.tags],
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('回忆已记录到时光回忆'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('故事详情'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? '取消收藏' : '收藏',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 故事标题
            Text(
              widget.story.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColor),
              ),
            ),
            const SizedBox(height: 16),

            // 标签信息
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryColor)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(AppConstants.primaryColor),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.story.era,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(AppConstants.primaryColor),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.story.category,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 故事内容
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.photoPaperDecoration,
              child: Text(
                widget.story.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: Colors.black87,
                ),
              ),
            ),

            // 标签
            if (widget.story.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                '标签',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.story.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.green),
                  );
                }).toList(),
              ),
            ],

            // 相关信息
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '发布于 ${DateFormat('yyyy年MM月dd日').format(widget.story.publishTime)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // 相关题目
            if (widget.story.relatedQuestionIds.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                '相关题目',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final questionService = QuestionService();
                  final questions = await questionService.getQuestionsByIds(
                    widget.story.relatedQuestionIds,
                  );
                  if (questions.isNotEmpty && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            QuestionDetailScreen(question: questions.first),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.quiz),
                label: Text('查看 ${widget.story.relatedQuestionIds.length} 道相关题目'),
              ),
            ],

            const SizedBox(height: 32),

            // 记录回忆按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _recordMemoryFromStory,
                icon: const Icon(Icons.edit),
                label: const Text('记录这段故事带来的回忆'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


