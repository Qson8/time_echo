import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../services/app_state_provider.dart';
import '../services/local_storage_service.dart';
import '../services/question_service.dart';
import '../models/question.dart';
import 'quiz_screen.dart';

/// 题目配置页面
class QuizConfigScreen extends StatefulWidget {
  const QuizConfigScreen({super.key});

  @override
  State<QuizConfigScreen> createState() => _QuizConfigScreenState();
}

class _QuizConfigScreenState extends State<QuizConfigScreen> {
  // 题目数量
  int _questionCount = 10;
  final List<int> _questionCountOptions = [5, 10, 15, 20, 30];
  
  // 分类选择（多选）
  Set<String> _selectedCategories = {'影视', '音乐', '事件'};
  final List<String> _categories = ['影视', '音乐', '事件'];
  
  // 年代选择（多选）
  Set<String> _selectedEras = {'80年代', '90年代', '00年代'};
  final List<String> _eras = ['80年代', '90年代', '00年代'];
  
  // 难度选择（多选）
  Set<String> _selectedDifficulties = {'简单', '中等', '困难'};
  final List<String> _difficulties = ['简单', '中等', '困难'];
  
  // 组题模式
  QuestionSelectionMode _selectionMode = QuestionSelectionMode.balanced;
  
  final LocalStorageService _localStorageService = LocalStorageService();
  bool _isLoading = true;
  int _availableQuestionCount = 0; // 符合条件的题目数量

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  /// 检查符合条件的题目数量
  Future<void> _checkAvailableQuestions() async {
    try {
      final questionService = QuestionService();
      final filteredQuestions = await questionService.getFilteredQuestions(
        categories: _selectedCategories.toList(),
        eras: _selectedEras.toList(),
        difficulties: _selectedDifficulties.toList(),
      );
      
      if (mounted) {
        setState(() {
          _availableQuestionCount = filteredQuestions.length;
        });
      }
    } catch (e) {
      print('❌ 检查题目数量失败: $e');
    }
  }

