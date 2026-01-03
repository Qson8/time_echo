import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../services/echo_collection_service.dart';
import '../models/question.dart';
import 'question_detail_screen.dart';
import 'quiz_screen.dart';
import 'quiz_config_screen.dart';
import '../utils/theme_adapter.dart';

/// 收藏页面
class CollectionScreen extends StatefulWidget {
  final bool hideAppBar;
  
  const CollectionScreen({super.key, this.hideAppBar = false});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  bool _isBatchMode = false;
  final Set<int> _selectedQuestions = <int>{};
  DateTime? _lastRefreshTime;
  
  // 筛选相关状态
  bool _isFiltering = false;
  String? _selectedCategory;
  String? _selectedEra;
  
  // 收藏时间映射表（questionId -> collectionTime）
  Map<int, DateTime> _collectionTimeMap = {};
  final _collectionService = EchoCollectionService();

  @override
  void initState() {
    super.initState();
    // 页面打开时刷新收藏数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCollections();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当页面重新获得焦点时刷新收藏数据（避免过度刷新，至少间隔1秒）
    final now = DateTime.now();
    if (_lastRefreshTime == null || 
        now.difference(_lastRefreshTime!).inSeconds > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshCollections();
      });
      _lastRefreshTime = now;
    }
  }

  /// 刷新收藏数据
  Future<void> _refreshCollections() async {
    if (!mounted) return;
    
    print('📚 [CollectionScreen] 开始刷新收藏数据...');
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    // 运行诊断以检查数据完整性（仅在调试时）
    try {
      final diagnoseResult = await appState.diagnoseCollectionData();
      
      print('📚 [CollectionScreen] 诊断结果:');
      print('📚   - 收藏记录总数: ${diagnoseResult['total_collections'] ?? 0}');
      print('📚   - 有效收藏数: ${diagnoseResult['valid_collections'] ?? 0}');
      print('📚   - 数据有效性: ${diagnoseResult['is_valid'] ?? false}');
      
      if (diagnoseResult['missing_question_ids'] != null && 
          (diagnoseResult['missing_question_ids'] as List).isNotEmpty) {
        print('📚 ⚠️ 警告：存在 ${(diagnoseResult['missing_question_ids'] as List).length} 个无效的收藏（题目不存在）');
      }
    } catch (e) {
      print('📚 [CollectionScreen] ⚠️ 诊断失败: $e');
    }
    
    // 强制重新加载收藏数据
    await appState.refreshCollections();
    print('📚 [CollectionScreen] 刷新完成，当前收藏数: ${appState.collectedQuestions.length}');
    
    // 加载收藏时间映射表
    _collectionTimeMap = await _collectionService.getCollectionTimeMap();
    print('📚 [CollectionScreen] 加载收藏时间映射表，共 ${_collectionTimeMap.length} 条记录');
    
    // 更新最后刷新时间
    _lastRefreshTime = DateTime.now();
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 在 build 方法中获取 Provider 状态，确保按钮能响应 _isBatchMode 变化
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final hasCollections = appState.collectedQuestions.isNotEmpty;
    
    // 调试信息
    print('🔍 [CollectionScreen] build: _isBatchMode=$_isBatchMode, hasCollections=$hasCollections');
    
    // 根据批量模式构建不同的 actions
    List<Widget> appBarActions = [];
    if (hasCollections) {
      if (_isBatchMode) {
        // 批量模式下只显示关闭按钮
        print('🔍 [CollectionScreen] 构建关闭按钮，_isBatchMode=$_isBatchMode');
        appBarActions.add(
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                print('🔍 [CollectionScreen] 关闭按钮被点击');
                setState(() {
                  _isBatchMode = false;
                  _selectedQuestions.clear();
                });
              },
              tooltip: '退出选择',
            ),
          ),
        );
      } else {
        // 非批量模式下显示筛选和批量操作按钮
        print('🔍 [CollectionScreen] 构建筛选和批量操作按钮，_isBatchMode=$_isBatchMode');
        appBarActions.addAll([
          IconButton(
            icon: Icon(
              _isFiltering ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _isFiltering 
                  ? const Color(AppConstants.primaryColor)
                  : null,
            ),
            onPressed: () {
              _showFilterBottomSheet();
            },
            tooltip: '筛选',
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () {
              print('🔍 [CollectionScreen] 批量操作按钮被点击，当前 _isBatchMode=$_isBatchMode');
              setState(() {
                _isBatchMode = true;
                print('🔍 [CollectionScreen] _isBatchMode 设置为 true');
              });
            },
            tooltip: '批量操作',
          ),
        ]);
      }
    } else {
      print('🔍 [CollectionScreen] 没有收藏，不显示按钮');
    }
    
    print('🔍 [CollectionScreen] appBarActions 数量: ${appBarActions.length}');
    print('🔍 [CollectionScreen] widget.hideAppBar: ${widget.hideAppBar}');
    
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('拾光收藏夹'),
        centerTitle: true,
        actions: appBarActions,
        // 添加调试信息，确保 AppBar 被正确创建
        automaticallyImplyLeading: true,
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (appState.collectedQuestions.isEmpty) {
            return _buildEmptyState();
          }

          // 获取筛选后的题目列表
          final filteredQuestions = _getFilteredQuestions(appState.collectedQuestions);

          return Column(
            children: [
              // 批量操作栏
              if (_isBatchMode) _buildBatchActionBar(appState),
              
              // 筛选状态栏
              if (_isFiltering) _buildFilterStatusBar(),
              
              // 如果没有 AppBar，在顶部添加按钮
              if (widget.hideAppBar && appState.collectedQuestions.isNotEmpty)
                Builder(
                  builder: (context) {
                    print('🔍 [CollectionScreen] 构建顶部按钮栏，_isBatchMode=$_isBatchMode');
                    if (_isBatchMode) {
                      print('🔍 [CollectionScreen] 添加关闭按钮到顶部');
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: ThemeAdapter.getSurfaceColor(context),
                        border: Border(
                          bottom: BorderSide(
                            color: ThemeAdapter.getDividerColor(context),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 批量模式下显示关闭按钮
                          if (_isBatchMode)
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                              onPressed: () {
                                print('🔍 [CollectionScreen] 顶部关闭按钮被点击');
                                setState(() {
                                  _isBatchMode = false;
                                  _selectedQuestions.clear();
                                });
                              },
                              tooltip: '退出选择',
                            )
                          else
                            // 非批量模式下显示批量操作按钮
                            IconButton(
                              icon: const Icon(Icons.checklist),
                              onPressed: () {
                                setState(() {
                                  _isBatchMode = true;
                                });
                              },
                              tooltip: '批量操作',
                            ),
                        ],
                      ),
                    );
                  },
                ),
              
              // 收藏列表
              Expanded(
                child: filteredQuestions.isEmpty
                    ? _buildEmptyFilterState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredQuestions.length,
                        itemBuilder: (context, index) {
                          final question = filteredQuestions[index];
                          return _buildCollectionCard(question, appState);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }


  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(
              builder: (context) => Icon(
                Icons.favorite_border,
                size: 80,
                color: ThemeAdapter.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 24),
            Builder(
              builder: (context) => Text(
                '还未收藏拾光题目',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeAdapter.getSecondaryTextColor(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) => Text(
                '快去答题收藏你的专属时光记忆吧～',
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeAdapter.getSecondaryTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // 和首页"开始拾光"按钮逻辑一样，导航到定制页面
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const QuizConfigScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
              ),
              child: const Text('开始答题'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建批量操作栏
  Widget _buildBatchActionBar(AppStateProvider appState) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ThemeAdapter.isDarkMode(context)
              ? const Color(AppConstants.primaryColor).withOpacity(0.15)
              : const Color(AppConstants.primaryColor).withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: const Color(AppConstants.primaryColor).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Flexible(
              child: Text(
                '已选择 ${_selectedQuestions.length} 项',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ThemeAdapter.getTextColor(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextButton(
                onPressed: _selectedQuestions.isNotEmpty
                    ? () => _removeSelectedQuestions(appState)
                    : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('取消收藏', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: TextButton(
                onPressed: _selectedQuestions.isNotEmpty
                    ? () => _shareSelectedQuestions()
                    : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('分享', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建收藏卡片
  Widget _buildCollectionCard(Question question, AppStateProvider appState) {
    final isSelected = _selectedQuestions.contains(question.id);
    
    return GestureDetector(
      onTap: () {
        if (_isBatchMode) {
          setState(() {
            if (isSelected) {
              _selectedQuestions.remove(question.id);
            } else {
              _selectedQuestions.add(question.id);
            }
          });
        } else {
          _showQuestionDetail(question);
        }
      },
      onLongPress: () {
        if (!_isBatchMode) {
          setState(() {
            _isBatchMode = true;
            _selectedQuestions.add(question.id);
          });
        }
      },
      child: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.photoPaperDecoration.copyWith(
            color: isSelected 
                ? const Color(AppConstants.primaryColor).withOpacity(0.1)
                : ThemeAdapter.getSurfaceColor(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 卡片头部
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 分类和难度标签
                    _buildCategoryTag(question.category),
                    const SizedBox(width: 8),
                    _buildDifficultyTag(question.difficulty),
                    const Spacer(),
                    
                    // 选择框
                    if (_isBatchMode)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected 
                              ? const Color(AppConstants.primaryColor)
                              : Colors.transparent,
                          border: Border.all(
                            color: const Color(AppConstants.primaryColor),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    
                    // 收藏图标
                    if (!_isBatchMode)
                      Icon(
                        Icons.star,
                        color: ThemeAdapter.getAccentColor(context),
                        size: 20,
                      ),
                  ],
                ),
              ),
              
              // 题目内容
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  question.content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: ThemeAdapter.getTextColor(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // 卡片底部
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    // 主题标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.echoTheme,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(AppConstants.primaryColor),
                        ),
                      ),
                    ),
                    const Spacer(),
                    
                    // 收藏时间
                    Builder(
                      builder: (context) {
                        // 使用收藏时间，如果没有则使用题目创建时间作为后备
                        final collectionTime = _collectionTimeMap[question.id] ?? question.createdAt;
                        return Text(
                          '收藏于 ${_formatDate(collectionTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeAdapter.getSecondaryTextColor(context),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建分类标签
  Widget _buildCategoryTag(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(AppConstants.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(AppConstants.primaryColor),
          width: 1,
        ),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 10,
          color: Color(AppConstants.primaryColor),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建难度标签
  Widget _buildDifficultyTag(String difficulty) {
    Color color;
    switch (difficulty) {
      case '简单':
        color = Colors.green;
        break;
      case '中等':
        color = Colors.orange;
        break;
      case '困难':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 显示题目详情
  void _showQuestionDetail(Question question) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestionDetailScreen(question: question),
      ),
    );
  }

  /// 移除选中的题目
  Future<void> _removeSelectedQuestions(AppStateProvider appState) async {
    if (_selectedQuestions.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要取消收藏这 ${_selectedQuestions.length} 道题目吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final questionId in _selectedQuestions) {
        await appState.toggleCollection(questionId);
      }
      
      setState(() {
        _selectedQuestions.clear();
        _isBatchMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消收藏')),
        );
      }
    }
  }

  /// 分享选中的题目
  void _shareSelectedQuestions() {
    if (_selectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要分享的题目')),
      );
      return;
    }
    
    // 生成分享内容
    final shareContent = _generateShareContent();
    
    // 显示分享对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分享拾光题目'),
        content: SingleChildScrollView(
          child: Text(shareContent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享内容已复制到剪贴板')),
              );
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }

  /// 生成分享内容
  String _generateShareContent() {
    final buffer = StringBuffer();
    buffer.writeln('🌟 来自拾光机的怀旧题目分享 🌟\n');
    
    int index = 1;
    for (final questionId in _selectedQuestions) {
      // 通过ID找到对应的题目对象
      final question = Provider.of<AppStateProvider>(context, listen: false)
          .collectedQuestions
          .firstWhere((q) => q.id == questionId);
      
      buffer.writeln('$index. ${question.content}');
      buffer.writeln('   分类：${question.category} | 难度：${question.difficulty}');
      buffer.writeln();
      index++;
    }
    
    buffer.writeln('📱 拾光机 - 离线怀旧问答应用');
    buffer.writeln('💫 通过题目唤醒你的时光记忆');
    
    return buffer.toString();
  }

  /// 获取筛选后的题目列表
  List<Question> _getFilteredQuestions(List<Question> questions) {
    if (!_isFiltering) {
      return questions;
    }

    return questions.where((question) {
      // 分类筛选
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (question.category != _selectedCategory) {
          return false;
        }
      }

      // 年代筛选
      if (_selectedEra != null && _selectedEra!.isNotEmpty) {
        if (!question.echoTheme.contains(_selectedEra!)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// 构建筛选状态栏
  Widget _buildFilterStatusBar() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ThemeAdapter.isDarkMode(context)
              ? const Color(AppConstants.primaryColor).withOpacity(0.1)
              : const Color(AppConstants.primaryColor).withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: const Color(AppConstants.primaryColor).withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_alt,
              size: 16,
              color: ThemeAdapter.getTextColor(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _buildFilterText(),
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeAdapter.getTextColor(context),
                ),
              ),
            ),
            TextButton(
              onPressed: _resetFilter,
              child: const Text('清除'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建筛选文本
  String _buildFilterText() {
    final List<String> filters = [];
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filters.add('分类：$_selectedCategory');
    }
    if (_selectedEra != null && _selectedEra!.isNotEmpty) {
      filters.add('年代：$_selectedEra');
    }
    return filters.isEmpty ? '未设置筛选条件' : filters.join(' | ');
  }

  /// 构建空筛选状态
  Widget _buildEmptyFilterState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(
              builder: (context) => Icon(
                Icons.filter_alt_off,
                size: 80,
                color: ThemeAdapter.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 24),
            Builder(
              builder: (context) => Text(
                '没有符合条件的收藏',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeAdapter.getSecondaryTextColor(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) => Text(
                '请尝试调整筛选条件',
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeAdapter.getSecondaryTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _resetFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
              ),
              child: const Text('清除筛选'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示筛选底部面板
  void _showFilterBottomSheet() {
    String? tempCategory = _selectedCategory;
    String? tempEra = _selectedEra;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Builder(
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: ThemeAdapter.getSurfaceColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeAdapter.getDividerColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '筛选条件',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ThemeAdapter.getTextColor(context),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: ThemeAdapter.getTextColor(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 筛选选项
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分类筛选
                    Text(
                      '分类',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ThemeAdapter.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                          '全部',
                          tempCategory == null,
                          () {
                            setState(() {
                              tempCategory = null;
                            });
                          },
                        ),
                        _buildFilterChip(
                          '影视',
                          tempCategory == '影视',
                          () {
                            setState(() {
                              tempCategory = '影视';
                            });
                          },
                        ),
                        _buildFilterChip(
                          '音乐',
                          tempCategory == '音乐',
                          () {
                            setState(() {
                              tempCategory = '音乐';
                            });
                          },
                        ),
                        _buildFilterChip(
                          '事件',
                          tempCategory == '事件',
                          () {
                            setState(() {
                              tempCategory = '事件';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 年代筛选
                    Text(
                      '年代',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ThemeAdapter.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                          '全部',
                          tempEra == null,
                          () {
                            setState(() {
                              tempEra = null;
                            });
                          },
                        ),
                        _buildFilterChip(
                          '80年代',
                          tempEra == '80年代',
                          () {
                            setState(() {
                              tempEra = '80年代';
                            });
                          },
                        ),
                        _buildFilterChip(
                          '90年代',
                          tempEra == '90年代',
                          () {
                            setState(() {
                              tempEra = '90年代';
                            });
                          },
                        ),
                        _buildFilterChip(
                          '00年代',
                          tempEra == '00年代',
                          () {
                            setState(() {
                              tempEra = '00年代';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 操作按钮
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            tempCategory = null;
                            tempEra = null;
                          });
                        },
                        child: const Text('重置'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = tempCategory;
                            _selectedEra = tempEra;
                            _isFiltering = tempCategory != null || tempEra != null;
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppConstants.primaryColor),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('确定'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建筛选芯片
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Builder(
      builder: (context) => FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(AppConstants.primaryColor).withOpacity(0.2),
        checkmarkColor: const Color(AppConstants.primaryColor),
        labelStyle: TextStyle(
          color: isSelected
              ? const Color(AppConstants.primaryColor)
              : ThemeAdapter.getTextColor(context),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected
              ? const Color(AppConstants.primaryColor)
              : ThemeAdapter.getDividerColor(context),
          width: isSelected ? 1.5 : 1,
        ),
      ),
    );
  }

  /// 重置筛选
  void _resetFilter() {
    setState(() {
      _selectedCategory = null;
      _selectedEra = null;
      _isFiltering = false;
    });
  }
}
