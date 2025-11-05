# 拾光机 (Time Echo)

一款专注于离线怀旧问答的Flutter应用，通过题目唤醒用户的时光记忆。

## 项目特色

- **全离线运行**：无需网络连接，保护用户隐私
- **怀旧主题**：聚焦80-90年代的影视、音乐、事件
- **拾光年龄**：通过答题计算用户的"拾光年龄"
- **成就系统**：8种不同的拾光成就等待解锁
- **收藏功能**：收藏喜欢的题目到拾光收藏夹
- **语音读题**：支持语音朗读，适合老年用户
- **老年友好**：大字体、大按钮、语音辅助

## 技术架构

### 开发框架
- **Flutter 3.4.0+**：跨平台开发框架
- **Dart**：编程语言

### 核心依赖
- **sqflite**：SQLite数据库
- **provider**：状态管理
- **shared_preferences**：本地存储
- **flutter_tts**：语音合成
- **path**：路径处理

### 项目结构
```
lib/
├── constants/          # 常量定义
│   ├── app_constants.dart
│   └── app_theme.dart
├── models/            # 数据模型
│   ├── question.dart
│   ├── echo_collection.dart
│   ├── echo_achievement.dart
│   ├── test_record.dart
│   └── question_update_log.dart
├── services/          # 业务服务
│   ├── database_service.dart
│   ├── question_service.dart
│   ├── echo_collection_service.dart
│   ├── echo_achievement_service.dart
│   ├── test_record_service.dart
│   ├── question_update_service.dart
│   ├── voice_service.dart
│   ├── local_storage_service.dart
│   └── app_state_provider.dart
├── screens/           # 页面
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── quiz_screen.dart
│   ├── quiz_result_screen.dart
│   ├── collection_screen.dart
│   ├── question_detail_screen.dart
│   ├── achievement_screen.dart
│   └── settings_screen.dart
├── widgets/           # 自定义组件
│   ├── elderly_optimization.dart
│   └── voice_control_widget.dart
└── main.dart          # 应用入口
```

## 功能模块

### 1. 怀旧问答模块
- **题库管理**：本地SQLite存储，支持离线更新
- **答题流程**：随机出题，实时计分
- **年龄计算**：基于准确率、速度、分类表现计算拾光年龄
- **分类支持**：影视、音乐、事件三大分类

### 2. 拾光收藏夹
- **收藏管理**：收藏喜欢的题目
- **批量操作**：支持批量取消收藏、分享
- **详情查看**：查看题目详情和解析

### 3. 拾光成就体系
- **8种成就**：从拾光初遇到拾光全勤人
- **解锁条件**：基于答题表现、收藏数量、连续天数等
- **奖励机制**：解锁成就获得徽章和特殊奖励

### 4. 语音辅助功能
- **语音读题**：支持题目和选项朗读
- **速度调节**：5档语速可选
- **老年友好**：专为老年用户优化

### 5. 个性化设置
- **评语风格**：通用版/老年友好版
- **字体大小**：4档字体大小
- **语音设置**：开关和速度调节
- **主题设置**：拾光复古主题

## 数据库设计

### 题目表 (questions)
- id, content, category, difficulty, echo_theme
- options, correct_answer, explanation
- is_new, created_at

### 拾光收藏夹表 (echo_collection)
- id, question_id, echo_note, collection_time

### 拾光成就表 (echo_achievement)
- id, achievement_name, achievement_icon
- reward, condition, is_unlocked, unlocked_at

### 测试记录表 (test_records)
- id, total_questions, correct_answers, accuracy
- total_time, echo_age, comment, test_time, category_scores

### 题库更新日志表 (question_update_log)
- id, app_name, new_question_count, version
- update_time, is_updated

## 成就系统

| 成就名称 | 达成条件 | 奖励 |
|---------|---------|------|
| 拾光初遇 | 完成首次测试 | 解锁拾光徽章・初遇 |
| 影视拾光者 | 影视分类正确率≥90% | 解锁影视徽章+收藏夹容量+5题 |
| 音乐回响者 | 音乐分类正确率≥90% | 解锁音乐徽章+收藏夹容量+5题 |
| 时代见证者 | 事件分类正确率≥90% | 解锁事件徽章+收藏夹容量+5题 |
| 拾光速答手 | 单题平均耗时≤15秒 | 解锁速答徽章+拾光年龄-1岁 |
| 拾光挑战者 | 困难题正确率100% | 解锁挑战徽章+拾光年龄-2岁 |
| 拾光收藏家 | 收藏题目≥20道 | 解锁收藏徽章+收藏夹容量+10题 |
| 拾光全勤人 | 连续7天每天测试 | 解锁全勤徽章+随机语录 |

## 安装运行

### 环境要求
- Flutter 3.4.0+
- Dart 3.0+
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### 安装步骤
1. 克隆项目
```bash
git clone <repository-url>
cd time_echo
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行项目
```bash
flutter run
```

### 平台支持
- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux
- ✅ Web

## 开发说明

### 状态管理
使用Provider进行状态管理，AppStateProvider作为全局状态提供者。

### 数据库操作
所有数据库操作通过Service层封装，确保数据一致性。

### 语音功能
基于flutter_tts实现，支持中文语音合成。

### 离线更新
通过本地资源文件实现题库更新，无需网络连接。

## 版本信息

- **当前版本**：1.0.0
- **最低SDK版本**：Flutter 3.4.0
- **目标平台**：iOS 11+, Android API 21+

## 许可证

本项目采用私有许可证，仅供内部使用。

## 联系方式

如有问题或建议，请联系开发团队。

---

**拾光机** - 让每一份时光记忆都值得珍藏 ✨