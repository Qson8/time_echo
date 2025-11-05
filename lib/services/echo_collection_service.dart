import '../models/echo_collection.dart';
import '../models/question.dart';
import 'json_storage_service.dart';
import 'question_service.dart';

/// 拾光收藏夹服务类（使用JSON文件存储）
class EchoCollectionService {
  static final EchoCollectionService _instance = EchoCollectionService._internal();
  factory EchoCollectionService() => _instance;
  EchoCollectionService._internal();
  
  final _storage = JsonStorageService();

  /// 添加收藏
  Future<void> addCollection(int questionId, {String note = ''}) async {
    try {
      print('📚 开始添加收藏，questionId=$questionId');
      
      // 检查是否已收藏
      final existing = await isCollected(questionId);
      if (existing) {
        print('📚 ⚠️ 题目已收藏，跳过');
        return;
      }
      
      // 获取所有收藏以生成新ID
      final allCollections = await _storage.getAllCollections();
      int newId = 1;
      if (allCollections.isNotEmpty) {
        final maxId = allCollections.map((c) => c.id).reduce((a, b) => a > b ? a : b);
        newId = maxId + 1;
      }
      
      final collection = EchoCollection(
        id: newId,
        questionId: questionId,
        echoNote: note,
        collectionTime: DateTime.now(),
      );
      
      await _storage.addCollection(collection);
      print('📚 ✅ 收藏已添加到JSON存储，收藏ID=$newId, questionId=$questionId');
      
      // 验证收藏是否成功保存
      final verifyCollections = await _storage.getAllCollections();
      final verifyCount = verifyCollections.where((c) => c.questionId == questionId).length;
      print('📚 验证：当前有 $verifyCount 条questionId=$questionId 的收藏记录');
      print('📚 总收藏记录数: ${verifyCollections.length}');
    } catch (e, stackTrace) {
      print('📚 ❌ 添加收藏失败: $e');
      print('📚 ❌ 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 取消收藏
  Future<void> removeCollection(int questionId) async {
    try {
      final allCollections = await _storage.getAllCollections();
      final collection = allCollections.firstWhere(
        (c) => c.questionId == questionId,
        orElse: () => throw Exception('收藏不存在'),
      );
      
      await _storage.removeCollection(collection.id);
      print('📚 ✅ 收藏已从JSON存储移除');
    } catch (e) {
      print('📚 ❌ 取消收藏失败: $e');
      // 不抛出异常，静默失败
    }
  }

  /// 检查是否已收藏
  Future<bool> isCollected(int questionId) async {
    try {
      final allCollections = await _storage.getAllCollections();
      return allCollections.any((c) => c.questionId == questionId);
    } catch (e) {
      print('📚 ❌ 检查收藏状态失败: $e');
      return false;
    }
  }

  /// 获取所有收藏
  Future<List<EchoCollection>> getAllCollections() async {
    try {
      final collections = await _storage.getAllCollections();
      // 按收藏时间降序排序
      collections.sort((a, b) => b.collectionTime.compareTo(a.collectionTime));
      return collections;
    } catch (e) {
      print('📚 ❌ 获取所有收藏失败: $e');
      return [];
    }
  }

  /// 获取收藏的题目详情
  Future<List<Question>> getCollectedQuestions() async {
    try {
      final collections = await getAllCollections();
      print('📚 获取收藏的题目详情：收藏记录数量=${collections.length}');
      if (collections.isEmpty) {
        print('📚 没有收藏记录');
        return [];
      }
      
      final questionIds = collections.map((c) => c.questionId).toList();
      print('📚 收藏的题目ID列表: $questionIds');
      
      final questionService = QuestionService();
      final questions = await questionService.getQuestionsByIds(questionIds);
      print('📚 找到的题目数量: ${questions.length} (期望: ${questionIds.length})');
      
      // 检查是否有缺失的题目
      final foundIds = questions.map((q) => q.id).toSet();
      final missingIds = questionIds.where((id) => !foundIds.contains(id)).toList();
      if (missingIds.isNotEmpty) {
        print('📚 ⚠️ 以下题目ID在题目列表中不存在: $missingIds');
      }
      
      // 按收藏时间排序
      final collectionMap = {for (var c in collections) c.questionId: c};
      questions.sort((a, b) {
        final timeA = collectionMap[a.id]?.collectionTime ?? DateTime(1970);
        final timeB = collectionMap[b.id]?.collectionTime ?? DateTime(1970);
        return timeB.compareTo(timeA); // 降序
      });
      
      print('📚 ✅ 返回 ${questions.length} 个收藏的题目');
      return questions;
    } catch (e, stackTrace) {
      print('📚 ❌ 获取收藏题目失败: $e');
      print('📚 ❌ 错误堆栈: $stackTrace');
      return [];
    }
  }

  /// 获取收藏数量
  Future<int> getCollectionCount() async {
    final collections = await getAllCollections();
    return collections.length;
  }

  /// 批量取消收藏
  Future<void> removeCollections(List<int> questionIds) async {
    for (final questionId in questionIds) {
      await removeCollection(questionId);
    }
  }

  /// 更新收藏笔记
  Future<void> updateCollectionNote(int questionId, String note) async {
    try {
      final allCollections = await _storage.getAllCollections();
      final collection = allCollections.firstWhere(
        (c) => c.questionId == questionId,
        orElse: () => throw Exception('收藏不存在'),
      );
      
      final updatedCollection = EchoCollection(
        id: collection.id,
        questionId: collection.questionId,
        echoNote: note,
        collectionTime: collection.collectionTime,
      );
      
      await _storage.addCollection(updatedCollection); // 这会覆盖原有的
      print('📚 ✅ 收藏笔记已更新');
    } catch (e) {
      print('📚 ❌ 更新收藏笔记失败: $e');
      rethrow;
    }
  }

  /// 获取收藏的题目ID列表
  Future<List<int>> getCollectedQuestionIds() async {
    final collections = await getAllCollections();
    return collections.map((c) => c.questionId).toList();
  }

  /// 清除所有收藏
  Future<void> clearAllCollections() async {
    try {
      final collections = await getAllCollections();
      for (final collection in collections) {
        await _storage.removeCollection(collection.id);
      }
      print('📚 ✅ 所有收藏已清除');
    } catch (e) {
      print('📚 ❌ 清除所有收藏失败: $e');
    }
  }

  /// 诊断收藏数据完整性（用于调试）
  Future<Map<String, dynamic>> diagnoseCollectionData() async {
    print('📚 ========== 开始诊断收藏数据 ==========');
    final result = <String, dynamic>{};
    
    try {
      // 1. 检查存储服务是否已初始化
      result['storage_initialized'] = true;
      print('📚 1. 存储服务状态: ✅ 已初始化');
      
      // 2. 获取所有收藏记录
      final collections = await _storage.getAllCollections();
      result['total_collections'] = collections.length;
      print('📚 2. 收藏记录总数: ${collections.length}');
      
      if (collections.isEmpty) {
        result['has_collections'] = false;
        result['message'] = '没有收藏记录';
        print('📚 3. 状态: ⚠️ 没有收藏记录');
        return result;
      }
      
      result['has_collections'] = true;
      
      // 3. 检查是否有重复的 questionId
      final questionIdSet = <int>{};
      final duplicateQuestionIds = <int>[];
      final collectionDetails = <Map<String, dynamic>>[];
      
      for (final c in collections) {
        if (questionIdSet.contains(c.questionId)) {
          duplicateQuestionIds.add(c.questionId);
        } else {
          questionIdSet.add(c.questionId);
        }
        
        collectionDetails.add({
          'id': c.id,
          'questionId': c.questionId,
          'time': c.collectionTime.toIso8601String(),
        });
      }
      
      result['unique_question_ids'] = questionIdSet.length;
      result['duplicate_question_ids'] = duplicateQuestionIds;
      result['collections'] = collectionDetails;
      
      print('📚 3. 唯一题目ID数量: ${questionIdSet.length}');
      if (duplicateQuestionIds.isNotEmpty) {
        print('📚 ⚠️ 发现重复的题目ID: $duplicateQuestionIds');
      }
      
      // 4. 检查题目是否存在
      final questionService = QuestionService();
      final allQuestions = await questionService.getAllQuestions();
      final questionIds = allQuestions.map((q) => q.id).toSet();
      
      final missingQuestionIds = <int>[];
      for (final questionId in questionIdSet) {
        if (!questionIds.contains(questionId)) {
          missingQuestionIds.add(questionId);
        }
      }
      
      result['total_questions'] = allQuestions.length;
      result['missing_question_ids'] = missingQuestionIds;
      result['valid_collections'] = questionIdSet.length - missingQuestionIds.length;
      
      print('📚 4. 题目总数: ${allQuestions.length}');
      print('📚 5. 有效的收藏数（题目存在）: ${questionIdSet.length - missingQuestionIds.length}');
      if (missingQuestionIds.isNotEmpty) {
        print('📚 ⚠️ 以下题目ID在题目列表中不存在: $missingQuestionIds');
      }
      
      result['is_valid'] = missingQuestionIds.isEmpty && duplicateQuestionIds.isEmpty;
      print('📚 6. 数据完整性: ${result['is_valid'] ? "✅ 正常" : "⚠️ 存在问题"}');
      
    } catch (e, stackTrace) {
      result['error'] = e.toString();
      result['stack_trace'] = stackTrace.toString();
      print('📚 ❌ 诊断过程中出错: $e');
      print('📚 ❌ 错误堆栈: $stackTrace');
    }
    
    print('📚 ========== 诊断完成 ==========');
    return result;
  }
}
