import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_models.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../providers/playlists_provider.dart';

class PlaylistFormScreen extends ConsumerStatefulWidget {
  final Playlist? playlist;

  const PlaylistFormScreen({super.key, this.playlist});

  @override
  ConsumerState<PlaylistFormScreen> createState() => _PlaylistFormScreenState();
}

class _PlaylistFormScreenState extends ConsumerState<PlaylistFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  String _contentType = 'VIDEO';
  String _playlistType = 'SYSTEM';
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist?.name);
    _descriptionController = TextEditingController(text: widget.playlist?.description);

    if (widget.playlist != null) {
      _contentType = widget.playlist!.contentType;
      _isPublic = widget.playlist!.isPublic;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.playlist != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Playlist' : 'Create Playlist'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basic Information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Playlist Name *',
                        hintText: 'Enter playlist name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Playlist name is required';
                        }
                        if (value.length > 255) {
                          return 'Name must not exceed 255 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter playlist description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 1000,
                    ),
                    const SizedBox(height: 16),

                    // Content Type Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _contentType,
                      decoration: const InputDecoration(labelText: 'Content Type *', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
                        DropdownMenuItem(value: 'AUDIO', child: Text('Audio')),
                      ],
                      onChanged: isEditing
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _contentType = value);
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Playlist Type Dropdown (only for create)
                    if (!isEditing) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _playlistType,
                        decoration: const InputDecoration(
                          labelText: 'Playlist Type *',
                          border: OutlineInputBorder(),
                          helperText: 'SYSTEM and SERIES are admin-managed playlists',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'SYSTEM', child: Text('System (Admin Curated)')),
                          DropdownMenuItem(value: 'SERIES', child: Text('Lecture Series')),
                          DropdownMenuItem(value: 'PUBLIC', child: Text('Public')),
                          DropdownMenuItem(value: 'USER', child: Text('User')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _playlistType = value;
                              // System and Series playlists are always public
                              if (value == 'SYSTEM' || value == 'SERIES') {
                                _isPublic = true;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Public Switch
                    SwitchListTile(
                      title: const Text('Public Playlist'),
                      subtitle: const Text('Make this playlist visible to all users'),
                      value: _isPublic,
                      onChanged: (_playlistType == 'SYSTEM' || _playlistType == 'SERIES')
                          ? null
                          : (value) => setState(() => _isPublic = value),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(isEditing ? 'Update Playlist' : 'Create Playlist'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.playlist != null) {
        // Update existing playlist
        await ref
            .read(playlistActionsProvider.notifier)
            .updatePlaylist(
              id: widget.playlist!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
              isPublic: _isPublic,
            );

        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Playlist updated successfully');
      } else {
        // Create new playlist
        await ref
            .read(playlistActionsProvider.notifier)
            .createPlaylist(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
              isPublic: _isPublic,
              contentType: _contentType,
              playlistType: _playlistType,
            );

        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Playlist created successfully');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to save playlist: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
