import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'local_storage_service.dart';

/// 字体大小管理服务（使用JSON存储）
class FontSizeService {
  static final FontSizeService _instance = FontSizeService._internal();
  factory FontSizeService() => _instance;
  FontSizeService._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  String _currentFontSize = '中';
  
  /// 初始化
  Future<void> initialize() async {
    print('📝 FontSizeService 初始化...');
    final fontSize = await _localStorage.getString('font_size');
    _currentFontSize = fontSize ?? '中';
    print('📝 ✅ FontSizeService 初始化完成，字体大小: $_currentFontSize');
  }
  
  String get currentFontSize => _currentFontSize;
  
  /// 设置字体大小
  void setFontSize(String fontSize) {
    _currentFontSize = fontSize;
    _saveFontSize(fontSize);
  }

  /// 更新字体大小
  Future<void> updateFontSize(String fontSize) async {
    _currentFontSize = fontSize;
    await _saveFontSize(fontSize);
  }

  /// 保存字体大小
  Future<void> _saveFontSize(String fontSize) async {
    try {
      await _localStorage.setString('font_size', fontSize);
    } catch (e) {
      print('📝 ⚠️ 保存字体大小失败: $e');
    }
  }
  
  /// 获取基础字体大小
  double getBaseFontSize() {
    return AppConstants.fontSizes[_currentFontSize] ?? 16.0;
  }
  
  /// 获取标题字体大小
  double getTitleFontSize() {
    return getBaseFontSize() * 1.5;
  }
  
  /// 获取大标题字体大小
  double getLargeTitleFontSize() {
    return getBaseFontSize() * 2.0;
  }
  
  /// 获取小字体大小
  double getSmallFontSize() {
    return getBaseFontSize() * 0.875;
  }
  
  /// 获取极小字体大小
  double getTinyFontSize() {
    return getBaseFontSize() * 0.75;
  }
  
  /// 构建响应式文本样式
  TextStyle buildTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    final baseSize = fontSize ?? getBaseFontSize();
    return TextStyle(
      fontSize: baseSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }
  
  /// 构建标题文本样式
  TextStyle buildTitleStyle({
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return buildTextStyle(
      fontSize: getTitleFontSize(),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
      height: height,
    );
  }
  
  /// 构建大标题文本样式
  TextStyle buildLargeTitleStyle({
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return buildTextStyle(
      fontSize: getLargeTitleFontSize(),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
      height: height,
    );
  }
  
  /// 构建小文本样式
  TextStyle buildSmallStyle({
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return buildTextStyle(
      fontSize: getSmallFontSize(),
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
  
  /// 构建极小文本样式
  TextStyle buildTinyStyle({
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return buildTextStyle(
      fontSize: getTinyFontSize(),
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
  
  /// 获取按钮内边距
  EdgeInsets getButtonPadding() {
    final baseSize = getBaseFontSize();
    return EdgeInsets.symmetric(
      horizontal: baseSize * 1.5,
      vertical: baseSize * 0.75,
    );
  }
  
  /// 获取卡片内边距
  EdgeInsets getCardPadding() {
    final baseSize = getBaseFontSize();
    return EdgeInsets.all(baseSize);
  }
  
  /// 获取列表项内边距
  EdgeInsets getListTilePadding() {
    final baseSize = getBaseFontSize();
    return EdgeInsets.symmetric(
      horizontal: baseSize * 0.75,
      vertical: baseSize * 0.5,
    );
  }
  
  /// 获取间距
  double getSpacing(double multiplier) {
    final baseSize = getBaseFontSize();
    return baseSize * multiplier;
  }

  /// 获取字体缩放因子
  double getFontScaleFactor() {
    // 直接使用内存中的当前字体大小，避免再次读取
    switch (_currentFontSize) {
      case '小':
        return 0.8;
      case '中':
        return 1.0;
      case '大':
        return 1.2;
      case '特大':
        return 1.4;
      default:
        return 1.0;
    }
  }
}
