import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/memory_record.dart';
import '../services/memory_service.dart';
import 'memory_detail_screen.dart';
import 'memory_view_screen.dart';

/// 记忆胶囊页面
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen>
    with SingleTickerProviderStateMixin {
  final MemoryService _memoryService = MemoryService();
  List<MemoryRecord> _memories = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0: 时间线, 1: 年代, 2: 标签
  String? _selectedEra;
  String? _selectedTag;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _loadMemories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final memories = await _memoryService.getAllMemories();
      if (!mounted) return;
      setState(() {
        _memories = memories;
        _isLoading = false;
      });
    } catch (e) {
      print('💝 [MemoryScreen] 加载回忆失败: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载回忆失败：${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: '重试',
            textColor: Colors.white,
            onPressed: _loadMemories,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆胶囊'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _navigateToAddMemory(context),
            tooltip: '记录回忆',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMemories,
            tooltip: '刷新',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
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
          tabs: [
            Tab(
              text: '时间线',
              icon: Icon(Icons.timeline, color: Colors.white),
            ),
            Tab(
              text: '年代',
              icon: Icon(Icons.calendar_today, color: Colors.white),
            ),
            Tab(
              text: '标签',
              icon: Icon(Icons.label, color: Colors.white),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memories.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddMemory(context),
        icon: const Icon(Icons.add),
        label: const Text('记录回忆'),
        backgroundColor: const Color(AppConstants.primaryColor),
      ),
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
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              '记忆胶囊还是空的',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '记录下那些让你怀念的时光吧～',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddMemory(context),
              icon: const Icon(Icons.add),
              label: const Text('记录第一段回忆'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTimelineView(),
        _buildEraView(),
        _buildTagView(),
      ],
    );
  }

  /// 时间线视图
  Widget _buildTimelineView() {
    final sortedMemories = List<MemoryRecord>.from(_memories)
      ..sort((a, b) => b.createTime.compareTo(a.createTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMemories.length,
      itemBuilder: (context, index) {
        final memory = sortedMemories[index];
        return _buildMemoryCard(memory);
      },
    );
  }

  /// 年代视图
  Widget _buildEraView() {
    final eras = ['80年代', '90年代', '00年代'];
    final eraMap = <String, List<MemoryRecord>>{};
    
    for (final era in eras) {
      eraMap[era] = _memories.where((m) => m.era == era).toList()
        ..sort((a, b) => b.createTime.compareTo(a.createTime));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: eras.length,
      itemBuilder: (context, index) {
        final era = eras[index];
        final memories = eraMap[era] ?? [];
        
        if (memories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
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
                      era,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConstants.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${memories.length}段回忆)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ...memories.map((memory) => _buildMemoryCard(memory)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// 标签视图
  Widget _buildTagView() {
    return FutureBuilder<List<String>>(
      future: _memoryService.getAllTags(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '还没有标签',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final tags = snapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            return FutureBuilder<List<MemoryRecord>>(
              future: _memoryService.getMemoriesByTag(tag),
              builder: (context, tagSnapshot) {
                if (!tagSnapshot.hasData || tagSnapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                final tagMemories = tagSnapshot.data!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.label,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${tagMemories.length}段回忆)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...tagMemories.map((memory) => _buildMemoryCard(memory)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// 构建回忆卡片
  Widget _buildMemoryCard(MemoryRecord memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.photoPaperDecoration,
      child: InkWell(
        onTap: () => _navigateToMemoryDetail(context, memory),
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
                      memory.era,
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      memory.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 心情图标
                  _buildMoodIcon(memory.mood),
                ],
              ),
              const SizedBox(height: 12),
              
              // 回忆内容
              Text(
                memory.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // 标签
              if (memory.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: memory.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
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
                    DateFormat('yyyy-MM-dd').format(memory.createTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (memory.location != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      memory.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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

  /// 构建心情图标
  Widget _buildMoodIcon(String mood) {
    IconData icon;
    Color color;
    
    switch (mood) {
      case '怀念':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case '感动':
        icon = Icons.emoji_emotions;
        color = Colors.orange;
        break;
      case '开心':
        icon = Icons.mood;
        color = Colors.amber;
        break;
      case '感慨':
        icon = Icons.sentiment_satisfied;
        color = Colors.blue;
        break;
      default:
        icon = Icons.favorite_border;
        color = Colors.grey;
    }
    
    return Icon(icon, size: 18, color: color);
  }

  /// 导航到添加回忆页面
  void _navigateToAddMemory(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MemoryDetailScreen(),
      ),
    );
    
    if (result == true) {
      _loadMemories();
    }
  }

  /// 导航到回忆详情页面
  void _navigateToMemoryDetail(
    BuildContext context,
    MemoryRecord memory,
  ) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MemoryViewScreen(memory: memory),
      ),
    );
    
    if (result == true) {
      _loadMemories();
    }
  }
}

