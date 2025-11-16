import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../models/content_model.dart';
import '../providers/content_provider.dart';
import 'content_translations_screen.dart';

class ContentFormScreen extends ConsumerStatefulWidget {
  final ContentItem? content;

  const ContentFormScreen({super.key, this.content});

  @override
  ConsumerState<ContentFormScreen> createState() => _ContentFormScreenState();
}

class _ContentFormScreenState extends ConsumerState<ContentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditing;

  // Form controllers
  late TextEditingController _externalContentIdController;
  late TextEditingController _thumbnailUrlController;
  late TextEditingController _durationController;
  late TextEditingController _recordingLocationController;
  late TextEditingController _tagsController;
  late TextEditingController _audioStreamUrlController;
  late TextEditingController _audioFileUrlController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;

  // Form state
  ContentType _contentType = ContentType.VIDEO;
  ContentStatus _status = ContentStatus.PROCESSING;
  bool _isPremium = false;
  DateTime? _recordingDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.content != null;

    // Initialize controllers
    _externalContentIdController = TextEditingController(text: widget.content?.externalContentId ?? '');
    _thumbnailUrlController = TextEditingController(text: widget.content?.thumbnailUrl ?? '');
    _durationController = TextEditingController(text: widget.content?.durationSeconds?.toString() ?? '');
    _recordingLocationController = TextEditingController(text: widget.content?.recordingLocation ?? '');
    _tagsController = TextEditingController(text: widget.content?.tags?.join(', ') ?? '');
    _audioStreamUrlController = TextEditingController(text: widget.content?.audioStreamUrl ?? '');
    _audioFileUrlController = TextEditingController(text: widget.content?.audioFileUrl ?? '');
    _artistController = TextEditingController(text: widget.content?.artist ?? '');
    _albumController = TextEditingController(text: widget.content?.album ?? '');

    // Initialize form state
    if (widget.content != null) {
      _contentType = widget.content!.contentType;
      _status = widget.content!.status;
      _isPremium = widget.content!.isPremium;
      _recordingDate = widget.content!.recordingDate;
    }
  }

  @override
  void dispose() {
    _externalContentIdController.dispose();
    _thumbnailUrlController.dispose();
    _durationController.dispose();
    _recordingLocationController.dispose();
    _tagsController.dispose();
    _audioStreamUrlController.dispose();
    _audioFileUrlController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Content' : 'Create Content'),
        actions: [
          if (_isEditing) ...[
            IconButton(icon: const Icon(Icons.lyrics), onPressed: _manageLyrics, tooltip: 'Manage Lyrics'),
            IconButton(
              icon: const Icon(Icons.translate),
              onPressed: _manageTranslations,
              tooltip: 'Manage Translations',
            ),
            IconButton(icon: const Icon(Icons.category), onPressed: _manageCategories, tooltip: 'Manage Categories'),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basic Information', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),

                    // Translation info card
                    if (_isEditing)
                      Card(
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.translate, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Title and description are managed via the Translations button above',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_isEditing) const SizedBox(height: 16),

                    // Content Type and Status
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ContentType>(
                            initialValue: _contentType,
                            decoration: const InputDecoration(labelText: 'Content Type', border: OutlineInputBorder()),
                            items: ContentType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(type == ContentType.VIDEO ? Icons.videocam : Icons.music_note, size: 20),
                                    const SizedBox(width: 8),
                                    Text(type.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _contentType = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<ContentStatus>(
                            initialValue: _status,
                            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                            items: ContentStatus.values.map((status) {
                              return DropdownMenuItem(value: status, child: Text(status.name));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Premium checkbox
                    CheckboxListTile(
                      value: _isPremium,
                      onChanged: (value) => setState(() => _isPremium = value ?? false),
                      title: const Text('Premium Content'),
                      subtitle: const Text('Requires subscription to access'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Media Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Media Details', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),

                    // External Content ID (vdoCipher, YouTube, etc.)
                    TextFormField(
                      controller: _externalContentIdController,
                      decoration: const InputDecoration(
                        labelText: 'External Content ID',
                        hintText: 'vdoCipher video ID or external reference',
                        border: OutlineInputBorder(),
                        helperText: 'Video ID from vdoCipher or other platforms',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thumbnail URL
                    TextFormField(
                      controller: _thumbnailUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Thumbnail URL',
                        hintText: 'https://example.com/thumbnail.jpg',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isNotEmpty == true && !Uri.tryParse(value!)!.isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Duration
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (seconds)',
                        hintText: 'Total duration in seconds',
                        border: OutlineInputBorder(),
                        suffixText: 'seconds',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isNotEmpty == true && int.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Audio-specific fields (show only for AUDIO type)
            if (_contentType == ContentType.AUDIO) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audio Details', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),

                      // Artist
                      TextFormField(
                        controller: _artistController,
                        decoration: const InputDecoration(
                          labelText: 'Artist',
                          hintText: 'Singer or performer name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Album
                      TextFormField(
                        controller: _albumController,
                        decoration: const InputDecoration(
                          labelText: 'Album',
                          hintText: 'Album or collection name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Audio Stream URL
                      TextFormField(
                        controller: _audioStreamUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Audio Stream URL',
                          hintText: 'URL for streaming audio',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Audio File URL
                      TextFormField(
                        controller: _audioFileUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Audio File URL',
                          hintText: 'Direct download URL (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Additional Metadata Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Additional Information', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),

                    // Recording Date
                    ListTile(
                      title: const Text('Recording Date'),
                      subtitle: Text(_recordingDate?.toString().split(' ')[0] ?? 'Not set'),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _recordingDate ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _recordingDate = date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recording Location
                    TextFormField(
                      controller: _recordingLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Recording Location',
                        hintText: 'e.g., Vrindavan, India',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Comma-separated tags',
                        border: OutlineInputBorder(),
                        helperText: 'e.g., bhajan, kirtan, devotional',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveContent,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEditing ? 'Update Content' : 'Create Content'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Parse tags
      final tags = _tagsController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

      final contentData = ContentItem(
        id: widget.content?.id ?? 0,
        contentType: _contentType,
        status: _status,
        isPremium: _isPremium,
        externalContentId: _externalContentIdController.text.isEmpty ? null : _externalContentIdController.text,
        thumbnailUrl: _thumbnailUrlController.text.isEmpty ? null : _thumbnailUrlController.text,
        durationSeconds: _durationController.text.isEmpty ? null : int.tryParse(_durationController.text),
        recordingDate: _recordingDate,
        recordingLocation: _recordingLocationController.text.isEmpty ? null : _recordingLocationController.text,
        tags: tags.isEmpty ? null : tags,
        audioStreamUrl: _audioStreamUrlController.text.isEmpty ? null : _audioStreamUrlController.text,
        audioFileUrl: _audioFileUrlController.text.isEmpty ? null : _audioFileUrlController.text,
        artist: _artistController.text.isEmpty ? null : _artistController.text,
        album: _albumController.text.isEmpty ? null : _albumController.text,
        viewCount: widget.content?.viewCount ?? 0,
        createdAt: widget.content?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await ref.read(contentActionsProvider.notifier).updateContent(widget.content!.id, contentData);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Content updated successfully');
      } else {
        await ref.read(contentActionsProvider.notifier).createContent(contentData);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Content created successfully');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to save content: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _manageLyrics() {
    if (widget.content == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Manage Lyrics')),
          body: Center(child: Text('Lyrics editor for content ID: ${widget.content!.id}\n\nComing soon!')),
        ),
      ),
    );
  }

  void _manageTranslations() {
    if (widget.content == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContentTranslationsScreen(content: widget.content!)),
    );
  }

  void _manageCategories() {
    if (widget.content == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Manage Categories')),
          body: Center(child: Text('Category manager for content ID: ${widget.content!.id}\n\nComing soon!')),
        ),
      ),
    );
  }
}
