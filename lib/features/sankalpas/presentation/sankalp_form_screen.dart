import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../models/sankalp_template_model.dart';
import '../providers/sankalpas_provider.dart';

class SankalpFormScreen extends ConsumerStatefulWidget {
  final SankalpTemplate? template;

  const SankalpFormScreen({super.key, this.template});

  @override
  ConsumerState<SankalpFormScreen> createState() => _SankalpFormScreenState();
}

class _SankalpFormScreenState extends ConsumerState<SankalpFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _titleHindiController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _linkedContentTagController;
  late final TextEditingController _defaultTargetValueController;
  late final TextEditingController _defaultTargetUnitController;
  late final TextEditingController _notificationMessageController;
  late final TextEditingController _displayOrderController;

  late SankalpType _selectedType;
  late String? _selectedIcon;
  late bool _isSystemTemplate;
  bool _isLoading = false;

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    final template = widget.template;

    _titleController = TextEditingController(text: template?.title ?? '');
    _titleHindiController = TextEditingController(text: template?.titleHindi ?? '');
    _descriptionController = TextEditingController(text: template?.description ?? '');
    _linkedContentTagController = TextEditingController(text: template?.linkedContentTag ?? '');
    _defaultTargetValueController = TextEditingController(text: template?.defaultTargetValue?.toString() ?? '');
    _defaultTargetUnitController = TextEditingController(text: template?.defaultTargetUnit ?? '');
    _notificationMessageController = TextEditingController(text: template?.defaultNotificationMessage ?? '');
    _displayOrderController = TextEditingController(text: template?.displayOrder.toString() ?? '0');

    _selectedType = template?.sankalpType ?? SankalpType.BOOLEAN;
    _selectedIcon = template?.icon;
    _isSystemTemplate = template?.isSystemTemplate ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleHindiController.dispose();
    _descriptionController.dispose();
    _linkedContentTagController.dispose();
    _defaultTargetValueController.dispose();
    _defaultTargetUnitController.dispose();
    _notificationMessageController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Sankalp Template' : 'Create Sankalp Template'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(onPressed: _saveTemplate, icon: const Icon(Icons.save), label: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Basic Information', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 24),
                      // Title (English)
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title (English) *',
                          hintText: 'Enter sankalp title in English',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Title (Hindi)
                      TextFormField(
                        controller: _titleHindiController,
                        decoration: const InputDecoration(
                          labelText: 'Title (Hindi)',
                          hintText: 'Enter sankalp title in Hindi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Sankalp Type
                      DropdownButtonFormField<SankalpType>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(labelText: 'Sankalp Type *', border: OutlineInputBorder()),
                        items: SankalpType.values.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type.displayName));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Target Configuration Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Configuration', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          // Default Target Value
                          Expanded(
                            child: TextFormField(
                              controller: _defaultTargetValueController,
                              decoration: const InputDecoration(
                                labelText: 'Default Target Value',
                                hintText: 'e.g., 120',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Default Target Unit
                          Expanded(
                            child: TextFormField(
                              controller: _defaultTargetUnitController,
                              decoration: const InputDecoration(
                                labelText: 'Default Target Unit',
                                hintText: 'e.g., minutes, pages',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Linked Content Tag
                      TextFormField(
                        controller: _linkedContentTagController,
                        decoration: const InputDecoration(
                          labelText: 'Linked Content Tag',
                          hintText: 'Tag to link related content',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Display Settings Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Display Settings', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          // Display Order
                          Expanded(
                            child: TextFormField(
                              controller: _displayOrderController,
                              decoration: const InputDecoration(
                                labelText: 'Display Order',
                                hintText: '0',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Icon Picker
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedIcon,
                              decoration: const InputDecoration(labelText: 'Icon', border: OutlineInputBorder()),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('No Icon')),
                                ...SankalpIcons.icons.map((icon) {
                                  return DropdownMenuItem(
                                    value: icon,
                                    child: Row(
                                      children: [
                                        Icon(_getIconData(icon), size: 20),
                                        const SizedBox(width: 8),
                                        Text(SankalpIcons.getDisplayName(icon)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedIcon = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // System Template Switch
                      SwitchListTile(
                        title: const Text('System Template'),
                        subtitle: const Text('System templates are pre-defined and shown to all users'),
                        value: _isSystemTemplate,
                        onChanged: (value) {
                          setState(() {
                            _isSystemTemplate = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Notification Settings Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notification Settings', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _notificationMessageController,
                        decoration: const InputDecoration(
                          labelText: 'Default Notification Message',
                          hintText: 'Reminder message for users',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'self_improvement':
        return Icons.self_improvement;
      case 'spa':
        return Icons.spa;
      case 'favorite':
        return Icons.favorite;
      case 'psychology':
        return Icons.psychology;
      case 'emoji_objects':
        return Icons.emoji_objects;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'brightness_7':
        return Icons.brightness_7;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'nights_stay':
        return Icons.nights_stay;
      case 'timer':
        return Icons.timer;
      case 'schedule':
        return Icons.schedule;
      case 'event':
        return Icons.event;
      case 'flag':
        return Icons.flag;
      case 'star':
        return Icons.star;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'bookmark':
        return Icons.bookmark;
      case 'check_circle':
        return Icons.check_circle;
      case 'celebration':
        return Icons.celebration;
      case 'music_note':
        return Icons.music_note;
      case 'headphones':
        return Icons.headphones;
      case 'menu_book':
        return Icons.menu_book;
      case 'library_books':
        return Icons.library_books;
      case 'edit_note':
        return Icons.edit_note;
      case 'draw':
        return Icons.draw;
      default:
        return Icons.circle;
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final template = SankalpTemplate(
        id: widget.template?.id,
        title: _titleController.text.trim(),
        titleHindi: _titleHindiController.text.trim().isEmpty ? null : _titleHindiController.text.trim(),
        sankalpType: _selectedType,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        linkedContentTag: _linkedContentTagController.text.trim().isEmpty
            ? null
            : _linkedContentTagController.text.trim(),
        defaultTargetValue: int.tryParse(_defaultTargetValueController.text),
        defaultTargetUnit: _defaultTargetUnitController.text.trim().isEmpty
            ? null
            : _defaultTargetUnitController.text.trim(),
        defaultNotificationMessage: _notificationMessageController.text.trim().isEmpty
            ? null
            : _notificationMessageController.text.trim(),
        icon: _selectedIcon,
        isSystemTemplate: _isSystemTemplate,
        displayOrder: int.tryParse(_displayOrderController.text) ?? 0,
      );

      if (_isEditing) {
        await ref.read(sankalpTemplateActionsProvider.notifier).updateTemplate(widget.template!.id!, template);
      } else {
        await ref.read(sankalpTemplateActionsProvider.notifier).createTemplate(template);
      }

      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        _isEditing ? 'Template updated successfully' : 'Template created successfully',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to save template: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
