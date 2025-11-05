# 故事数据初始化说明

## 📖 概述

时光故事馆需要初始故事数据才能正常显示。本文件说明如何初始化故事数据。

## 📁 数据文件位置

故事数据存储在JSON文件中：
- **存储位置**：应用数据目录下的 `stories.json`
- **模板文件**：`assets/data/stories_template.json`（示例）

## 🔧 初始化方式

### 方式1：通过代码初始化（推荐）

在应用首次启动时，检查故事数据是否存在，如果不存在则从模板文件加载。

**实现示例**：

```dart
// 在 app_state_provider.dart 或 main.dart 中添加初始化逻辑
Future<void> initializeStories() async {
  final storyService = StoryService();
  final stories = await storyService.getAllStories();
  
  // 如果故事为空，从模板加载
  if (stories.isEmpty) {
    await _loadStoriesFromTemplate();
  }
}

Future<void> _loadStoriesFromTemplate() async {
  // 读取 assets/data/stories_template.json
  // 解析并保存到 stories.json
}
```

### 方式2：手动初始化

1. 将 `assets/data/stories_template.json` 复制到应用数据目录
2. 重命名为 `stories.json`
3. 确保数据格式正确

## 📝 数据格式说明

每个故事对象包含以下字段：

```json
{
  "id": 1,                           // 唯一ID（整数）
  "title": "故事标题",                // 标题（字符串）
  "content": "故事内容...",           // 内容（字符串，支持多行）
  "era": "90年代",                   // 年代（80年代/90年代/00年代）
  "category": "影视",                // 分类（影视/音乐/事件）
  "related_question_ids": "1,2,3",   // 关联题目IDs（逗号分隔，可选）
  "tags": "标签1,标签2",             // 标签（逗号分隔，可选）
  "thumbnail": "缩略图描述",          // 缩略图描述（可选）
  "author": "作者名",                 // 作者（可选）
  "publish_time": "2024-01-01T00:00:00.000Z",  // 发布时间（ISO格式）
  "is_favorite": 0                   // 是否收藏（0=否，1=是）
}
```

## ✅ 注意事项

1. **ID唯一性**：确保每个故事的ID唯一
2. **日期格式**：使用ISO 8601格式（`YYYY-MM-DDTHH:mm:ss.sssZ`）
3. **关联题目**：`related_question_ids` 中的ID必须在 `questions.json` 中存在
4. **标签格式**：多个标签用逗号分隔，不要有空格

## 📊 建议的故事数量

为了提供良好的用户体验，建议至少准备：

- **80年代故事**：10-15个
- **90年代故事**：15-20个
- **00年代故事**：5-10个（可选）

每个分类（影视/音乐/事件）都应该有故事。

## 🎯 故事内容建议

### 影视类故事
- 经典电影的背景故事
- 热门电视剧的拍摄花絮
- 演员的经典角色解读

### 音乐类故事
- 经典歌曲的创作背景
- 歌手的成长故事
- 音乐风格的演变

### 事件类故事
- 历史事件的背景
- 社会变迁的见证
- 时代印记的回忆

## 🔄 数据更新

故事数据可以通过以下方式更新：

1. **应用内更新**：在设置页面添加"更新故事库"功能
2. **手动更新**：替换 `stories.json` 文件
3. **版本更新**：随应用版本更新一起发布新故事

## 📌 当前状态

- ✅ 故事数据模型已创建
- ✅ 故事服务已实现
- ✅ 故事浏览页面已创建
- ✅ 模板文件已准备
- ⏳ 等待初始化逻辑实现（可选）

