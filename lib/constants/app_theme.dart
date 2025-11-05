import 'package:flutter/material.dart';
import 'app_constants.dart';

/// 应用主题配置
class AppTheme {
  // 拾光主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppConstants.primaryColor),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryColor),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      // 注意：CardThemeData 在某些Flutter版本中可能不支持
      // 我们将通过Card组件的默认样式来实现
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(AppConstants.primaryColor),
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(AppConstants.primaryColor),
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(AppConstants.primaryColor),
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
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(AppConstants.primaryColor),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(AppConstants.primaryColor),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(AppConstants.primaryColor),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // 老年友好版主题
  static ThemeData get elderlyFriendlyTheme {
    return lightTheme.copyWith(
      textTheme: lightTheme.textTheme.copyWith(
        headlineLarge: lightTheme.textTheme.headlineLarge?.copyWith(fontSize: 32),
        headlineMedium: lightTheme.textTheme.headlineMedium?.copyWith(fontSize: 28),
        headlineSmall: lightTheme.textTheme.headlineSmall?.copyWith(fontSize: 24),
        bodyLarge: lightTheme.textTheme.bodyLarge?.copyWith(fontSize: 18),
        bodyMedium: lightTheme.textTheme.bodyMedium?.copyWith(fontSize: 16),
        bodySmall: lightTheme.textTheme.bodySmall?.copyWith(fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryColor),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 48),
        ),
      ),
      // 注意：CardThemeData 在某些Flutter版本中可能不支持
      // 我们将通过Card组件的默认样式来实现
    );
  }

  // 复古装饰样式
  static BoxDecoration get vintageDecoration {
    return BoxDecoration(
      color: const Color(AppConstants.secondaryColor),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(AppConstants.primaryColor),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // 胶片边框装饰
  static BoxDecoration get filmBorderDecoration {
    return BoxDecoration(
      color: const Color(AppConstants.secondaryColor),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: const Color(AppConstants.primaryColor),
        width: 2,
      ),
    );
  }

  // 相纸背景装饰
  static BoxDecoration get photoPaperDecoration {
    return BoxDecoration(
      color: const Color(AppConstants.secondaryColor),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(AppConstants.primaryColor),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // 成就徽章装饰
  static BoxDecoration get achievementBadgeDecoration {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color(AppConstants.primaryColor),
          const Color(AppConstants.primaryColor).withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(AppConstants.primaryColor).withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // 收藏按钮样式
  static BoxDecoration collectionButtonDecoration(bool isCollected) {
    return BoxDecoration(
      color: isCollected 
          ? const Color(AppConstants.accentColor)
          : Colors.transparent,
      shape: BoxShape.circle,
      border: Border.all(
        color: const Color(AppConstants.primaryColor),
        width: 2,
      ),
    );
  }

  // 答题选项样式
  static BoxDecoration answerOptionDecoration(bool isSelected, bool isCorrect, bool isWrong) {
    Color backgroundColor = Colors.transparent;
    Color borderColor = const Color(AppConstants.primaryColor);
    
    if (isSelected) {
      if (isCorrect) {
        backgroundColor = const Color(AppConstants.accentColor).withOpacity(0.2);
        borderColor = const Color(AppConstants.accentColor);
      } else if (isWrong) {
        backgroundColor = const Color(AppConstants.errorColor).withOpacity(0.2);
        borderColor = const Color(AppConstants.errorColor);
      } else {
        backgroundColor = const Color(AppConstants.primaryColor).withOpacity(0.1);
      }
    }
    
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: borderColor,
        width: 2,
      ),
    );
  }
}
