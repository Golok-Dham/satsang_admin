import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_models.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../providers/quotes_provider.dart';

class QuoteFormScreen extends ConsumerStatefulWidget {
  final DivineQuote? quote;

  const QuoteFormScreen({super.key, this.quote});

  @override
  ConsumerState<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends ConsumerState<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form controllers
  late final TextEditingController _devanagariController;
  late final TextEditingController _transliterationController;
  late final TextEditingController _hindiMeaningController;
  late final TextEditingController _englishMeaningController;
  late final TextEditingController _sourceBookController;
  late final TextEditingController _sourceBookHindiController;
  late final TextEditingController _chapterRefController;
  late final TextEditingController _verseNumberController;
  late final TextEditingController _pageNumberController;

  late QuoteCategory _selectedCategory;
  late QuoteMood _selectedMood;
  late bool _isActive;
  late int _displayPriority;

  @override
  void initState() {
    super.initState();
    final quote = widget.quote;

    _devanagariController = TextEditingController(text: quote?.textDevanagari ?? '');
    _transliterationController = TextEditingController(text: quote?.textTransliteration ?? '');
    _hindiMeaningController = TextEditingController(text: quote?.textHindiMeaning ?? '');
    _englishMeaningController = TextEditingController(text: quote?.textEnglishMeaning ?? '');
    _sourceBookController = TextEditingController(text: quote?.sourceBook ?? '');
    _sourceBookHindiController = TextEditingController(text: quote?.sourceBookHindi ?? '');
    _chapterRefController = TextEditingController(text: quote?.chapterReference ?? '');
    _verseNumberController = TextEditingController(text: quote?.verseNumber ?? '');
    _pageNumberController = TextEditingController(text: quote?.pageNumber ?? '');

    _selectedCategory = quote?.category ?? QuoteCategory.GENERAL;
    _selectedMood = quote?.mood ?? QuoteMood.NEUTRAL;
    _isActive = quote?.isActive ?? true;
    _displayPriority = quote?.displayPriority ?? 0;
  }

  @override
  void dispose() {
    _devanagariController.dispose();
    _transliterationController.dispose();
    _hindiMeaningController.dispose();
    _englishMeaningController.dispose();
    _sourceBookController.dispose();
    _sourceBookHindiController.dispose();
    _chapterRefController.dispose();
    _verseNumberController.dispose();
    _pageNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.quote != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Quote' : 'Create Quote'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Devanagari text
              TextFormField(
                controller: _devanagariController,
                decoration: const InputDecoration(
                  labelText: 'Text (Devanagari)',
                  border: OutlineInputBorder(),
                  helperText: 'Original text in Devanagari script',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Devanagari text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Transliteration
              TextFormField(
                controller: _transliterationController,
                decoration: const InputDecoration(
                  labelText: 'Transliteration',
                  border: OutlineInputBorder(),
                  helperText: 'Roman script transliteration',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Hindi meaning
              TextFormField(
                controller: _hindiMeaningController,
                decoration: const InputDecoration(
                  labelText: 'Hindi Meaning',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // English meaning
              TextFormField(
                controller: _englishMeaningController,
                decoration: const InputDecoration(
                  labelText: 'English Meaning',
                  border: OutlineInputBorder(),
                  helperText: 'Required',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter English meaning';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Source book (English)
              TextFormField(
                controller: _sourceBookController,
                decoration: const InputDecoration(
                  labelText: 'Source Book',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., Bhagavad Gita',
                ),
              ),
              const SizedBox(height: 16),

              // Source book (Hindi)
              TextFormField(
                controller: _sourceBookHindiController,
                decoration: const InputDecoration(
                  labelText: 'Source Book (Hindi)',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., श्रीमद्भगवद्गीता',
                ),
              ),
              const SizedBox(height: 16),

              // Reference fields row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _chapterRefController,
                      decoration: const InputDecoration(
                        labelText: 'Chapter',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _verseNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Verse',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pageNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Page',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category and Mood dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<QuoteCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: QuoteCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<QuoteMood>(
                      value: _selectedMood,
                      decoration: const InputDecoration(
                        labelText: 'Mood',
                        border: OutlineInputBorder(),
                      ),
                      items: QuoteMood.values.map((mood) {
                        return DropdownMenuItem(
                          value: mood,
                          child: Text(mood.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMood = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Display priority slider
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Display Priority: $_displayPriority',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _displayPriority.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: _displayPriority.toString(),
                        onChanged: (value) {
                          setState(() => _displayPriority = value.toInt());
                        },
                      ),
                      Text(
                        'Higher priority quotes appear more frequently',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active status switch
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Quote will be shown to users'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Quote' : 'Create Quote'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final quote = DivineQuote(
        id: widget.quote?.id ?? 0,
        textDevanagari: _devanagariController.text,
        textTransliteration: _transliterationController.text.isEmpty
            ? null
            : _transliterationController.text,
        textHindiMeaning: _hindiMeaningController.text.isEmpty
            ? null
            : _hindiMeaningController.text,
        textEnglishMeaning: _englishMeaningController.text,
        sourceBook: _sourceBookController.text.isEmpty
            ? null
            : _sourceBookController.text,
        sourceBookHindi: _sourceBookHindiController.text.isEmpty
            ? null
            : _sourceBookHindiController.text,
        chapterReference: _chapterRefController.text.isEmpty
            ? null
            : _chapterRefController.text,
        verseNumber: _verseNumberController.text.isEmpty
            ? null
            : _verseNumberController.text,
        pageNumber: _pageNumberController.text.isEmpty
            ? null
            : _pageNumberController.text,
        category: _selectedCategory,
        mood: _selectedMood,
        isActive: _isActive,
        displayPriority: _displayPriority,
        createdAt: widget.quote?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.quote == null) {
        // Create new quote
        await ref.read(quoteActionsProvider.notifier).createQuote(quote);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Quote created successfully');
      } else {
        // Update existing quote
        await ref.read(quoteActionsProvider.notifier).updateQuote(
              widget.quote!.id,
              quote,
            );
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Quote updated successfully');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to save quote: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
