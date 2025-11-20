import 'package:flutter/material.dart';
import '../models/question.dart';

/// 答题主题服务（根据题目年代切换主题）
class QuizThemeService {
  static final QuizThemeService _instance = QuizThemeService._internal();
  factory QuizThemeService() => _instance;
  QuizThemeService._internal();

  /// 根据题目获取主题颜色
  ThemeData getThemeForQuestion(Question? question) {
    if (question == null) {
      return _getDefaultTheme();
    }

    // 根据年代主题获取对应的颜色方案
    final era = question.echoTheme.toLowerCase();
    
    if (era.contains('80')) {
      return _get80sTheme();
    } else if (era.contains('90')) {
      return _get90sTheme();
    } else if (era.contains('00')) {
      return _get00sTheme();
    }

    return _getDefaultTheme();
  }

  /// 80年代主题 - 复古暖色调
  ThemeData _get80sTheme() {
    return ThemeData(
      primaryColor: const Color(0xFFD2691E), // 巧克力色
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD2691E),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF8DC), // 玉米丝色
      cardColor: const Color(0xFFFFE4B5), // 鹿皮色
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFD2691E),
        foregroundColor: Colors.white,
      ),
    );
  }

  /// 90年代主题 - 彩色渐变
  ThemeData _get90sTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF9370DB), // 中紫色
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9370DB),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF0E68C), // 卡其色
      cardColor: const Color(0xFFFFB6C1), // 浅粉色
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF9370DB),
        foregroundColor: Colors.white,
      ),
    );
  }

  /// 00年代主题 - 现代简约
  ThemeData _get00sTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF4169E1), // 皇家蓝
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4169E1),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // 浅灰色
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4169E1),
        foregroundColor: Colors.white,
      ),
    );
  }

  /// 默认主题
  ThemeData _getDefaultTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF8B4513), // 棕色
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4513),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF8DC),
      cardColor: const Color(0xFFFFE4B5),
    );
  }

  /// 获取背景渐变
  LinearGradient getBackgroundGradient(Question? question) {
    if (question == null) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8DC), Color(0xFFFFE4B5)],
      );
    }

    final era = question.echoTheme.toLowerCase();
    
    if (era.contains('80')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8DC), Color(0xFFFFE4B5), Color(0xFFFFD700)],
      );
    } else if (era.contains('90')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0E68C), Color(0xFFFFB6C1), Color(0xFF9370DB)],
      );
    } else if (era.contains('00')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0), Color(0xFF4169E1)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF8DC), Color(0xFFFFE4B5)],
    );
  }
}

