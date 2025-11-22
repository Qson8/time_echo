import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../services/app_state_provider.dart';
import '../models/question.dart';
import 'question_detail_screen.dart';
import 'quiz_screen.dart';
import 'quiz_config_screen.dart';

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

  @override
  void initState() {
    super.initState();
    // 页面打开时刷新收藏数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCollections();
    });
  }

  /// 刷新收藏数据
  Future<void> _refreshCollections() async {
    print('📚 [CollectionScreen] 开始刷新收藏数据...');
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    // 运行诊断以检查数据完整性
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('拾光收藏夹'),
        centerTitle: true,
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              if (appState.collectedQuestions.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return IconButton(
                icon: Icon(_isBatchMode ? Icons.close : Icons.checklist),
                onPressed: () {
                  setState(() {
                    _isBatchMode = !_isBatchMode;
                    if (!_isBatchMode) {
                      _selectedQuestions.clear();
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (appState.collectedQuestions.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // 批量操作栏
              if (_isBatchMode) _buildBatchActionBar(appState),
              
              // 如果没有 AppBar，在顶部添加批量操作按钮
              if (widget.hideAppBar && !_isBatchMode && appState.collectedQuestions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                ),
              
              // 收藏列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appState.collectedQuestions.length,
                  itemBuilder: (context, index) {
                    final question = appState.collectedQuestions[index];
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
            const Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              '还未收藏拾光题目',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '快去答题收藏你的专属时光记忆吧～',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // 和首页"开始拾光"按钮逻辑一样，导航到定制页面
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const QuizConfigScreen()),
                );
              },
              child: const Text('开始答题'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建批量操作栏
  Widget _buildBatchActionBar(AppStateProvider appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(AppConstants.primaryColor).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: const Color(AppConstants.primaryColor).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '已选择 ${_selectedQuestions.length} 项',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _selectedQuestions.isNotEmpty
                ? () => _removeSelectedQuestions(appState)
                : null,
            child: const Text('取消收藏'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _selectedQuestions.isNotEmpty
                ? () => _shareSelectedQuestions()
                : null,
            child: const Text('分享拾光截图'),
          ),
        ],
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.photoPaperDecoration.copyWith(
          color: isSelected 
              ? const Color(AppConstants.primaryColor).withOpacity(0.1)
              : const Color(AppConstants.secondaryColor),
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
                    const Icon(
                      Icons.star,
                      color: Color(AppConstants.accentColor),
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
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
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
                  Text(
                    '收藏于 ${_formatDate(question.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
}
