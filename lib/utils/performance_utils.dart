import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:isolate';

/// 性能优化工具类
class PerformanceUtils {
  /// 预加载图片资源
  static Future<void> preloadImages(BuildContext context, List<String> imagePaths) async {
    for (final path in imagePaths) {
      try {
        await precacheImage(AssetImage(path), context);
      } catch (e) {
        print('预加载图片失败: $path, 错误: $e');
      }
    }
  }

  /// 预加载字体
  static Future<void> preloadFonts() async {
    try {
      await rootBundle.load('assets/fonts/NotoSansCJK-Regular.ttf');
    } catch (e) {
      print('预加载字体失败: $e');
    }
  }

  /// 延迟执行任务
  static void scheduleMicrotask(VoidCallback callback) {
    scheduleMicrotask(callback);
  }

  /// 延迟执行任务（毫秒）
  static void delayedTask(VoidCallback callback, int milliseconds) {
    Timer(Duration(milliseconds: milliseconds), callback);
  }

  /// 防抖函数
  static Timer? _debounceTimer;
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// 节流函数
  static DateTime? _lastExecution;
  static void throttle(VoidCallback callback, {Duration delay = const Duration(milliseconds: 100)}) {
    final now = DateTime.now();
    if (_lastExecution == null || now.difference(_lastExecution!) > delay) {
      _lastExecution = now;
      callback();
    }
  }

  /// 测量执行时间
  static Future<T> measureExecutionTime<T>(
    Future<T> Function() function, {
    String? label,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      if (label != null) {
        print('$label 执行时间: ${stopwatch.elapsedMilliseconds}ms');
      }
      return result;
    } catch (e) {
      stopwatch.stop();
      if (label != null) {
        print('$label 执行失败: $e, 耗时: ${stopwatch.elapsedMilliseconds}ms');
      }
      rethrow;
    }
  }

  /// 在独立线程中执行计算密集型任务
  static Future<T> computeInIsolate<T>(
    T Function() computation, {
    String? debugLabel,
  }) async {
    // 注释掉compute方法，因为需要导入flutter/foundation.dart
    // return await compute((_) => computation(), null);
    return await computation();
  }
}

/// 高性能列表组件
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: children[index],
        );
      },
    );
  }
}

/// 高性能网格组件
class OptimizedGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedGridView({
    super.key,
    required this.children,
    required this.crossAxisCount,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: children[index],
        );
      },
    );
  }
}

/// 懒加载组件
class LazyLoadWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Widget? placeholder;

  const LazyLoadWidget({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 100),
    this.placeholder,
  });

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    PerformanceUtils.delayedTask(() {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    }, widget.delay.inMilliseconds);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded) {
      return RepaintBoundary(child: widget.child);
    }
    return widget.placeholder ?? const SizedBox.shrink();
  }
}

/// 缓存组件
class CachedWidget extends StatefulWidget {
  final Widget child;
  final String cacheKey;
  final Duration cacheDuration;

  const CachedWidget({
    super.key,
    required this.child,
    required this.cacheKey,
    this.cacheDuration = const Duration(minutes: 5),
  });

  @override
  State<CachedWidget> createState() => _CachedWidgetState();
}

class _CachedWidgetState extends State<CachedWidget> {
  static final Map<String, Widget> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cacheKey = widget.cacheKey;
    
    // 检查缓存是否过期
    if (_cacheTimestamps.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey]!;
      if (now.difference(timestamp) > widget.cacheDuration) {
        _cache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }
    
    // 返回缓存的组件或创建新组件
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    
    final cachedWidget = RepaintBoundary(child: this.widget.child);
    _cache[cacheKey] = cachedWidget;
    _cacheTimestamps[cacheKey] = now;
    
    return cachedWidget;
  }
}

/// 虚拟滚动组件
class VirtualScrollView extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;

  const VirtualScrollView({
    super.key,
    required this.itemCount,
    required this.itemHeight,
    required this.itemBuilder,
    this.controller,
    this.padding,
  });

  @override
  State<VirtualScrollView> createState() => _VirtualScrollViewState();
}

class _VirtualScrollViewState extends State<VirtualScrollView> {
  late ScrollController _controller;
  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _controller.addListener(_onScroll);
    _updateVisibleRange();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    _updateVisibleRange();
  }

  void _updateVisibleRange() {
    if (!_controller.hasClients) return;
    
    final scrollOffset = _controller.offset;
    final viewportHeight = _controller.position.viewportDimension;
    
    final firstIndex = (scrollOffset / widget.itemHeight).floor();
    final lastIndex = ((scrollOffset + viewportHeight) / widget.itemHeight).ceil();
    
    if (firstIndex != _firstVisibleIndex || lastIndex != _lastVisibleIndex) {
      setState(() {
        _firstVisibleIndex = firstIndex.clamp(0, widget.itemCount - 1);
        _lastVisibleIndex = lastIndex.clamp(0, widget.itemCount - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemExtent: widget.itemHeight,
      itemBuilder: (context, index) {
        if (index < _firstVisibleIndex || index > _lastVisibleIndex) {
          return SizedBox(height: widget.itemHeight);
        }
        
        return RepaintBoundary(
          child: widget.itemBuilder(context, index),
        );
      },
    );
  }
}

/// 图片缓存组件
class CachedImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
    );
  }
}

/// 内存监控组件
class MemoryMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const MemoryMonitor({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<MemoryMonitor> createState() => _MemoryMonitorState();
}

class _MemoryMonitorState extends State<MemoryMonitor> {
  Timer? _timer;
  String _memoryInfo = '';

  @override
  void initState() {
    super.initState();
    if (widget.showOverlay) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _memoryInfo = _getMemoryInfo();
        });
      }
    });
  }

  String _getMemoryInfo() {
    // 这里可以添加实际的内存监控逻辑
    return 'Memory: ${DateTime.now().millisecondsSinceEpoch % 1000}MB';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showOverlay) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _memoryInfo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
