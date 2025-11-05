import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'local_storage_service.dart';

/// 主题类型枚举
enum ThemeType {
  vintage,    // 拾光复古主题
  modern,     // 现代简约主题
  dark,       // 深色主题
  elderly,    // 老年友好主题
}

/// 主题管理服务（使用JSON存储）
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeType _currentTheme = ThemeType.vintage;
  final LocalStorageService _localStorage = LocalStorageService();
  
  /// 初始化
  Future<void> initialize() async {
    print('🎨 ThemeService 初始化...');
    await _loadTheme();
    print('🎨 ✅ ThemeService 初始化完成');
  }
  
  ThemeType get currentTheme => _currentTheme;
  
  /// 设置主题
  Future<void> setTheme(ThemeType theme) async {
    _currentTheme = theme;
    await _saveTheme(theme);
  }
  
  /// 保存主题到本地存储
  Future<void> _saveTheme(ThemeType theme) async {
    await _localStorage.setString('selected_theme', theme.name);
  }
  
  /// 从本地存储加载主题
  Future<void> _loadTheme() async {
    final themeName = await _localStorage.getString('selected_theme');
    if (themeName != null) {
      try {
        _currentTheme = ThemeType.values.firstWhere(
          (theme) => theme.name == themeName,
        );
      } catch (e) {
        _currentTheme = ThemeType.vintage; // 默认主题
      }
    }
  }
  
  /// 获取主题名称
  String getThemeName(ThemeType theme) {
    switch (theme) {
      case ThemeType.vintage:
        return '拾光复古';
      case ThemeType.modern:
        return '现代简约';
      case ThemeType.dark:
        return '深色模式';
      case ThemeType.elderly:
        return '老年友好';
    }
  }
  
  /// 获取主题描述
  String getThemeDescription(ThemeType theme) {
    switch (theme) {
      case ThemeType.vintage:
        return '怀旧色调，温暖时光记忆';
      case ThemeType.modern:
        return '简洁设计，清爽体验';
      case ThemeType.dark:
        return '护眼深色，夜间友好';
      case ThemeType.elderly:
        return '大字体，高对比度';
    }
  }
  
  /// 获取主题图标
  IconData getThemeIcon(ThemeType theme) {
    switch (theme) {
      case ThemeType.vintage:
        return Icons.photo_filter;
      case ThemeType.modern:
        return Icons.palette;
      case ThemeType.dark:
        return Icons.dark_mode;
      case ThemeType.elderly:
        return Icons.accessibility;
    }
  }
  
  /// 获取主题颜色
  Color getThemeColor(ThemeType theme) {
    switch (theme) {
      case ThemeType.vintage:
        return const Color(AppConstants.primaryColor);
      case ThemeType.modern:
        return Colors.blue;
      case ThemeType.dark:
        return Colors.grey[800]!;
      case ThemeType.elderly:
        return Colors.green;
    }
  }
  
  /// 获取主题数据
  ThemeData getThemeData() {
    switch (_currentTheme) {
      case ThemeType.vintage:
        return _getVintageTheme();
      case ThemeType.modern:
        return _getModernTheme();
      case ThemeType.dark:
        return _getDarkTheme();
      case ThemeType.elderly:
        return _getElderlyTheme();
    }
  }
  
  /// 拾光复古主题
  ThemeData _getVintageTheme() {
    const vintagePrimary = Color(AppConstants.primaryColor);
    const vintageSecondary = Color(AppConstants.secondaryColor);
    const vintageAccent = Color(AppConstants.accentColor);
    
    return ThemeData(
      useMaterial3: true,
      primarySwatch: MaterialColor(
        AppConstants.primaryColor,
        <int, Color>{
          50: const Color(AppConstants.primaryColor).withOpacity(0.1),
          100: const Color(AppConstants.primaryColor).withOpacity(0.2),
          200: const Color(AppConstants.primaryColor).withOpacity(0.3),
          300: const Color(AppConstants.primaryColor).withOpacity(0.4),
          400: const Color(AppConstants.primaryColor).withOpacity(0.5),
          500: const Color(AppConstants.primaryColor),
          600: const Color(AppConstants.primaryColor).withOpacity(0.7),
          700: const Color(AppConstants.primaryColor).withOpacity(0.8),
          800: const Color(AppConstants.primaryColor).withOpacity(0.9),
          900: const Color(AppConstants.primaryColor),
        },
      ),
      primaryColor: vintagePrimary,
      scaffoldBackgroundColor: vintageSecondary,
      cardColor: Colors.white,
      dividerColor: Colors.grey.withOpacity(0.3),
      appBarTheme: const AppBarTheme(
        backgroundColor: vintagePrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 24),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vintagePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: vintagePrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: vintagePrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: vintagePrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: vintagePrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: vintagePrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
      ),
      iconTheme: const IconThemeData(
        color: vintagePrimary,
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: vintagePrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: vintagePrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: vintagePrimary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: vintagePrimary,
        labelStyle: const TextStyle(color: Colors.black87),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: vintagePrimary,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: vintagePrimary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }
  
  /// 现代简约主题
  ThemeData _getModernTheme() {
    const modernPrimary = Color(0xFF2196F3); // 现代蓝色
    const modernAccent = Color(0xFF03A9F4); // 亮蓝作为强调色
    
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.blue,
      primaryColor: modernPrimary,
      scaffoldBackgroundColor: Colors.grey[50],
      cardColor: Colors.white,
      dividerColor: Colors.grey.withOpacity(0.2),
      appBarTheme: const AppBarTheme(
        backgroundColor: modernPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 24),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: modernPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: modernPrimary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: modernPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF424242),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF424242),
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(0xFF757575),
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF424242),
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF757575),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF424242),
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: modernPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100]!,
        selectedColor: modernPrimary,
        labelStyle: const TextStyle(color: Color(0xFF424242)),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[200]!,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: modernPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
  
  /// 深色主题
  ThemeData _getDarkTheme() {
    const darkPrimary = Color(0xFF9E9E9E);
    const darkBackground = Color(0xFF121212);
    const darkSurface = Color(0xFF1E1E1E);
    
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primarySwatch: Colors.grey,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: Colors.grey[700]!,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE0E0E0), height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFE0E0E0), height: 1.5),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0)),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFE0E0E0)),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFB0B0B0)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFE0E0E0), size: 24),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
    );
  }
  
  /// 老年友好主题
  ThemeData _getElderlyTheme() {
    const elderlyGreen = Colors.green;
    
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.green,
      primaryColor: elderlyGreen,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: Colors.grey.withOpacity(0.5),
      appBarTheme: const AppBarTheme(
        backgroundColor: elderlyGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 28),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: elderlyGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: elderlyGreen,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
        bodyLarge: TextStyle(fontSize: 20, height: 1.6, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 18, height: 1.5, color: Colors.black87),
        bodySmall: TextStyle(fontSize: 16, height: 1.4, color: Colors.black87),
        labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
        labelMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        labelSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      iconTheme: const IconThemeData(
        color: elderlyGreen,
        size: 28,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: elderlyGreen, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: elderlyGreen,
            width: 3,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: elderlyGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  /// 检查是否为老年友好模式
  Future<bool> isElderlyFriendlyMode() async {
    try {
      final value = await _localStorage.getBool('elderly_mode');
      return value ?? false;
    } catch (e) {
      print('🎨 ⚠️ 获取老年友好模式失败: $e');
      return false;
    }
  }
}
