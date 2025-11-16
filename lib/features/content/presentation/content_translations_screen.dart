import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../models/content_model.dart';
import '../models/content_translation_model.dart';
import '../providers/content_translations_provider.dart';

class ContentTranslationsScreen extends ConsumerStatefulWidget {
  final ContentItem content;

  const ContentTranslationsScreen({super.key, required this.content});

  @override
  ConsumerState<ContentTranslationsScreen> createState() => _ContentTranslationsScreenState();
}

class _ContentTranslationsScreenState extends ConsumerState<ContentTranslationsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isSubmitting = false;

  // English translation controllers
  late TextEditingController _englishTitleController;
  late TextEditingController _englishDescriptionController;

  // Hindi translation controllers
  late TextEditingController _hindiTitleController;
  late TextEditingController _hindiDescriptionController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize English controllers
    _englishTitleController = TextEditingController();
    _englishDescriptionController = TextEditingController();

    // Initialize Hindi controllers
    _hindiTitleController = TextEditingController();
    _hindiDescriptionController = TextEditingController();

    // Load existing translations from backend
    _loadTranslations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _englishTitleController.dispose();
    _englishDescriptionController.dispose();
    _hindiTitleController.dispose();
    _hindiDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTranslations() async {
    // Fetch translations from backend API
    try {
      final translations = await ref.read(contentTranslationsListProvider(widget.content.id).future);

      for (final translation in translations) {
        if (translation.languageCode == 'en') {
          _englishTitleController.text = translation.title;
          _englishDescriptionController.text = translation.description ?? '';
        } else if (translation.languageCode == 'hi') {
          _hindiTitleController.text = translation.title;
          _hindiDescriptionController.text = translation.description ?? '';
        }
      }
    } catch (e) {
      // If no translations exist yet, that's OK - user will create them
      debugPrint('No existing translations found: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Translations - ${widget.content.title ?? 'Content ${widget.content.id}'}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.language), text: 'English'),
            Tab(icon: Icon(Icons.translate), text: 'हिन्दी (Hindi)'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // English Translation Tab
            _buildTranslationForm(
              language: 'English',
              languageCode: 'en',
              titleController: _englishTitleController,
              descriptionController: _englishDescriptionController,
              useDevanagari: false,
            ),
            // Hindi Translation Tab
            _buildTranslationForm(
              language: 'हिन्दी',
              languageCode: 'hi',
              titleController: _hindiTitleController,
              descriptionController: _hindiDescriptionController,
              useDevanagari: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _saveTranslations,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Translations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationForm({
    required String language,
    required String languageCode,
    required TextEditingController titleController,
    required TextEditingController descriptionController,
    required bool useDevanagari,
  }) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  languageCode == 'hi' ? Icons.language : Icons.abc,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  '$language Translation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title field
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.title, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Title', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter title in $language',
                      border: const OutlineInputBorder(),
                      filled: true,
                    ),
                    style: useDevanagari ? GoogleFonts.notoSansDevanagari(fontSize: 16) : null,
                    maxLength: 500,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Title is required for $language';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description field
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Description', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Enter detailed description in $language',
                      border: const OutlineInputBorder(),
                      filled: true,
                      helperText: 'Provide a comprehensive description of the content',
                    ),
                    style: useDevanagari ? GoogleFonts.notoSansDevanagari(fontSize: 16) : null,
                    maxLines: 8,
                    maxLength: 2000,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Translation tips
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Translation Tips', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (languageCode == 'hi')
                    Text(
                      '• Use Devanagari script (हिन्दी)\n'
                      '• Ensure proper Unicode encoding\n'
                      '• Include diacritical marks (matras)\n'
                      '• Maintain spiritual terminology accuracy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    )
                  else
                    Text(
                      '• Use clear, concise English\n'
                      '• Include relevant keywords for search\n'
                      '• Maintain spiritual context\n'
                      '• Proofread for grammar and spelling',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTranslations() async {
    if (!_formKey.currentState!.validate()) {
      // Switch to the tab with validation errors
      if (_englishTitleController.text.trim().isEmpty) {
        _tabController.animateTo(0);
      } else if (_hindiTitleController.text.trim().isEmpty) {
        _tabController.animateTo(1);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Build translations list
      final translations = <ContentTranslation>[
        ContentTranslation(
          contentId: widget.content.id,
          languageCode: 'en',
          title: _englishTitleController.text.trim(),
          description: _englishDescriptionController.text.trim().isEmpty
              ? null
              : _englishDescriptionController.text.trim(),
        ),
        ContentTranslation(
          contentId: widget.content.id,
          languageCode: 'hi',
          title: _hindiTitleController.text.trim(),
          description: _hindiDescriptionController.text.trim().isEmpty ? null : _hindiDescriptionController.text.trim(),
        ),
      ];

      // Save translations to backend
      await ref.read(contentTranslationsActionsProvider.notifier).saveTranslations(widget.content.id, translations);

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Translations saved successfully');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to save translations: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
