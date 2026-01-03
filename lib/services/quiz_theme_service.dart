import 'package:flutter/material.dart';
import '../models/question.dart';

/// 答题主题服务（根据题目年代切换主题）
class QuizThemeService {
  static final QuizThemeService _instance = QuizThemeService._internal();
  factory QuizThemeService() => _instance;
  QuizThemeService._internal();

  /// 根据题目获取主题颜色（适配深色模式）
  ThemeData getThemeForQuestion(Question? question, {bool isDarkMode = false}) {
    if (question == null) {
      return _getDefaultTheme(isDarkMode: isDarkMode);
    }

    // 根据年代主题获取对应的颜色方案
    final era = question.echoTheme.toLowerCase();
    
    if (era.contains('80')) {
      return _get80sTheme(isDarkMode: isDarkMode);                                                  
    } else if (era.contains('90')) {
      return _get90sTheme(isDarkMode: isDarkMode);
    } else if (era.contains('00')) {
      return _get00sTheme(isDarkMode: isDarkMode);
    }

    return _getDefaultTheme(isDarkMode: isDarkMode);
  }

  /// 80年代主题 - 复古暖色调
  ThemeData _get80sTheme({bool isDarkMode = false}) {
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    return ThemeData(
      primaryColor: const Color(0xFFD2691E), // 巧克力色
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD2691E),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDarkMode 
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFFFF8DC), // 玉米丝色
      cardColor: isDarkMode 
          ? const Color(0xFF2D2D2D)
          : const Color(0xFFFFE4B5), // 鹿皮色
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode 
            ? const Color(0xFF2D2D2D)
            : const Color(0xFFD2691E),
        foregroundColor: isDarkMode ? Colors.white : Colors.white,
      ),
    );
  }

  /// 90年代主题 - 彩色渐变
  ThemeData _get90sTheme({bool isDarkMode = false}) {
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    return ThemeData(
      primaryColor: const Color(0xFF9370DB), // 中紫色
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9370DB),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDarkMode 
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFF0E68C), // 卡其色
      cardColor: isDarkMode 
          ? const Color(0xFF2D2D2D)
          : const Color(0xFFFFB6C1), // 浅粉色
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode 
            ? const Color(0xFF2D2D2D)
            : const Color(0xFF9370DB),
        foregroundColor: isDarkMode ? Colors.white : Colors.white,
      ),
    );
  }

  /// 00年代主题 - 现代简约
  ThemeData _get00sTheme({bool isDarkMode = false}) {
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    return ThemeData(
      primaryColor: const Color(0xFF4169E1), // 皇家蓝
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4169E1),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDarkMode 
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFF5F5F5), // 浅灰色
      cardColor: isDarkMode 
          ? const Color(0xFF2D2D2D)
          : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode 
            ? const Color(0xFF2D2D2D)
            : const Color(0xFF4169E1),
        foregroundColor: isDarkMode ? Colors.white : Colors.white,
      ),
    );
  }

  /// 默认主题
  ThemeData _getDefaultTheme({bool isDarkMode = false}) {
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    return ThemeData(
      primaryColor: const Color(0xFF8B4513), // 棕色
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4513),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDarkMode 
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFFFF8DC),
      cardColor: isDarkMode 
          ? const Color(0xFF2D2D2D)
          : const Color(0xFFFFE4B5),
    );
  }

  /// 获取背景渐变（适配深色模式）
  LinearGradient getBackgroundGradient(Question? question, {bool isDarkMode = false}) {
    if (isDarkMode) {
      // 深色模式下的渐变
      if (question == null) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF2D2D2D),
            const Color(0xFF1A1A1A),
          ],
        );
      }

      final era = question.echoTheme.toLowerCase();
      
      if (era.contains('80')) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D1B0E),
            const Color(0xFF3D2B1E),
            const Color(0xFF2D1B0E),
          ],
        );
      } else if (era.contains('90')) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D1B2E),
            const Color(0xFF3D2B3E),
            const Color(0xFF2D1B2E),
          ],
        );
      } else if (era.contains('00')) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E2E),
            const Color(0xFF2D2D3E),
            const Color(0xFF1E1E2E),
          ],
        );
      }

      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1E1E1E),
          const Color(0xFF2D2D2D),
          const Color(0xFF1A1A1A),
        ],
      );
    }

    // 浅色模式下的渐变（原有逻辑）
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

