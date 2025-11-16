import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../models/content_lyrics_model.dart';
import '../models/content_model.dart';
import '../models/karaoke_line_model.dart';
import '../providers/content_lyrics_provider.dart';

/// Screen for editing content lyrics with multiple editing modes.
class ContentLyricsScreen extends ConsumerStatefulWidget {
  const ContentLyricsScreen({super.key, required this.content});

  final ContentItem content;

  @override
  ConsumerState<ContentLyricsScreen> createState() => _ContentLyricsScreenState();
}

class _ContentLyricsScreenState extends ConsumerState<ContentLyricsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Text controllers
  late final TextEditingController _hindiLyricsController;
  late final TextEditingController _englishLyricsController;
  late final TextEditingController _hindiMeaningController;
  late final TextEditingController _englishMeaningController;
  late final TextEditingController _karaokeJsonController;

  // Karaoke editor state
  KaraokeData? _karaokeData;
  bool _hasKaraokeChanges = false;
  bool _hasTextChanges = false;
  bool _isSyncingFromEditor = false;
  bool _isHydratingForm = false;
  bool _canPopOverride = false;

  // Loading state
  bool _isSaving = false;
  bool _isLoadingInitial = true;

  ContentLyrics? _currentLyrics;

  bool get _hasUnsavedChanges => _hasTextChanges || _hasKaraokeChanges;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _hindiLyricsController = TextEditingController();
    _englishLyricsController = TextEditingController();
    _hindiMeaningController = TextEditingController();
    _englishMeaningController = TextEditingController();
    _karaokeJsonController = TextEditingController();

    _hindiLyricsController.addListener(_markTextChanged);
    _englishLyricsController.addListener(_markTextChanged);
    _hindiMeaningController.addListener(_markTextChanged);
    _englishMeaningController.addListener(_markTextChanged);
    _karaokeJsonController.addListener(_handleJsonChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialLyrics();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hindiLyricsController
      ..removeListener(_markTextChanged)
      ..dispose();
    _englishLyricsController
      ..removeListener(_markTextChanged)
      ..dispose();
    _hindiMeaningController
      ..removeListener(_markTextChanged)
      ..dispose();
    _englishMeaningController
      ..removeListener(_markTextChanged)
      ..dispose();
    _karaokeJsonController
      ..removeListener(_handleJsonChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allowSystemPop = !_hasUnsavedChanges || _canPopOverride;

    return PopScope(
      canPop: allowSystemPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldClose = await _onWillPop();
        if (shouldClose && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop(result);
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Lyrics - ${widget.content.title ?? "Content #${widget.content.id}"}'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Lyrics', icon: Icon(Icons.lyrics)),
              Tab(text: 'Meanings', icon: Icon(Icons.lightbulb_outline)),
              Tab(text: 'Karaoke JSON', icon: Icon(Icons.code)),
              Tab(text: 'Karaoke Editor', icon: Icon(Icons.grid_on)),
            ],
          ),
          actions: [
            if (_isSaving || _isLoadingInitial)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              IconButton(icon: const Icon(Icons.save), tooltip: 'Save Lyrics', onPressed: _saveLyrics),
          ],
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildLyricsTab(), _buildMeaningsTab(), _buildKaraokeTab(), _buildKaraokeEditorTab()],
            ),
            if (_isLoadingInitial)
              Positioned.fill(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_isSaving) {
      if (mounted) {
        SnackBarHelper.showInfo(context, 'Please wait for the save to finish');
      }
      return false;
    }

    if (!_hasUnsavedChanges) {
      if (mounted) {
        setState(() => _canPopOverride = true);
      }
      return true;
    }

    final action = await _showUnsavedChangesDialog();
    if (action == _UnsavedChangesAction.discard) {
      if (mounted) {
        setState(() => _canPopOverride = true);
      }
      return true;
    }

    if (action == _UnsavedChangesAction.save) {
      await _saveLyrics();
      if (!_hasUnsavedChanges && mounted) {
        setState(() => _canPopOverride = true);
        return true;
      }
      return !_hasUnsavedChanges;
    }

    return false;
  }

  Future<_UnsavedChangesAction?> _showUnsavedChangesDialog() {
    return showDialog<_UnsavedChangesAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('You have unsaved lyrics edits. Save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_UnsavedChangesAction.cancel),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_UnsavedChangesAction.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_UnsavedChangesAction.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hindi Lyrics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _hindiLyricsController,
            maxLines: 10,
            style: GoogleFonts.notoSansDevanagari(),
            decoration: InputDecoration(
              hintText: 'Enter Hindi lyrics here...',
              hintStyle: GoogleFonts.notoSansDevanagari(),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('English Lyrics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _englishLyricsController,
            maxLines: 10,
            decoration: const InputDecoration(hintText: 'Enter English lyrics here...', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildMeaningsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hindi Meaning', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _hindiMeaningController,
            maxLines: 10,
            style: GoogleFonts.notoSansDevanagari(),
            decoration: InputDecoration(
              hintText: 'Enter Hindi meaning/interpretation here...',
              hintStyle: GoogleFonts.notoSansDevanagari(),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('English Meaning', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _englishMeaningController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Enter English meaning/interpretation here...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaraokeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Karaoke JSON', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton.icon(
                onPressed: _formatJson,
                icon: const Icon(Icons.format_align_left),
                label: const Text('Format'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _validateJson,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Validate'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _karaokeJsonController,
              maxLines: null,
              expands: true,
              style: GoogleFonts.sourceCodePro(fontSize: 13),
              decoration: const InputDecoration(
                hintText: '{\n  "lines": [...],\n  "metadata": {...}\n}',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaraokeEditorTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _parseJsonToEditor,
                icon: const Icon(Icons.refresh),
                label: const Text('Load from JSON'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: _addNewLine, icon: const Icon(Icons.add), label: const Text('Add Line')),
              const Spacer(),
              if (_hasKaraokeChanges)
                Chip(
                  avatar: Icon(Icons.circle, size: 12, color: Theme.of(context).colorScheme.error),
                  label: const Text('Unsaved changes'),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
            ],
          ),
        ),
        Expanded(child: _karaokeData == null ? _buildEmptyState() : _buildKaraokeTable()),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No karaoke data loaded',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Load from JSON" to parse the JSON tab',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildKaraokeTable() {
    if (_karaokeData == null || _karaokeData!.lines.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Start (s)')),
            DataColumn(label: Text('End (s)')),
            DataColumn(label: Text('Hindi')),
            DataColumn(label: Text('English')),
            DataColumn(label: Text('Hindi Meaning')),
            DataColumn(label: Text('English Meaning')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _karaokeData!.lines.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            return DataRow(
              cells: [
                DataCell(Text('${line.index}')),
                DataCell(
                  InkWell(
                    onTap: () => _updateLineStartTime(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Text(line.startTime.toStringAsFixed(2), style: GoogleFonts.sourceCodePro()),
                    ),
                  ),
                ),
                DataCell(
                  InkWell(
                    onTap: () => _updateLineEndTime(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Text(line.endTime.toStringAsFixed(2), style: GoogleFonts.sourceCodePro()),
                    ),
                  ),
                ),
                DataCell(
                  InkWell(
                    onTap: () => _updateLineHindi(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Text(
                        line.hindi.isEmpty ? '(empty)' : line.hindi,
                        style: line.hindi.isEmpty
                            ? TextStyle(color: Theme.of(context).colorScheme.outline, fontStyle: FontStyle.italic)
                            : GoogleFonts.notoSansDevanagari(),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  InkWell(
                    onTap: () => _updateLineEnglish(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Text(
                        line.english.isEmpty ? '(empty)' : line.english,
                        style: line.english.isEmpty
                            ? TextStyle(color: Theme.of(context).colorScheme.outline, fontStyle: FontStyle.italic)
                            : null,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  InkWell(
                    onTap: () => _updateLineHindiMeaning(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Text(
                        line.hindiMeaning.isEmpty ? '(empty)' : line.hindiMeaning,
                        style: line.hindiMeaning.isEmpty
                            ? TextStyle(color: Theme.of(context).colorScheme.outline, fontStyle: FontStyle.italic)
                            : GoogleFonts.notoSansDevanagari(),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  InkWell(
                    onTap: () => _updateLineEnglishMeaning(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Text(
                        line.englishMeaning.isEmpty ? '(empty)' : line.englishMeaning,
                        style: line.englishMeaning.isEmpty
                            ? TextStyle(color: Theme.of(context).colorScheme.outline, fontStyle: FontStyle.italic)
                            : null,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        iconSize: 18,
                        tooltip: 'Move Up',
                        onPressed: index > 0 ? () => _moveLineUp(index) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        iconSize: 18,
                        tooltip: 'Move Down',
                        onPressed: index < _karaokeData!.lines.length - 1 ? () => _moveLineDown(index) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        iconSize: 18,
                        tooltip: 'Delete',
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => _deleteLine(index),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _markTextChanged() {
    if (_isHydratingForm) {
      return;
    }
    if (!_hasTextChanges) {
      setState(() => _hasTextChanges = true);
    }
  }

  void _handleJsonChanged() {
    if (_isSyncingFromEditor || _isHydratingForm) {
      return;
    }
    if (!_hasKaraokeChanges) {
      setState(() => _hasKaraokeChanges = true);
    }
  }

  void _parseJsonToEditor() {
    final jsonString = _karaokeJsonController.text.trim();

    if (jsonString.isEmpty) {
      SnackBarHelper.showWarning(context, 'JSON is empty');
      return;
    }

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = KaraokeData.fromJson(jsonMap);

      setState(() {
        _karaokeData = data;
        _hasKaraokeChanges = false;
      });

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Loaded ${data.lines.length} lines');
    } catch (error) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Invalid JSON: $error');
    }
  }

  void _addNewLine() {
    if (_karaokeData == null) {
      setState(() {
        _karaokeData = KaraokeData.empty();
      });
    }

    final newIndex = _karaokeData!.lines.length;
    final previousEndTime = _karaokeData!.lines.isEmpty ? 0.0 : _karaokeData!.lines.last.endTime;

    final newLine = KaraokeLine(
      index: newIndex,
      startTime: previousEndTime,
      endTime: previousEndTime + 5.0,
      hindi: '',
      english: '',
      hindiMeaning: '',
      englishMeaning: '',
    );

    setState(() {
      _karaokeData = KaraokeData(
        lines: [..._karaokeData!.lines, newLine],
        metadata: _karaokeData!.metadata.copyWith(lastUpdated: DateTime.now()),
      );
      _hasKaraokeChanges = true;
    });

    _syncEditorToJson();
  }

  Future<void> _updateLineStartTime(int index) async {
    final line = _karaokeData!.lines[index];
    final result = await _showNumberDialog('Edit Start Time', 'Enter start time in seconds', line.startTime);

    if (result != null) {
      _updateLine(index, line.copyWith(startTime: result));
    }
  }

  Future<void> _updateLineEndTime(int index) async {
    final line = _karaokeData!.lines[index];
    final result = await _showNumberDialog('Edit End Time', 'Enter end time in seconds', line.endTime);

    if (result != null) {
      _updateLine(index, line.copyWith(endTime: result));
    }
  }

  Future<void> _updateLineHindi(int index) async {
    final line = _karaokeData!.lines[index];
    final result = await _showTextDialog('Edit Hindi Text', 'Enter Hindi lyrics', line.hindi, useDevanagari: true);

    if (result != null) {
      _updateLine(index, line.copyWith(hindi: result));
    }
  }

  Future<void> _updateLineEnglish(int index) async {
    final line = _karaokeData!.lines[index];
    final result = await _showTextDialog('Edit English Text', 'Enter English lyrics', line.english);

    if (result != null) {
      _updateLine(index, line.copyWith(english: result));
    }
  }

  Future<void> _updateLineHindiMeaning(int index) async {
    final line = _karaokeData!.lines[index];
    final result = await _showTextDialog(
      'Edit Hindi Meaning',
      'Enter Hindi meaning/interpretation',
      line.hindiMeaning,
      useDevanagari: true,
    );

    if (result != null) {
      _updateLine(index, line.copyWith(hindiMeaning: result));
    }
  }

  Future<void> _updateLineEnglishMeaning(int index) async {
    final line = _karaokeData!.lines[index];
    final result = await _showTextDialog(
      'Edit English Meaning',
      'Enter English meaning/interpretation',
      line.englishMeaning,
    );

    if (result != null) {
      _updateLine(index, line.copyWith(englishMeaning: result));
    }
  }

  void _updateLine(int index, KaraokeLine updatedLine) {
    final lines = List<KaraokeLine>.from(_karaokeData!.lines);
    lines[index] = updatedLine;

    setState(() {
      _karaokeData = KaraokeData(
        lines: lines,
        metadata: _karaokeData!.metadata.copyWith(lastUpdated: DateTime.now()),
      );
      _hasKaraokeChanges = true;
    });

    _syncEditorToJson();
  }

  void _moveLineUp(int index) {
    if (index <= 0) return;

    final lines = List<KaraokeLine>.from(_karaokeData!.lines);
    final temp = lines[index];
    lines[index] = lines[index - 1].copyWith(index: index);
    lines[index - 1] = temp.copyWith(index: index - 1);

    setState(() {
      _karaokeData = KaraokeData(
        lines: lines,
        metadata: _karaokeData!.metadata.copyWith(lastUpdated: DateTime.now()),
      );
      _hasKaraokeChanges = true;
    });

    _syncEditorToJson();
  }

  void _moveLineDown(int index) {
    if (index >= _karaokeData!.lines.length - 1) return;

    final lines = List<KaraokeLine>.from(_karaokeData!.lines);
    final temp = lines[index];
    lines[index] = lines[index + 1].copyWith(index: index);
    lines[index + 1] = temp.copyWith(index: index + 1);

    setState(() {
      _karaokeData = KaraokeData(
        lines: lines,
        metadata: _karaokeData!.metadata.copyWith(lastUpdated: DateTime.now()),
      );
      _hasKaraokeChanges = true;
    });

    _syncEditorToJson();
  }

  Future<void> _deleteLine(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Line'),
        content: Text('Delete line ${_karaokeData!.lines[index].index}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final lines = List<KaraokeLine>.from(_karaokeData!.lines);
    lines.removeAt(index);
    for (var i = index; i < lines.length; i++) {
      lines[i] = lines[i].copyWith(index: i);
    }

    setState(() {
      _karaokeData = KaraokeData(
        lines: lines,
        metadata: _karaokeData!.metadata.copyWith(lastUpdated: DateTime.now()),
      );
      _hasKaraokeChanges = true;
    });

    _syncEditorToJson();

    if (!mounted) return;
    SnackBarHelper.showInfo(context, 'Line deleted');
  }

  void _syncEditorToJson() {
    if (_karaokeData == null) return;

    final jsonMap = _karaokeData!.toJson();
    const encoder = JsonEncoder.withIndent('  ');
    final prettyJson = encoder.convert(jsonMap);

    _isSyncingFromEditor = true;
    _karaokeJsonController.text = prettyJson;
    Future.microtask(() => _isSyncingFromEditor = false);
  }

  void _resetFormState() {
    _isHydratingForm = true;
    _hindiLyricsController.clear();
    _englishLyricsController.clear();
    _hindiMeaningController.clear();
    _englishMeaningController.clear();
    _isSyncingFromEditor = true;
    _karaokeJsonController.clear();
    Future.microtask(() => _isSyncingFromEditor = false);
    if (mounted) {
      setState(() {
        _karaokeData = null;
        _hasKaraokeChanges = false;
        _hasTextChanges = false;
      });
    }
    _isHydratingForm = false;
  }

  Future<double?> _showNumberDialog(String title, String label, double initialValue) async {
    final controller = TextEditingController(text: initialValue.toStringAsFixed(2));

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                Navigator.of(context).pop(value);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<String?> _showTextDialog(String title, String label, String initialValue, {bool useDevanagari = false}) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: useDevanagari ? GoogleFonts.notoSansDevanagari() : null,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('OK')),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  void _formatJson() {
    final jsonString = _karaokeJsonController.text.trim();

    if (jsonString.isEmpty) {
      SnackBarHelper.showWarning(context, 'JSON is empty');
      return;
    }

    try {
      final jsonMap = jsonDecode(jsonString);
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(jsonMap);

      _karaokeJsonController.text = prettyJson;

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'JSON formatted');
    } catch (error) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Invalid JSON: $error');
    }
  }

  void _validateJson() {
    final jsonString = _karaokeJsonController.text.trim();

    if (jsonString.isEmpty) {
      SnackBarHelper.showWarning(context, 'JSON is empty');
      return;
    }

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = KaraokeData.fromJson(jsonMap);
      final errors = data.validate();

      if (errors.isEmpty) {
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Valid JSON with ${data.lines.length} lines');
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Validation Errors'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors
                    .map(
                      (error) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text('• $error')),
                    )
                    .toList(),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Invalid JSON: $error');
    }
  }

  Future<void> _loadInitialLyrics() async {
    if (!mounted) return;
    setState(() => _isLoadingInitial = true);
    try {
      final lyrics = await ref.read(contentLyricsItemProvider(widget.content.id).future);
      if (!mounted) return;
      _currentLyrics = lyrics;
      _hydrateFromLyrics(lyrics);
    } on DioException catch (error) {
      if (!mounted) return;
      final message = error.message ?? 'Failed to load lyrics';
      SnackBarHelper.showError(context, message);
      _resetFormState();
    } catch (error) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to load lyrics: $error');
      _resetFormState();
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  void _hydrateFromLyrics(ContentLyrics? lyrics) {
    _isHydratingForm = true;
    if (lyrics == null) {
      _resetFormState();
      _isHydratingForm = false;
      return;
    }

    _hindiLyricsController.text = lyrics.hindiLyrics ?? '';
    _englishLyricsController.text = lyrics.englishLyrics ?? '';
    _hindiMeaningController.text = lyrics.hindiMeaning ?? '';
    _englishMeaningController.text = lyrics.englishMeaning ?? '';

    KaraokeData? parsedData;
    final rawJson = lyrics.timestampedData;
    if (rawJson != null && rawJson.trim().isNotEmpty) {
      final pretty = _prettyPrintJson(rawJson);
      _isSyncingFromEditor = true;
      _karaokeJsonController.text = pretty;
      Future.microtask(() => _isSyncingFromEditor = false);
      try {
        final jsonMap = jsonDecode(rawJson) as Map<String, dynamic>;
        parsedData = KaraokeData.fromJson(jsonMap);
      } catch (_) {
        parsedData = null;
      }
    } else {
      _isSyncingFromEditor = true;
      _karaokeJsonController.clear();
      Future.microtask(() => _isSyncingFromEditor = false);
      parsedData = null;
    }

    if (mounted) {
      setState(() {
        _karaokeData = parsedData;
        _hasKaraokeChanges = false;
        _hasTextChanges = false;
      });
    }
    _isHydratingForm = false;
  }

  String _prettyPrintJson(String source) {
    try {
      final decoded = jsonDecode(source);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return source;
    }
  }

  Future<void> _saveLyrics() async {
    if (_isSaving) return;

    if (_karaokeJsonController.text.trim().isNotEmpty) {
      try {
        final jsonMap = jsonDecode(_karaokeJsonController.text) as Map<String, dynamic>;
        final data = KaraokeData.fromJson(jsonMap);
        final errors = data.validate();

        if (errors.isNotEmpty) {
          if (!mounted) return;
          SnackBarHelper.showError(context, 'Fix karaoke validation errors first');
          return;
        }
      } catch (_) {
        if (!mounted) return;
        SnackBarHelper.showError(context, 'Fix karaoke JSON errors first');
        return;
      }
    }

    setState(() => _isSaving = true);

    final karaokeRaw = _karaokeJsonController.text.trim();
    final payload = ContentLyrics(
      id: _currentLyrics?.id,
      contentId: widget.content.id,
      hindiLyrics: _hindiLyricsController.text,
      englishLyrics: _englishLyricsController.text,
      hindiMeaning: _hindiMeaningController.text,
      englishMeaning: _englishMeaningController.text,
      timestampedData: karaokeRaw,
      hasTimestamps: karaokeRaw.isNotEmpty,
    );

    try {
      final saved = await ref.read(contentLyricsActionsProvider.notifier).saveLyrics(payload);
      if (!mounted) return;
      _currentLyrics = saved;
      SnackBarHelper.showSuccess(context, 'Lyrics saved successfully');
      await _loadInitialLyrics();
    } on DioException catch (error) {
      if (!mounted) return;
      final responseData = error.response?.data;
      String? backendMessage;
      if (responseData is Map<String, dynamic>) {
        backendMessage = responseData['message'] as String?;
      }
      final message = backendMessage ?? error.message ?? 'Failed to save lyrics';
      SnackBarHelper.showError(context, message);
    } catch (error) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to save lyrics: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

enum _UnsavedChangesAction { cancel, discard, save }
