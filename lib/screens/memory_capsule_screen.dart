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
        _loadCapsules();
      }
    });
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
  Future<void> _loadCapsules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<MemoryCapsule> capsules = [];

      switch (_selectedTabIndex) {
        case 0: // 全部
          capsules = await _service.getAllCapsules();
          break;
        case 1: // 按年代
          if (_selectedEra != null) {
            capsules = await _service.getCapsulesByEra(_selectedEra!);
          } else {
            capsules = await _service.getAllCapsules();
          }
          break;
        case 2: // 按分类
          if (_selectedCategory != null) {
            capsules = await _service.getCapsulesByCategory(_selectedCategory!);
          } else {
            capsules = await _service.getAllCapsules();
          }
          break;
        default:
          capsules = await _service.getAllCapsules();
      }

      // 确保capsules不为null
      if (capsules.isEmpty) {
        capsules = [];
      }

      // 按创建时间倒序排列
      if (capsules.isNotEmpty) {
        capsules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      if (mounted) {
        setState(() {
          _capsules = capsules;
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
        title: const Text('时光记忆胶囊'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '按年代'),
            Tab(text: '按分类'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _capsules.isEmpty
              ? _buildEmptyState()
              : _buildCapsulesList(),
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
            '还没有记忆胶囊',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮创建你的第一个记忆胶囊',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建记忆胶囊列表
  Widget _buildCapsulesList() {
    return Column(
      children: [
        // 筛选器（按年代或分类）
        if (_selectedTabIndex == 1 || _selectedTabIndex == 2)
          _buildFilterBar(),
        
        // 列表
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCapsules,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _capsules.length,
              itemBuilder: (context, index) {
                return _buildCapsuleCard(_capsules[index]);
              },
            ),
          ),
        ),
      ],
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
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(AppConstants.primaryColor).withOpacity(0.2),
      checkmarkColor: const Color(AppConstants.primaryColor),
    );
  }

  /// 构建记忆胶囊卡片
  Widget _buildCapsuleCard(MemoryCapsule capsule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewCapsuleDetail(capsule),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和标签
              Row(
                children: [
                  Expanded(
                    child: Text(
                      capsule.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      capsule.era,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(AppConstants.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 内容预览
              Text(
                capsule.getPreviewText(maxLength: 100),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // 底部信息
              Row(
                children: [
                  // 标签
                  if (capsule.tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: (capsule.tags.take(3).toList()).map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // 媒体图标
                  if (capsule.hasImage)
                    const Icon(Icons.image, size: 16, color: Colors.blue),
                  if (capsule.hasImage && capsule.hasAudio)
                    const SizedBox(width: 4),
                  if (capsule.hasAudio)
                    const Icon(Icons.audiotrack, size: 16, color: Colors.orange),
                  
                  const SizedBox(width: 8),
                  
                  // 时间
                  Text(
                    _formatDate(capsule.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      _loadCapsules();
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
      _loadCapsules();
    }
  }
}

