import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mm_annonator/custom_text_editing_controller.dart';

class DatasetAnnonatorScreen extends StatefulWidget {
  const DatasetAnnonatorScreen({super.key});

  @override
  State<DatasetAnnonatorScreen> createState() => _DatasetAnnonatorScreenState();
}

class _DatasetAnnonatorScreenState extends State<DatasetAnnonatorScreen> {
  late CustomTextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final Map<String, String> _dictionary = {};
  final List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _controller = CustomTextEditingController(dictionary: _dictionary);
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    try {
      String dictionaryContent = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/dictionary.json');
      Map<String, dynamic> loadedDictionary = jsonDecode(dictionaryContent);
      setState(() {
        _dictionary.clear();
        _dictionary.addAll(
          loadedDictionary.map((key, value) => MapEntry(key, value.toString())),
        );
        _controller = CustomTextEditingController(dictionary: _dictionary);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading dictionary: $e')));
    }
  }

  Future<void> loadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString(encoding: const Utf8Codec());
        _controller.text = content; // Replace content directly
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading file: $e')));
    }
  }

  Future<void> saveDictionary() async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Dictionary File',
        fileName: 'dictionary.json',
      );
      if (outputPath != null) {
        File file = File(outputPath);
        if (await file.exists()) {
          bool? shouldOverride = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('File Exists'),
                  content: const Text(
                    'The file already exists. Do you want to override it?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
          );
          if (shouldOverride != true) return; // Exit if user declines
        }
        String jsonContent = jsonEncode(_dictionary);
        await file.writeAsString(jsonContent, encoding: const Utf8Codec());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dictionary saved successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving dictionary: $e')));
    }
  }

  void annotateText(String tag) {
    final selection = _controller.selection;
    if (selection.start != selection.end) {
      _history.add({
        'text': _controller.text,
        'selection': TextSelection(
          baseOffset: selection.baseOffset,
          extentOffset: selection.extentOffset,
        ),
      });

      String selectedText = _controller.text.substring(
        selection.start,
        selection.end,
      );
      _controller.addNewWord(selectedText, tag);
      _controller.text = _controller.text; // Trigger rebuild with new styling
      _controller.selection = TextSelection.collapsed(offset: selection.end);

      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select text to annotate')),
      );
    }
  }

  void undo() {
    if (_history.isNotEmpty) {
      final lastState = _history.removeLast();
      _controller.text = lastState['text'];
      _controller.selection = lastState['selection'];
      setState(() {});
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nothing to undo')));
    }
  }

  void cleanData() {
    String cleanedText =
        _controller.text
            .replaceAll(RegExp(r'\s+'), ' ') // Remove extra spaces
            .trim(); // Remove leading/trailing spaces
    _controller.text = cleanedText;
    setState(() {}); // Reflect changes in the UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Burmese Text Annotator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Field Column
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: loadFile,
                            child: const Text('Load File'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: cleanData,
                            child: const Text('Clean Data'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: saveDictionary,
                            child: const Text('Save Dictionary'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => annotateText('root'),
                            child: const Text('Root'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => annotateText('particle'),
                            child: const Text('Particle'),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ],
                  ),

                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontFamily: 'Pyidaungsu',
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter or load Burmese text here...',
                      ),
                      enableInteractiveSelection: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Select text to annotate with root or particle.',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            // Dictionary Canvas
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        _dictionary.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('${entry.key}: ${entry.value}'),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
