/// 应用常量
class AppConstants {
  // 应用信息
  static const String appName = '拾光机';
  static const String appNameEn = 'Time Echo';
  static const String appVersion = '1.0.0';
  
  // 颜色主题
  static const int primaryColor = 0xFF8B4513; // 拾光棕（焦糖棕）
  static const int secondaryColor = 0xFFF8F5F0; // 浅相纸白
  static const int accentColor = 0xFF2E7D32; // 深灰绿
  static const int errorColor = 0xFFC74B50; // 深灰红
  
  // 题目分类
  static const List<String> categories = ['影视', '音乐', '事件'];
  
  // 难度等级
  static const List<String> difficulties = ['简单', '中等', '困难'];
  
  // 拾光主题
  static const List<String> echoThemes = [
    '80年代影视',
    '90年代音乐',
    '80年代事件',
    '90年代影视',
    '90年代事件',
  ];
  
  // 成就类型
  static const Map<int, String> achievementTypes = {
    1: '拾光初遇',
    2: '影视拾光者',
    3: '音乐回响者',
    4: '时代见证者',
    5: '拾光速答手',
    6: '拾光挑战者',
    7: '拾光收藏家',
    8: '拾光全勤人',
  };
  
  // 拾光语录
  static const Map<String, List<String>> echoQuotes = {
    '影视': [
      '每帧画面，都是时光的印记～',
      '银幕上的故事，承载着我们的青春～',
      '经典永不过时，回忆永远珍贵～',
    ],
    '音乐': [
      '旋律响起，时光重回眼前～',
      '音符跳跃间，藏着岁月的秘密～',
      '一首老歌，一段回忆～',
    ],
    '事件': [
      '每段故事，都是时光的礼物～',
      '历史的长河中，我们都是见证者～',
      '那些年，我们一起走过的岁月～',
    ],
    '收藏': [
      '每道收藏，都是时光的碎片～',
      '珍藏的不仅是题目，更是回忆～',
      '拾光收藏夹，装满美好时光～',
    ],
    '全勤': [
      '7天拾光之旅，满是回忆的温度～',
      '坚持的每一天，都是对时光的致敬～',
      '拾光路上，感谢有你的陪伴～',
    ],
  };
  
  // 老年友好版评语
  static const Map<String, String> elderlyFriendlyComments = {
    'excellent': '您对老时光的记忆真清晰，拾光机为您点赞～',
    'good': '您的怀旧情怀让人感动，继续保持～',
    'average': '您对过往时光有一定了解，继续探索吧～',
    'poor': '没关系，每个人都有自己的时光记忆～',
  };
  
  // 通用版评语
  static const Map<String, String> generalComments = {
    'excellent': '你是复古圈的新势力！',
    'good': '你对怀旧文化很有研究～',
    'average': '你对过往时光有一定了解',
    'poor': '看来你需要多了解一些怀旧文化',
  };
  
  // 数据库表名
  static const String tableQuestions = 'questions';
  static const String tableEchoCollection = 'echo_collection';
  static const String tableEchoAchievement = 'echo_achievement';
  static const String tableTestRecords = 'test_records';
  static const String tableQuestionUpdateLog = 'question_update_log';
  
  // 本地存储键
  static const String keyFirstLaunch = 'first_launch';
  static const String keyVoiceEnabled = 'voice_enabled';
  static const String keyVoiceSpeed = 'voice_speed';
  static const String keyCommentStyle = 'comment_style';
  static const String keyFontSize = 'font_size';
  static const String keyElderlyMode = 'elderly_mode';
  static const String keyLastTestDate = 'last_test_date';
  
  // 语音设置
  static const Map<String, double> voiceSpeeds = {
    '极慢': 0.2,
    '慢': 0.4,
    '中': 0.5,
    '快': 0.7,
    '极快': 0.9,
  };
  
  // 字体大小
  static const Map<String, double> fontSizes = {
    '小': 14.0,
    '中': 16.0,
    '大': 18.0,
    '特大': 20.0,
  };
  
  // 动画时长
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // 题目数量设置
  static const int defaultQuestionCount = 10;
  static const int minQuestionCount = 5;
  static const int maxQuestionCount = 20;
  
  // 成就解锁条件
  static const Map<int, Map<String, dynamic>> achievementConditions = {
    1: {'type': 'first_test', 'value': 1},
    2: {'type': 'category_accuracy', 'category': '影视', 'value': 90},
    3: {'type': 'category_accuracy', 'category': '音乐', 'value': 90},
    4: {'type': 'category_accuracy', 'category': '事件', 'value': 90},
    5: {'type': 'speed', 'value': 15}, // 秒
    6: {'type': 'difficulty_accuracy', 'difficulty': '困难', 'value': 100},
    7: {'type': 'collection_count', 'value': 20},
    8: {'type': 'consecutive_days', 'value': 7},
  };
}
