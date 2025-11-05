import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// 主题状态提供者
class ThemeProvider extends ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  
  ThemeType get currentTheme => _themeService.currentTheme;
  
  /// 设置主题
  Future<void> setTheme(ThemeType theme) async {
    await _themeService.setTheme(theme);
    notifyListeners();
  }
  
  /// 获取主题数据
  ThemeData getThemeData() {
    return _themeService.getThemeData();
  }
  
  /// 获取主题名称
  String getThemeName(ThemeType theme) {
    return _themeService.getThemeName(theme);
  }
  
  /// 获取主题描述
  String getThemeDescription(ThemeType theme) {
    return _themeService.getThemeDescription(theme);
  }
  
  /// 获取主题图标
  IconData getThemeIcon(ThemeType theme) {
    return _themeService.getThemeIcon(theme);
  }
  
  /// 获取主题颜色
  Color getThemeColor(ThemeType theme) {
    return _themeService.getThemeColor(theme);
  }
}