  /// 加载保存的配置
  Future<void> _loadSavedConfig() async {
    try {
      final config = await _localStorageService.getQuizConfig();
      if (config != null && mounted) {
        setState(() {
          _questionCount = config['questionCount'] as int? ?? 10;
          _selectedCategories = (config['categories'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              {'影视', '音乐', '事件'};
          _selectedEras = (config['eras'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              {'80年代', '90年代', '00年代'};
          _selectedDifficulties = (config['difficulties'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              {'简单', '中等', '困难'};
          
          final modeStr = config['selectionMode'] as String? ?? 'balanced';
          switch (modeStr) {
            case 'random':
              _selectionMode = QuestionSelectionMode.random;
              break;
            case 'balanced':
              _selectionMode = QuestionSelectionMode.balanced;
              break;
            case 'smart':
              _selectionMode = QuestionSelectionMode.smart;
              break;
            default:
              _selectionMode = QuestionSelectionMode.balanced;
          }
          _isLoading = false;
        });
        print('✅ 已加载保存的配置');
        // 加载配置后检查题目数量
        _checkAvailableQuestions();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // 即使没有保存的配置，也检查默认配置的题目数量
        _checkAvailableQuestions();
      }
    } catch (e) {
      print('❌ 加载配置失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('定制题目'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题说明
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(AppConstants.primaryColor),
                    const Color(AppConstants.primaryColor).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.tune, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    '定制你的拾光之旅',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '选择你想要的题目类型，开始个性化的怀旧之旅',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 题目数量提示
            if (_availableQuestionCount > 0)
              _buildQuestionCountHint(),
            
            const SizedBox(height: 16),
            
            // 题目数量
            _buildSectionTitle('题目数量', Icons.numbers),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: _questionCountOptions.map((count) {
                  final isSelected = _questionCount == count;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ChoiceChip(
                        label: Text(
                          '$count 道',
                          style: const TextStyle(fontSize: 13),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _questionCount = count;
                            });
                            // 检查题目数量
                            _checkAvailableQuestions();
                          }
                        },
                        selectedColor: const Color(AppConstants.primaryColor),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 分类选择
            _buildSectionTitle('题目分类', Icons.category),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(
                          category,
                          style: const TextStyle(fontSize: 13),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                              // 至少保留一个分类
                              if (_selectedCategories.isEmpty) {
                                _selectedCategories.add(category);
                              }
                            }
                          });
                          // 检查题目数量
                          _checkAvailableQuestions();
                        },
                        selectedColor: _getCategoryColor(category).withOpacity(0.2),
                        checkmarkColor: _getCategoryColor(category),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 年代选择
            _buildSectionTitle('怀旧年代', Icons.calendar_today),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: _eras.map((era) {
                  final isSelected = _selectedEras.contains(era);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(
                          era,
                          style: const TextStyle(fontSize: 13),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedEras.add(era);
                            } else {
                              _selectedEras.remove(era);
                              // 至少保留一个年代
                              if (_selectedEras.isEmpty) {
                                _selectedEras.add(era);
                              }
                            }
                          });
                          // 检查题目数量
                          _checkAvailableQuestions();
                        },
                        selectedColor: Colors.orange.withOpacity(0.2),
                        checkmarkColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 难度选择
            _buildSectionTitle('题目难度', Icons.star),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: _difficulties.map((difficulty) {
                  final isSelected = _selectedDifficulties.contains(difficulty);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FilterChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: _getDifficultyColor(difficulty),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              difficulty,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDifficulties.add(difficulty);
                            } else {
                              _selectedDifficulties.remove(difficulty);
                              // 至少保留一个难度
                              if (_selectedDifficulties.isEmpty) {
                                _selectedDifficulties.add(difficulty);
                              }
                            }
                          });
                          // 检查题目数量
                          _checkAvailableQuestions();
                        },
                        selectedColor: _getDifficultyColor(difficulty).withOpacity(0.2),
                        checkmarkColor: _getDifficultyColor(difficulty),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 组题模式
            _buildSectionTitle('组题模式', Icons.settings),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: QuestionSelectionMode.values.map((mode) {
                  final isSelected = _selectionMode == mode;
                  return RadioListTile<QuestionSelectionMode>(
                    title: Text(_getModeName(mode)),
                    subtitle: Text(_getModeDescription(mode)),
                    value: mode,
                    groupValue: _selectionMode,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectionMode = value;
                        });
                      }
                    },
                    activeColor: const Color(AppConstants.primaryColor),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 开始按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text(
                      '开始拾光',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(AppConstants.primaryColor), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '影视':
        return Colors.purple;
      case '音乐':
        return Colors.blue;
      case '事件':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '简单':
        return Colors.green;
      case '中等':
        return Colors.amber;
      case '困难':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// 构建题目数量提示
  Widget _buildQuestionCountHint() {
    final isEnough = _availableQuestionCount >= _questionCount;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnough 
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnough 
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEnough ? Icons.check_circle : Icons.warning,
            color: isEnough ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEnough
                  ? '符合条件的题目有 $_availableQuestionCount 道，足够使用'
                  : '符合条件的题目只有 $_availableQuestionCount 道，少于选择的 $_questionCount 道',
              style: TextStyle(
                fontSize: 13,
                color: isEnough ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getModeName(QuestionSelectionMode mode) {
    switch (mode) {
      case QuestionSelectionMode.random:
        return '随机模式';
      case QuestionSelectionMode.balanced:
        return '均衡模式';
      case QuestionSelectionMode.smart:
        return '智能推荐';
    }
  }

  String _getModeDescription(QuestionSelectionMode mode) {
    switch (mode) {
      case QuestionSelectionMode.random:
        return '完全随机选择题目，简单高效';
      case QuestionSelectionMode.balanced:
        return '按分类、难度、年代均衡分配，体验更全面';
      case QuestionSelectionMode.smart:
        return '根据你的答题历史智能推荐，个性化体验';
    }
  }

  void _startQuiz() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    // 检查题目数量是否足够
    if (_availableQuestionCount < _questionCount) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('题目数量不足'),
          content: Text(
            '根据当前筛选条件，符合条件的题目只有 $_availableQuestionCount 道，\n'
            '但您选择了 $_questionCount 道题目。\n\n'
            '是否继续使用现有的 $_availableQuestionCount 道题目？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) {
        return; // 用户取消
      }
    }
    
    // 显示加载提示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 保存配置到本地存储
      final modeStr = _selectionMode.toString().split('.').last;
      await _localStorageService.saveQuizConfig(
        questionCount: _questionCount,
        categories: _selectedCategories.toList(),
        eras: _selectedEras.toList(),
        difficulties: _selectedDifficulties.toList(),
        selectionMode: modeStr,
      );
      
      // 开始拾光，传入配置参数
      await appState.startTestWithFilters(
        questionCount: _questionCount,
        mode: _selectionMode,
        categories: _selectedCategories.toList(),
        eras: _selectedEras.toList(),
        difficulties: _selectedDifficulties.toList(),
      );

      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        
        // 验证定制项是否生效
        final questions = appState.currentTestQuestions;
        final actualCount = questions.length;
        
        // 检查分类
        final actualCategories = questions.map((q) => q.category).toSet();
        final invalidCategories = actualCategories.where((c) => !_selectedCategories.contains(c)).toList();
        
        // 检查年代
        final actualEras = questions.map((q) {
          if (q.echoTheme.contains('80年代')) return '80年代';
          if (q.echoTheme.contains('90年代')) return '90年代';
          if (q.echoTheme.contains('00年代')) return '00年代';
          return '';
        }).where((e) => e.isNotEmpty).toSet();
        final invalidEras = actualEras.where((e) => !_selectedEras.contains(e)).toList();
        
        // 检查难度
        final actualDifficulties = questions.map((q) => q.difficulty).toSet();
        final invalidDifficulties = actualDifficulties.where((d) => !_selectedDifficulties.contains(d)).toList();
        
        // 构建提示信息
        final List<String> warnings = [];
        if (actualCount < _questionCount) {
          warnings.add('符合筛选条件的题目只有 $actualCount 道（请求 $_questionCount 道）');
        }
        if (invalidCategories.isNotEmpty) {
          warnings.add('发现不符合分类要求的题目：$invalidCategories（应只包含：${_selectedCategories.join('、')}）');
        }
        if (invalidEras.isNotEmpty) {
          warnings.add('发现不符合年代要求的题目：$invalidEras（应只包含：${_selectedEras.join('、')}）');
        }
        if (invalidDifficulties.isNotEmpty) {
          warnings.add('发现不符合难度要求的题目：$invalidDifficulties（应只包含：${_selectedDifficulties.join('、')}）');
        }
        
        if (warnings.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(w, style: const TextStyle(fontSize: 13)),
                )).toList(),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QuizScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('开始拾光失败：$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

