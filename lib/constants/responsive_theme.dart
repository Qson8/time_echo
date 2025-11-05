import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/font_size_service.dart';

/// 响应式主题
class ResponsiveTheme {
  static ThemeData getTheme() {
    final fontSizeService = FontSizeService();
    
    return ThemeData(
      // 基础颜色
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
      primaryColor: const Color(AppConstants.primaryColor),
      scaffoldBackgroundColor: const Color(AppConstants.secondaryColor),
      
      // 文本主题
      textTheme: TextTheme(
        // 大标题
        headlineLarge: fontSizeService.buildLargeTitleStyle(
          color: const Color(AppConstants.primaryColor),
        ),
        // 标题
        headlineMedium: fontSizeService.buildTitleStyle(
          color: const Color(AppConstants.primaryColor),
        ),
        // 小标题
        headlineSmall: fontSizeService.buildTitleStyle(
          fontWeight: FontWeight.w600,
          color: const Color(AppConstants.primaryColor),
        ),
        // 正文
        bodyLarge: fontSizeService.buildTextStyle(
          color: Colors.black87,
          height: 1.5,
        ),
        // 中等正文
        bodyMedium: fontSizeService.buildTextStyle(
          color: Colors.black87,
          height: 1.4,
        ),
        // 小正文
        bodySmall: fontSizeService.buildSmallStyle(
          color: Colors.black54,
          height: 1.3,
        ),
        // 标签
        labelLarge: fontSizeService.buildTextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        // 小标签
        labelMedium: fontSizeService.buildSmallStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
        // 极小标签
        labelSmall: fontSizeService.buildTinyStyle(
          color: Colors.black38,
        ),
      ),
      
      // AppBar主题
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: fontSizeService.buildTitleStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryColor),
          foregroundColor: Colors.white,
          padding: fontSizeService.getButtonPadding(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: fontSizeService.buildTextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // 文本按钮主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(AppConstants.primaryColor),
          padding: fontSizeService.getButtonPadding(),
          textStyle: fontSizeService.buildTextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // 卡片主题
      // 注意：CardThemeData 在某些Flutter版本中可能不支持
      // 我们将通过Card组件的默认样式来实现
      
      // 列表主题
      listTileTheme: ListTileThemeData(
        contentPadding: fontSizeService.getListTilePadding(),
        titleTextStyle: fontSizeService.buildTextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        subtitleTextStyle: fontSizeService.buildSmallStyle(
          color: Colors.black54,
        ),
        iconColor: const Color(AppConstants.primaryColor),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(AppConstants.primaryColor),
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.all(fontSizeService.getSpacing(1)),
        hintStyle: fontSizeService.buildTextStyle(
          color: Colors.grey,
        ),
        labelStyle: fontSizeService.buildTextStyle(
          color: Colors.grey,
        ),
      ),
      
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(AppConstants.primaryColor);
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(AppConstants.primaryColor).withOpacity(0.3);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      
      // 对话框主题
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: fontSizeService.buildTitleStyle(
          color: Colors.black87,
        ),
        contentTextStyle: fontSizeService.buildTextStyle(
          color: Colors.black87,
          height: 1.4,
        ),
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(AppConstants.primaryColor),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: Colors.grey.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),
      
      // 进度指示器主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(AppConstants.primaryColor),
        linearTrackColor: Colors.grey,
        circularTrackColor: Colors.grey,
      ),
      
      // 复选框主题
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(AppConstants.primaryColor);
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.5),
          width: 2,
        ),
      ),
      
      // 单选按钮主题
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(AppConstants.primaryColor);
          }
          return Colors.grey;
        }),
      ),
    );
  }
}
