import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/memory_capsule.dart';
import '../services/memory_capsule_service.dart';
import 'memory_capsule_detail_screen.dart';
import 'memory_capsule_creation_screen.dart';

/// 记忆胶囊主页面
class MemoryCapsuleScreen extends StatefulWidget {
  const MemoryCapsuleScreen({super.key});

  @override
  State<MemoryCapsuleScreen> createState() => _MemoryCapsuleScreenState();
}

class _MemoryCapsuleScreenState extends State<MemoryCapsuleScreen>
    with SingleTickerProviderStateMixin {
  final MemoryCapsuleService _service = MemoryCapsuleService();
  List<MemoryCapsule> _capsules = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0: 全部, 1: 按年代, 2: 按分类
  String? _selectedEra;
  String? _selectedCategory;
  late TabController _tabController;
  DateTime? _lastRefreshTime; // 记录最后刷新时间，避免过度刷新

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
          _selectedEra = null;
          _selectedCategory = null;
        });
        _loadCapsules(forceReload: true); // Tab切换时强制刷新
      }
    });
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 当页面重新可见时刷新数据（使用didChangeDependencies + 防抖）
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面可见时都刷新一次，但添加防抖机制（至少间隔1秒）
    final now = DateTime.now();
    if (_lastRefreshTime == null || 
        now.difference(_lastRefreshTime!).inSeconds > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🔄 页面可见，刷新记忆胶囊列表...');
          _loadCapsules(forceReload: true);
          _lastRefreshTime = now;
        }
      });
    }
  }

  /// 初始化服务并加载数据
  Future<void> _initializeService() async {
    try {
      await _service.initialize();
      await _loadCapsules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  /// 加载记忆胶囊
  Future<void> _loadCapsules({bool forceReload = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<MemoryCapsule> capsules = [];

      switch (_selectedTabIndex) {
        case 0: // 全部
          capsules = await _service.getAllCapsules(forceReload: forceReload);
          break;
        case 1: // 按年代
          if (_selectedEra != null) {
            capsules = await _service.getCapsulesByEra(_selectedEra!, forceReload: forceReload);
          } else {
            capsules = await _service.getAllCapsules(forceReload: forceReload);
          }
          break;
        case 2: // 按分类
          if (_selectedCategory != null) {
            capsules = await _service.getCapsulesByCategory(_selectedCategory!, forceReload: forceReload);
          } else {
            capsules = await _service.getAllCapsules(forceReload: forceReload);
          }
          break;
        default:
          capsules = await _service.getAllCapsules(forceReload: forceReload);
      }

      // 确保capsules不为null，并创建可修改的副本（因为服务返回的是不可修改列表）
      List<MemoryCapsule> mutableCapsules = capsules.isEmpty 
          ? [] 
          : List<MemoryCapsule>.from(capsules);

      // 按创建时间倒序排列
      if (mutableCapsules.isNotEmpty) {
        mutableCapsules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      if (mounted) {
        setState(() {
          _capsules = mutableCapsules;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载记忆胶囊失败: $e');
      if (mounted) {
        setState(() {
          _capsules = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆胶囊'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // 选中标签使用白色，更显眼
          unselectedLabelColor: Colors.white70, // 未选中标签使用半透明白色
          indicatorColor: Colors.white, // 指示器颜色
          indicatorWeight: 3, // 指示器粗细
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold, // 选中标签加粗
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal, // 未选中标签正常粗细
          ),
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '按年代'),
            Tab(text: '按分类'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 筛选器（按年代或分类）- 始终显示，即使列表为空
                if (_selectedTabIndex == 1 || _selectedTabIndex == 2)
                  _buildFilterBar(),
                // 列表或空状态
                Expanded(
                  child: _capsules.isEmpty
                      ? _buildEmptyState()
                      : _buildCapsulesList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewCapsule(),
        icon: const Icon(Icons.add),
        label: const Text('新建记忆'),
        backgroundColor: const Color(AppConstants.primaryColor),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    String emptyMessage = '还没有记忆胶囊';
    String emptyHint = '点击右下角按钮创建你的第一个记忆胶囊';
    
    // 根据筛选条件显示不同的提示
    if (_selectedTabIndex == 1 && _selectedEra != null) {
      emptyMessage = '还没有$_selectedEra的记忆胶囊';
      emptyHint = '尝试选择其他年代，或创建新的记忆胶囊';
    } else if (_selectedTabIndex == 2 && _selectedCategory != null) {
      emptyMessage = '还没有$_selectedCategory分类的记忆胶囊';
      emptyHint = '尝试选择其他分类，或创建新的记忆胶囊';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              emptyHint,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建记忆胶囊列表
  Widget _buildCapsulesList() {
    return RefreshIndicator(
      onRefresh: _loadCapsules,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _capsules.length,
        itemBuilder: (context, index) {
          return _buildCapsuleCard(_capsules[index]);
        },
      ),
    );
  }

  /// 构建筛选栏
  Widget _buildFilterBar() {
    if (_selectedTabIndex == 1) {
      // 按年代筛选
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip('全部', _selectedEra == null, () {
              setState(() => _selectedEra = null);
              _loadCapsules();
            }),
            const SizedBox(width: 8),
            _buildFilterChip('80年代', _selectedEra == '80年代', () {
              setState(() => _selectedEra = '80年代');
              _loadCapsules();
            }),
            const SizedBox(width: 8),
            _buildFilterChip('90年代', _selectedEra == '90年代', () {
              setState(() => _selectedEra = '90年代');
              _loadCapsules();
            }),
            const SizedBox(width: 8),
            _buildFilterChip('00年代', _selectedEra == '00年代', () {
              setState(() => _selectedEra = '00年代');
              _loadCapsules();
            }),
          ],
        ),
      );
    } else if (_selectedTabIndex == 2) {
      // 按分类筛选
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip('全部', _selectedCategory == null, () {
              setState(() => _selectedCategory = null);
              _loadCapsules();
            }),
            const SizedBox(width: 8),
            _buildFilterChip('影视', _selectedCategory == '影视', () {
              setState(() => _selectedCategory = '影视');
              _loadCapsules();
            }),
            const SizedBox(width: 8),
            _buildFilterChip('音乐', _selectedCategory == '音乐', () {
              setState(() => _selectedCategory = '音乐');
              _loadCapsules();
            }),
            const SizedBox(width: 8),
            _buildFilterChip('事件', _selectedCategory == '事件', () {
              setState(() => _selectedCategory = '事件');
              _loadCapsules();
            }),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// 构建筛选芯片
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected 
              ? const Color(AppConstants.primaryColor) // 选中时使用主题色，更显眼
              : const Color(AppConstants.textPrimaryColor), // 未选中时使用深色文字
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(AppConstants.primaryColor).withOpacity(0.2),
      backgroundColor: Colors.white, // 未选中时使用白色背景，提高对比度
      checkmarkColor: const Color(AppConstants.primaryColor),
      side: BorderSide(
        color: isSelected 
            ? const Color(AppConstants.primaryColor)
            : Colors.grey.withOpacity(0.3),
        width: 1.5,
      ),
    );
  }

  /// 构建记忆胶囊卡片
  Widget _buildCapsuleCard(MemoryCapsule capsule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewCapsuleDetail(capsule),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：年代标签和分类
                Row(
                  children: [
                    // 年代标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(AppConstants.primaryColor).withOpacity(0.15),
                            const Color(AppConstants.primaryColor).withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(width: 4),
                          Text(
                            capsule.era,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(AppConstants.primaryColor),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 分类标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(AppConstants.accentColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(AppConstants.accentColor).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        capsule.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(AppConstants.accentColor),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 心情图标
                    if (capsule.mood.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getMoodColor(capsule.mood).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getMoodIcon(capsule.mood),
                          size: 16,
                          color: _getMoodColor(capsule.mood),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 标题
                Text(
                  capsule.getDisplayTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.textPrimaryColor),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // 内容预览
                Text(
                  capsule.getPreviewText(maxLength: 120),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // 底部信息栏
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 标签
                      if (capsule.tags.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (capsule.tags.take(3).toList()).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
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
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      
                      const SizedBox(width: 12),
                      
                      // 媒体图标
                      if (capsule.hasImage || capsule.hasAudio)
                        Row(
                          children: [
                            if (capsule.hasImage)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                              ),
                            if (capsule.hasImage && capsule.hasAudio)
                              const SizedBox(width: 6),
                            if (capsule.hasAudio)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.audiotrack,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                      
                      const SizedBox(width: 12),
                      
                      // 时间
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(capsule.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// 查看记忆胶囊详情
  void _viewCapsuleDetail(MemoryCapsule capsule) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoryCapsuleDetailScreen(capsule: capsule),
      ),
    );

    // 如果返回true，说明需要刷新列表
    if (result == true) {
      print('🔄 记忆胶囊编辑成功，强制刷新列表...');
      await _loadCapsules(forceReload: true);
      print('✅ 列表刷新完成，当前有 ${_capsules.length} 个记忆胶囊');
    }
  }

  /// 创建新记忆胶囊
  void _createNewCapsule() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MemoryCapsuleCreationScreen(),
      ),
    );

    // 如果返回true，说明创建成功，需要刷新列表
    if (result == true) {
      print('🔄 记忆胶囊创建成功，强制刷新列表...');
      // 强制重新加载数据（从文件读取最新数据）
      await _loadCapsules(forceReload: true);
      print('✅ 列表刷新完成，当前有 ${_capsules.length} 个记忆胶囊');
    }
  }
}

