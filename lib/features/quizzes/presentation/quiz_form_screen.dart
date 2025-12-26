import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../models/quiz_model.dart';
import '../providers/quizzes_provider.dart';

/// Quiz form screen for creating and editing quizzes
class QuizFormScreen extends ConsumerStatefulWidget {
  final int? quizId;

  const QuizFormScreen({super.key, this.quizId});

  bool get isEditing => quizId != null;

  @override
  ConsumerState<QuizFormScreen> createState() => _QuizFormScreenState();
}

class _QuizFormScreenState extends ConsumerState<QuizFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  int? _contentId;
  final _contentIdController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _titleHiController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _descriptionHiController = TextEditingController();
  bool _isActive = true;

  // Questions
  List<QuizQuestion> _questions = [];

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _contentIdController.dispose();
    _titleEnController.dispose();
    _titleHiController.dispose();
    _descriptionEnController.dispose();
    _descriptionHiController.dispose();
    super.dispose();
  }

  void _initializeFromQuiz(QuizDetail quiz) {
    if (_isInitialized) return;
    _isInitialized = true;

    _contentId = quiz.contentId;
    _contentIdController.text = quiz.contentId.toString();
    _titleEnController.text = quiz.titleEn ?? '';
    _titleHiController.text = quiz.titleHi ?? '';
    _descriptionEnController.text = quiz.descriptionEn ?? '';
    _descriptionHiController.text = quiz.descriptionHi ?? '';
    _isActive = quiz.isActive;
    _questions = List.from(quiz.questions);
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    if (_contentId == null) {
      SnackBarHelper.showError(context, 'Please enter a valid Content ID');
      return;
    }

    if (_questions.isEmpty) {
      SnackBarHelper.showError(context, 'Please add at least one question');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final questionsData = _questions.map((q) => q.toJson()).toList();

      if (widget.isEditing) {
        await ref
            .read(quizActionsProvider.notifier)
            .updateQuiz(
              quizId: widget.quizId!,
              titleEn: _titleEnController.text.isEmpty ? null : _titleEnController.text,
              titleHi: _titleHiController.text.isEmpty ? null : _titleHiController.text,
              descriptionEn: _descriptionEnController.text.isEmpty ? null : _descriptionEnController.text,
              descriptionHi: _descriptionHiController.text.isEmpty ? null : _descriptionHiController.text,
              isActive: _isActive,
              questions: questionsData,
            );
      } else {
        await ref
            .read(quizActionsProvider.notifier)
            .createQuiz(
              contentId: _contentId!,
              titleEn: _titleEnController.text.isEmpty ? null : _titleEnController.text,
              titleHi: _titleHiController.text.isEmpty ? null : _titleHiController.text,
              descriptionEn: _descriptionEnController.text.isEmpty ? null : _descriptionEnController.text,
              descriptionHi: _descriptionHiController.text.isEmpty ? null : _descriptionHiController.text,
              isActive: _isActive,
              questions: questionsData,
            );
      }

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, widget.isEditing ? 'Quiz updated' : 'Quiz created');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to save quiz: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuizQuestion.empty(displayOrder: _questions.length));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      // Re-index display orders
      for (var i = 0; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(displayOrder: i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If editing, load the quiz details
    if (widget.isEditing) {
      final quizAsync = ref.watch(quizDetailProvider(widget.quizId!));

      return quizAsync.when(
        data: (quiz) {
          _initializeFromQuiz(quiz);
          return _buildForm(theme);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Loading...')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load quiz: $error'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go Back')),
              ],
            ),
          ),
        ),
      );
    }

    return _buildForm(theme);
  }

  Widget _buildForm(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Quiz' : 'Create Quiz'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(onPressed: _saveQuiz, icon: const Icon(Icons.save), label: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Content ID (only for new quizzes)
            if (!widget.isEditing) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Content Association', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Content ID *',
                          hintText: 'Enter the content ID to associate this quiz with',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Content ID is required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _contentId = int.tryParse(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quiz metadata
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz Information', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _titleEnController,
                            decoration: const InputDecoration(
                              labelText: 'Title (English)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _titleHiController,
                            decoration: const InputDecoration(labelText: 'Title (Hindi)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _descriptionEnController,
                            decoration: const InputDecoration(
                              labelText: 'Description (English)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _descriptionHiController,
                            decoration: const InputDecoration(
                              labelText: 'Description (Hindi)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Quiz is available to users'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Questions section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Questions (${_questions.length}/10)', style: theme.textTheme.titleMedium),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _questions.length >= 10
                                  ? null
                                  : () {
                                      setState(() {
                                        _questions.add(QuizQuestion.trueFalse(displayOrder: _questions.length));
                                      });
                                    },
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('True/False'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _questions.length >= 10 ? null : _addQuestion,
                              icon: const Icon(Icons.add),
                              label: const Text('Multiple Choice'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_questions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.help_outline, size: 48, color: theme.colorScheme.outline),
                              const SizedBox(height: 8),
                              Text(
                                'No questions yet. Add at least one question.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(_questions.length, (index) {
                        return _QuestionEditor(
                          key: ValueKey('question_$index'),
                          question: _questions[index],
                          index: index,
                          onChanged: (updatedQuestion) {
                            setState(() {
                              _questions[index] = updatedQuestion;
                            });
                          },
                          onRemove: () => _removeQuestion(index),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for editing a single question
class _QuestionEditor extends StatefulWidget {
  final QuizQuestion question;
  final int index;
  final ValueChanged<QuizQuestion> onChanged;
  final VoidCallback onRemove;

  const _QuestionEditor({
    super.key,
    required this.question,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  late TextEditingController _questionEnController;
  late TextEditingController _questionHiController;
  late TextEditingController _explanationEnController;
  late TextEditingController _explanationHiController;
  late List<TextEditingController> _optionEnControllers;
  late List<TextEditingController> _optionHiControllers;
  late QuestionType _questionType;
  late int _correctAnswerIndex;

  @override
  void initState() {
    super.initState();
    _questionEnController = TextEditingController(text: widget.question.questionTextEn);
    _questionHiController = TextEditingController(text: widget.question.questionTextHi);
    _explanationEnController = TextEditingController(text: widget.question.explanationEn);
    _explanationHiController = TextEditingController(text: widget.question.explanationHi);
    _questionType = widget.question.questionType;
    _correctAnswerIndex = widget.question.correctAnswerIndex;

    _optionEnControllers = widget.question.optionsEn.map((opt) => TextEditingController(text: opt)).toList();
    _optionHiControllers = widget.question.optionsHi.map((opt) => TextEditingController(text: opt)).toList();

    // Ensure at least 4 options for multiple choice
    while (_optionEnControllers.length < 4 && _questionType == QuestionType.MULTIPLE_CHOICE) {
      _optionEnControllers.add(TextEditingController());
      _optionHiControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _questionEnController.dispose();
    _questionHiController.dispose();
    _explanationEnController.dispose();
    _explanationHiController.dispose();
    for (final c in _optionEnControllers) {
      c.dispose();
    }
    for (final c in _optionHiControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateQuestion() {
    widget.onChanged(
      widget.question.copyWith(
        questionTextEn: _questionEnController.text.isEmpty ? null : _questionEnController.text,
        questionTextHi: _questionHiController.text.isEmpty ? null : _questionHiController.text,
        questionType: _questionType,
        optionsEn: _optionEnControllers.map((c) => c.text).toList(),
        optionsHi: _optionHiControllers.map((c) => c.text).toList(),
        correctAnswerIndex: _correctAnswerIndex,
        explanationEn: _explanationEnController.text.isEmpty ? null : _explanationEnController.text,
        explanationHi: _explanationHiController.text.isEmpty ? null : _explanationHiController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with question number and delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 14, child: Text('${widget.index + 1}', style: const TextStyle(fontSize: 12))),
                    const SizedBox(width: 8),
                    Text(_questionType.displayName, style: theme.textTheme.titleSmall),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove question',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question text
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _questionEnController,
                    decoration: const InputDecoration(labelText: 'Question (English)', border: OutlineInputBorder()),
                    maxLines: 2,
                    onChanged: (_) => _updateQuestion(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _questionHiController,
                    decoration: const InputDecoration(labelText: 'Question (Hindi)', border: OutlineInputBorder()),
                    maxLines: 2,
                    onChanged: (_) => _updateQuestion(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options
            Text('Options', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...List.generate(_optionEnControllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Use IconButton instead of deprecated Radio
                    IconButton(
                      icon: Icon(
                        _correctAnswerIndex == i ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: _correctAnswerIndex == i ? theme.colorScheme.primary : null,
                      ),
                      onPressed: () {
                        setState(() => _correctAnswerIndex = i);
                        _updateQuestion();
                      },
                      tooltip: 'Mark as correct answer',
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _optionEnControllers[i],
                        decoration: InputDecoration(
                          labelText: 'Option ${i + 1} (EN)',
                          border: const OutlineInputBorder(),
                          suffixIcon: _correctAnswerIndex == i
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                        onChanged: (_) => _updateQuestion(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _optionHiControllers[i],
                        decoration: InputDecoration(
                          labelText: 'Option ${i + 1} (HI)',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => _updateQuestion(),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Explanation (optional)
            ExpansionTile(
              title: const Text('Explanation (Optional)'),
              tilePadding: EdgeInsets.zero,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _explanationEnController,
                        decoration: const InputDecoration(
                          labelText: 'Explanation (English)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onChanged: (_) => _updateQuestion(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _explanationHiController,
                        decoration: const InputDecoration(
                          labelText: 'Explanation (Hindi)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onChanged: (_) => _updateQuestion(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
