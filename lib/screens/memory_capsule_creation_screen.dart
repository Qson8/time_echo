import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import '../models/memory_capsule.dart';
import '../services/memory_capsule_service.dart';
import '../services/question_service.dart';
import '../models/question.dart';
import '../services/audio_recorder_service.dart' show AudioRecorderService, createAudioRecorderService;

/// 记忆胶囊创建/编辑页面
class MemoryCapsuleCreationScreen extends StatefulWidget {
  final MemoryCapsule? capsule; // 如果为null，则是新建；否则是编辑

  const MemoryCapsuleCreationScreen({
    super.key,
    this.capsule,
  });

  @override
  State<MemoryCapsuleCreationScreen> createState() => _MemoryCapsuleCreationScreenState();
}

class _MemoryCapsuleCreationScreenState extends State<MemoryCapsuleCreationScreen> {
  final MemoryCapsuleService _service = MemoryCapsuleService();
  final QuestionService _questionService = QuestionService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  late final AudioRecorderService _audioRecorder;

  String _selectedEra = '80年代';
  String _selectedCategory = '影视';
  String _selectedMood = '怀念';
  DateTime? _selectedMemoryDate;
  List<String> _tags = [];
  int? _relatedQuestionId;
  Question? _relatedQuestion;

  String? _imagePath;
  String? _audioPath;
  bool _isRecording = false;
  bool _isSaving = false;

  final List<String> _eras = ['80年代', '90年代', '00年代'];
  final List<String> _categories = ['影视', '音乐', '事件'];
  final List<String> _moods = ['怀念', '感动', '开心', '感慨'];

  @override
  void initState() {
    super.initState();
    _audioRecorder = createAudioRecorderService();
    if (widget.capsule != null) {
      _initializeFromCapsule(widget.capsule!);
    }
  }

  void _initializeFromCapsule(MemoryCapsule capsule) {
    _titleController.text = capsule.title;
    _contentController.text = capsule.content;
    _selectedEra = capsule.era;
    _selectedCategory = capsule.category;
    _selectedMood = capsule.mood;
    _selectedMemoryDate = capsule.memoryDate;
    _locationController.text = capsule.location ?? '';
    _tags = List.from(capsule.tags);
    _relatedQuestionId = capsule.questionId;
    _imagePath = capsule.imagePath;
    _audioPath = capsule.audioPath;

    if (_relatedQuestionId != null) {
      _loadRelatedQuestion();
    }
  }

  Future<void> _loadRelatedQuestion() async {
    if (_relatedQuestionId != null) {
      final question = await _questionService.getQuestionById(_relatedQuestionId!);
      setState(() {
        _relatedQuestion = question;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  /// 选择图片
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // 压缩质量
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  /// 拍照
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    }
  }

  /// 开始录音
  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        final path = await _getTemporaryAudioPath();
        await _audioRecorder.start(path);
        setState(() {
          _isRecording = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要录音权限，或当前平台不支持录音功能')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开始录音失败: $e')),
        );
      }
    }
  }

  /// 停止录音
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _audioPath = path;
          _isRecording = false;
        });
      } else {
        setState(() {
          _isRecording = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止录音失败: $e')),
        );
      }
      setState(() {
        _isRecording = false;
      });
    }
  }

  /// 获取临时音频路径
  Future<String> _getTemporaryAudioPath() async {
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${tempDir.path}/audio_$timestamp.m4a';
  }

  /// 删除图片
  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
  }

  /// 删除音频
  void _removeAudio() {
    setState(() {
      _audioPath = null;
    });
  }

  /// 添加标签
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  /// 删除标签
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  /// 选择记忆日期
  Future<void> _selectMemoryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedMemoryDate ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedMemoryDate = date;
      });
    }
  }

  /// 保存记忆胶囊
  Future<void> _saveCapsule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.initialize();

      String? savedImagePath = _imagePath;
      String? savedAudioPath = _audioPath;

      // 如果是新图片，需要保存到永久存储
      if (_imagePath != null && !_imagePath!.contains('memory_capsules')) {
        savedImagePath = await _service.saveImageFile(_imagePath!);
      }

      // 如果是新音频，需要保存到永久存储
      if (_audioPath != null && !_audioPath!.contains('memory_capsules')) {
        savedAudioPath = await _service.saveAudioFile(_audioPath!);
      }

      final capsule = MemoryCapsule(
        id: widget.capsule?.id ?? 0,
        questionId: _relatedQuestionId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imagePath: savedImagePath,
        audioPath: savedAudioPath,
        createdAt: widget.capsule?.createdAt ?? DateTime.now(),
        memoryDate: _selectedMemoryDate,
        tags: _tags,
        era: _selectedEra,
        category: _selectedCategory,
        mood: _selectedMood,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      if (widget.capsule == null) {
        await _service.addCapsule(capsule);
      } else {
        await _service.updateCapsule(capsule);
      }

      if (mounted) {
        Navigator.pop(context, true); // 返回true表示保存成功
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.capsule == null ? '新建记忆胶囊' : '编辑记忆胶囊'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveCapsule,
              child: const Text('保存'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '记忆标题 *',
                hintText: '给这段记忆起个标题',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 内容
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '记忆内容 *',
                hintText: '记录你的回忆...',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入内容';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 年代选择
            DropdownButtonFormField<String>(
              value: _selectedEra,
              decoration: const InputDecoration(
                labelText: '年代',
                border: OutlineInputBorder(),
              ),
              items: _eras.map((era) {
                return DropdownMenuItem(value: era, child: Text(era));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedEra = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // 分类选择
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // 心情选择
            DropdownButtonFormField<String>(
              value: _selectedMood,
              decoration: const InputDecoration(
                labelText: '心情',
                border: OutlineInputBorder(),
              ),
              items: _moods.map((mood) {
                return DropdownMenuItem(value: mood, child: Text(mood));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMood = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // 记忆日期
            ListTile(
              title: const Text('记忆时间'),
              subtitle: Text(
                _selectedMemoryDate == null
                    ? '未设置'
                    : '${_selectedMemoryDate!.year}年${_selectedMemoryDate!.month}月${_selectedMemoryDate!.day}日',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectMemoryDate,
            ),
            const SizedBox(height: 16),

            // 位置
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '地点（可选）',
                hintText: '如：家乡、大学',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 标签
            TextFormField(
              controller: _tagController,
              decoration: InputDecoration(
                labelText: '标签',
                hintText: '输入标签后按回车添加',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ),
              onFieldSubmitted: (_) => _addTag(),
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // 图片
            if (_imagePath != null) ...[
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(_imagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _removeImage,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('选择图片'),
                    onPressed: _pickImage,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('拍照'),
                    onPressed: _takePhoto,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 音频
            if (_audioPath != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('已录制音频')),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _removeAudio,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            OutlinedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? '停止录音' : '开始录音'),
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: OutlinedButton.styleFrom(
                foregroundColor: _isRecording ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

