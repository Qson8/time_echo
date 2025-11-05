import 'dart:math';
import '../models/question.dart';
import 'json_storage_service.dart';

/// 题目服务类（使用JSON文件存储）
class QuestionService {
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;
  QuestionService._internal();

  final _storage = JsonStorageService();

  /// 获取所有题目
  Future<List<Question>> getAllQuestions() async {
    return await _storage.getAllQuestions();
  }

  /// 根据分类获取题目
  Future<List<Question>> getQuestionsByCategory(String category) async {
    final allQuestions = await _storage.getAllQuestions();
    return allQuestions.where((q) => q.category == category).toList();
  }

  /// 根据难度获取题目
  Future<List<Question>> getQuestionsByDifficulty(String difficulty) async {
    final allQuestions = await _storage.getAllQuestions();
    return allQuestions.where((q) => q.difficulty == difficulty).toList();
  }

  /// 随机获取指定数量的题目
  /// 使用 Dart 层面的随机化以确保跨平台兼容性（特别是 HarmonyOS）
  Future<List<Question>> getRandomQuestions(int count) async {
    try {
      final allQuestions = await _storage.getAllQuestions();
      
      // 如果题目数量不足，直接返回所有题目
      if (allQuestions.length <= count) {
        return allQuestions;
      }
      
      // 使用 Dart 的 Random 和 shuffle 进行随机化
      final random = Random();
      final shuffled = List<Question>.from(allQuestions)..shuffle(random);
      
      // 返回前 count 个题目
      return shuffled.take(count).toList();
    } catch (e) {
      print('获取随机题目失败: $e');
      // 如果出错，返回空列表
      return [];
    }
  }

  /// 根据ID获取题目
  Future<Question?> getQuestionById(int id) async {
    return await _storage.getQuestionById(id);
  }

