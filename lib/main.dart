import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state_provider.dart';
import 'services/offline_data_manager.dart';
import 'services/font_size_service.dart';
import 'services/json_storage_service.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化JSON存储服务（所有数据持久化的基础）
  try {
    await JsonStorageService().initialize();
    print('✅ JSON存储服务初始化成功');
  } catch (e) {
    print('❌ JSON存储服务初始化失败: $e');
  }
  
  // 初始化字体大小服务
  try {
    await FontSizeService().initialize();
    print('字体大小服务初始化成功');
  } catch (e) {
    print('字体大小服务初始化失败: $e');
  }
  
  // 初始化离线数据管理器（如果需要的话，现在主要使用JSON存储）
  try {
    await OfflineDataManager().initialize();
    print('离线数据管理器初始化成功');
  } catch (e) {
    print('离线数据管理器初始化失败: $e');
  }
  
  runApp(const TimeEchoApp());
}

class TimeEchoApp extends StatelessWidget {
  const TimeEchoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppStateProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer2<AppStateProvider, ThemeProvider>(
        builder: (context, appState, themeProvider, child) {
          // 获取字体缩放因子 - 从appState获取当前字体大小
          final fontSizeService = FontSizeService();
          // 监听appState.fontSize的变化
          final textScaleFactor = fontSizeService.getFontScaleFactor();
          
          return MaterialApp(
            title: '拾光机',
            theme: themeProvider.getThemeData(),
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}