  /// 根据ID列表获取题目
  Future<List<Question>> getQuestionsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    
    final allQuestions = await _storage.getAllQuestions();
    final idSet = ids.toSet();
    return allQuestions.where((q) => idSet.contains(q.id)).toList();
  }

  /// 获取新题目数量
  Future<int> getNewQuestionCount() async {
    final allQuestions = await _storage.getAllQuestions();
    return allQuestions.where((q) => q.isNew).length;
  }

  /// 标记新题目为已读
  Future<void> markNewQuestionsAsRead() async {
    final allQuestions = await _storage.getAllQuestions();
    for (final question in allQuestions) {
      if (question.isNew) {
        final updatedQuestion = Question(
          id: question.id,
          content: question.content,
          category: question.category,
          difficulty: question.difficulty,
          echoTheme: question.echoTheme,
          options: question.options,
          correctAnswer: question.correctAnswer,
          explanation: question.explanation,
          isNew: false,
          createdAt: question.createdAt,
        );
        await _storage.updateQuestion(updatedQuestion);
      }
    }
  }

  /// 添加新题目
  Future<void> addQuestion(Question question) async {
    await _storage.addQuestion(question);
  }

  /// 批量添加题目
  Future<void> addQuestions(List<Question> questions) async {
    await _storage.addQuestions(questions);
  }

  /// 获取题目总数
  Future<int> getTotalQuestionCount() async {
    final allQuestions = await _storage.getAllQuestions();
    return allQuestions.length;
  }

  /// 根据主题获取题目
  Future<List<Question>> getQuestionsByTheme(String theme) async {
    final allQuestions = await _storage.getAllQuestions();
    return allQuestions.where((q) => q.echoTheme == theme).toList();
  }

  /// 均衡分布组题（按分类、难度、年代均衡分配）
  /// 确保每个分类、难度、年代都有题目，避免分布不均
  Future<List<Question>> getBalancedQuestions(int count) async {
    try {
      final allQuestions = await _storage.getAllQuestions();
      
      if (allQuestions.isEmpty) return [];
      if (allQuestions.length <= count) return allQuestions;

      final categories = ['影视', '音乐', '事件'];
      final difficulties = ['简单', '中等', '困难'];
      final eras = ['80年代', '90年代', '00年代'];
      
      final selectedQuestions = <Question>[];
      final usedQuestionIds = <int>{};
      final random = Random();

      // 1. 按分类均衡分配（每个分类至少 count/3 道题目）
      final categoryCount = (count / categories.length).ceil();
      for (final category in categories) {
        final categoryQuestions = allQuestions
            .where((q) => q.category == category && !usedQuestionIds.contains(q.id))
            .toList();
        categoryQuestions.shuffle(random);
        final selected = categoryQuestions.take(categoryCount).toList();
        selectedQuestions.addAll(selected);
        usedQuestionIds.addAll(selected.map((q) => q.id));
      }

      // 2. 按难度均衡分配（简单33%、中等50%、困难17%）
      final difficultyCounts = {
        '简单': (count * 0.33).round(),
        '中等': (count * 0.50).round(),
        '困难': (count * 0.17).round(),
      };
      
      // 如果当前题目不足，按难度补充
      if (selectedQuestions.length < count) {
        for (final entry in difficultyCounts.entries) {
          final difficulty = entry.key;
          final targetCount = entry.value;
          final currentCount = selectedQuestions.where((q) => q.difficulty == difficulty).length;
          final needCount = targetCount - currentCount;
          
          if (needCount > 0) {
            final difficultyQuestions = allQuestions
                .where((q) => q.difficulty == difficulty && !usedQuestionIds.contains(q.id))
                .toList();
            difficultyQuestions.shuffle(random);
            final selected = difficultyQuestions.take(needCount).toList();
            selectedQuestions.addAll(selected);
            usedQuestionIds.addAll(selected.map((q) => q.id));
          }
        }
      }

      // 3. 按年代均衡分配（每个年代约 count/3 道题目）
      final eraCount = (count / eras.length).ceil();
      final eraCounts = <String, int>{};
      for (final era in eras) {
        eraCounts[era] = eraCount;
      }
      
      // 如果当前题目不足，按年代补充
      if (selectedQuestions.length < count) {
        for (final era in eras) {
          final currentCount = selectedQuestions.where((q) => q.echoTheme.contains(era)).length;
          final needCount = eraCounts[era]! - currentCount;
          
          if (needCount > 0) {
            final eraQuestions = allQuestions
                .where((q) => q.echoTheme.contains(era) && !usedQuestionIds.contains(q.id))
                .toList();
            eraQuestions.shuffle(random);
            final selected = eraQuestions.take(needCount).toList();
            selectedQuestions.addAll(selected);
            usedQuestionIds.addAll(selected.map((q) => q.id));
          }
        }
      }

      // 4. 如果题目仍不足，随机补充
      if (selectedQuestions.length < count) {
        final remainingQuestions = allQuestions
            .where((q) => !usedQuestionIds.contains(q.id))
            .toList();
        remainingQuestions.shuffle(random);
        final needCount = count - selectedQuestions.length;
        selectedQuestions.addAll(remainingQuestions.take(needCount));
      }

      // 5. 如果题目超过要求，随机截取
      if (selectedQuestions.length > count) {
        selectedQuestions.shuffle(random);
        return selectedQuestions.take(count).toList();
      }

      // 6. 最后打乱顺序
      selectedQuestions.shuffle(random);
      return selectedQuestions;
    } catch (e) {
      print('均衡组题失败: $e');
      // 如果失败，回退到随机选择
      return getRandomQuestions(count);
    }
  }

  /// 根据条件过滤题目
  Future<List<Question>> getFilteredQuestions({
    List<String>? categories,
    List<String>? eras,
    List<String>? difficulties,
  }) async {
    final allQuestions = await getAllQuestions();
    
    print('🔍 开始过滤题目：');
    print('   分类条件：$categories');
    print('   年代条件：$eras');
    print('   难度条件：$difficulties');
    print('   总题目数：${allQuestions.length}');
    
    final filtered = allQuestions.where((question) {
      // 分类过滤
      if (categories != null && categories.isNotEmpty) {
        if (!categories.contains(question.category)) {
          return false;
        }
      }
      
      // 年代过滤
      if (eras != null && eras.isNotEmpty) {
        bool matchesEra = false;
        for (final era in eras) {
          // 检查 echoTheme 是否包含该年代
          if (question.echoTheme.contains(era)) {
            matchesEra = true;
            break;
          }
        }
        if (!matchesEra) {
          return false;
        }
      }
      
      // 难度过滤
      if (difficulties != null && difficulties.isNotEmpty) {
        if (!difficulties.contains(question.difficulty)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    print('✅ 过滤完成：找到 ${filtered.length} 道符合条件的题目');
    
    // 统计过滤后的题目分布
    if (filtered.isNotEmpty) {
      final categoryStats = <String, int>{};
      final eraStats = <String, int>{};
      final difficultyStats = <String, int>{};
      
      for (final q in filtered) {
        categoryStats[q.category] = (categoryStats[q.category] ?? 0) + 1;
        difficultyStats[q.difficulty] = (difficultyStats[q.difficulty] ?? 0) + 1;
        
        if (q.echoTheme.contains('80年代')) {
          eraStats['80年代'] = (eraStats['80年代'] ?? 0) + 1;
        } else if (q.echoTheme.contains('90年代')) {
          eraStats['90年代'] = (eraStats['90年代'] ?? 0) + 1;
        } else if (q.echoTheme.contains('00年代')) {
          eraStats['00年代'] = (eraStats['00年代'] ?? 0) + 1;
        }
      }
      
      print('   分类分布：$categoryStats');
      print('   年代分布：$eraStats');
      print('   难度分布：$difficultyStats');
    }
    
    return filtered;
  }

  /// 根据条件随机获取指定数量的题目
  Future<List<Question>> getRandomQuestionsWithFilters({
    required int count,
    List<String>? categories,
    List<String>? eras,
    List<String>? difficulties,
  }) async {
    final filteredQuestions = await getFilteredQuestions(
      categories: categories,
      eras: eras,
      difficulties: difficulties,
    );
    
    if (filteredQuestions.isEmpty) {
      return [];
    }
    
    // 如果过滤后的题目数量不足，返回所有符合条件的题目
    if (filteredQuestions.length <= count) {
      final random = Random();
      final shuffled = List<Question>.from(filteredQuestions)..shuffle(random);
      return shuffled;
    }
    
    // 如果题目足够，随机选择指定数量
    final random = Random();
    final shuffled = List<Question>.from(filteredQuestions)..shuffle(random);
    return shuffled.take(count).toList();
  }

  /// 根据条件均衡获取指定数量的题目
  Future<List<Question>> getBalancedQuestionsWithFilters({
    required int count,
    List<String>? categories,
    List<String>? eras,
    List<String>? difficulties,
  }) async {
    final filteredQuestions = await getFilteredQuestions(
      categories: categories,
      eras: eras,
      difficulties: difficulties,
    );
    
    if (filteredQuestions.isEmpty) return [];
    
    // 如果过滤后的题目数量不足，直接返回所有题目（打乱顺序）
    if (filteredQuestions.length <= count) {
      final random = Random();
      final shuffled = List<Question>.from(filteredQuestions)..shuffle(random);
      print('📌 符合条件的题目只有 ${filteredQuestions.length} 道（请求 $count 道），返回全部题目');
      return shuffled;
    }
    
    final selectedQuestions = <Question>[];
    final usedQuestionIds = <int>{};
    final random = Random();
    
    // 使用筛选后的题目列表进行均衡分配
    final availableCategories = categories ?? ['影视', '音乐', '事件'];
    final availableEras = eras ?? ['80年代', '90年代', '00年代'];
    final availableDifficulties = difficulties ?? ['简单', '中等', '困难'];
    
    // 按分类均衡分配
    final categoryCount = (count / availableCategories.length).ceil();
    for (final category in availableCategories) {
      final categoryQuestions = filteredQuestions
          .where((q) => q.category == category && !usedQuestionIds.contains(q.id))
          .toList();
      if (categoryQuestions.isNotEmpty) {
        categoryQuestions.shuffle(random);
        final selected = categoryQuestions.take(categoryCount).toList();
        selectedQuestions.addAll(selected);
        usedQuestionIds.addAll(selected.map((q) => q.id));
      }
    }
    
    // 按难度均衡分配
    final difficultyCounts = {
      '简单': (count * 0.33).round(),
      '中等': (count * 0.50).round(),
      '困难': (count * 0.17).round(),
    };
    
    if (selectedQuestions.length < count) {
      for (final difficulty in availableDifficulties) {
        final targetCount = difficultyCounts[difficulty] ?? 0;
        final currentCount = selectedQuestions
            .where((q) => q.difficulty == difficulty)
            .length;
        final needCount = targetCount - currentCount;
        
        if (needCount > 0) {
          final difficultyQuestions = filteredQuestions
              .where((q) => 
                  q.difficulty == difficulty && 
                  !usedQuestionIds.contains(q.id))
              .toList();
          if (difficultyQuestions.isNotEmpty) {
            difficultyQuestions.shuffle(random);
            final selected = difficultyQuestions.take(needCount).toList();
            selectedQuestions.addAll(selected);
            usedQuestionIds.addAll(selected.map((q) => q.id));
          }
        }
      }
    }
    
    // 按年代均衡分配
    final eraCount = (count / availableEras.length).ceil();
    if (selectedQuestions.length < count) {
      for (final era in availableEras) {
        final currentCount = selectedQuestions
            .where((q) => q.echoTheme.contains(era))
            .length;
        final needCount = eraCount - currentCount;
        
        if (needCount > 0) {
          final eraQuestions = filteredQuestions
              .where((q) => 
                  q.echoTheme.contains(era) && 
                  !usedQuestionIds.contains(q.id))
              .toList();
          if (eraQuestions.isNotEmpty) {
            eraQuestions.shuffle(random);
            final selected = eraQuestions.take(needCount).toList();
            selectedQuestions.addAll(selected);
            usedQuestionIds.addAll(selected.map((q) => q.id));
          }
        }
      }
    }
    
    // 如果题目仍不足，随机补充
    if (selectedQuestions.length < count) {
      final remainingQuestions = filteredQuestions
          .where((q) => !usedQuestionIds.contains(q.id))
          .toList();
      if (remainingQuestions.isNotEmpty) {
        remainingQuestions.shuffle(random);
        final needCount = count - selectedQuestions.length;
        final availableCount = remainingQuestions.length;
        // 尽可能填充到接近请求的数量
        selectedQuestions.addAll(
          remainingQuestions.take(needCount < availableCount ? needCount : availableCount)
        );
      }
    }
    
    // 如果题目超过要求，随机截取
    if (selectedQuestions.length > count) {
      selectedQuestions.shuffle(random);
      return selectedQuestions.take(count).toList();
    }
    
    // 确保返回的题目数量尽可能接近请求数量
    // 如果还有剩余题目未使用，尽量补充
    if (selectedQuestions.length < count) {
      final remainingQuestions = filteredQuestions
          .where((q) => !usedQuestionIds.contains(q.id))
          .toList();
      if (remainingQuestions.isNotEmpty) {
        remainingQuestions.shuffle(random);
        final needCount = count - selectedQuestions.length;
        selectedQuestions.addAll(
          remainingQuestions.take(needCount < remainingQuestions.length ? needCount : remainingQuestions.length)
        );
      }
    }
    
    // 最后打乱顺序
    selectedQuestions.shuffle(random);
    
    print('📊 均衡分配完成：选中 ${selectedQuestions.length} 道题目（请求 $count 道，可用 ${filteredQuestions.length} 道）');
    return selectedQuestions;
  }
}
