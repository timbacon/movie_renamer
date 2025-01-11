import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RenamerContent extends StatefulWidget {
  const RenamerContent({super.key});

  @override
  State<RenamerContent> createState() => _RenamerContentState();
}

class _RenamerContentState extends State<RenamerContent> {
  List<PlatformFile>? _paths;
  bool _isLoading = false;
  double _progress = 0.0;
  bool _processing = false;
  String _currentlyProcessing = '';
  final List<String> _completed = [];
  final List<String> _skipped = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  void _resetState() {
    setState(() {
      _paths = null;
      _isLoading = false;
      _progress = 0.0;
      _processing = false;
    });
  }

  void _renameMovies() async {
    if (_paths == null) return;
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final String? apiKey = await prefs.getString('apiKey');

    if ((apiKey == null || apiKey == '') && mounted) {
      await displayInfoBar(context, builder: (context, close) {
        return InfoBar(
          title: const Text('No Api key found!'),
          content: const Text(
            'Please add your api key in the settings to continue renaming movies.',
          ),
          severity: InfoBarSeverity.warning,
        );
      });
      return;
    }

    setState(() {
      _processing = true;
    });
    final total = _paths!.length;
    for (var i = 0; i < total; i++) {
      final file = _paths![i];
      final name = file.name;
      final ext = name.split('.').last;
      final path = file.path?.substring(0, file.path!.length - name.length);

      if (path == null) continue;

      setState(() {
        _currentlyProcessing = file.path!;
      });

      int dateIndex = name.indexOf(RegExp('-([0-9]{4})'));
      if (dateIndex == -1) {
        dateIndex = name.indexOf(RegExp('([0-9]{4})'));
      }
      String? date = RegExp('-([0-9]{4})').firstMatch(name)?[0]?.substring(1);
      date ??= RegExp('([0-9]{4})').firstMatch(name)?[0];

      String cleanName = name
          .substring(0, dateIndex)
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();

      var response = await http.get(Uri.https('www.omdbapi.com', '/', {
        't': cleanName,
        'apikey': apiKey,
        'type': 'movie',
        'y': date,
      }));
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        String? Title = jsonResponse['Title'];
        String? Year = jsonResponse['Year'];
        if (jsonResponse['Response'] == 'False') {
          if (mounted) {
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (context) => ContentDialog(
                title: Text(jsonResponse['Error'] ?? 'Rename Failed!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to find movie details for $name'),
                    InfoLabel(
                        label: 'Movie Title',
                        child: TextBox(
                          controller: _titleController,
                        )),
                    InfoLabel(
                        label: 'Movie Year',
                        child: TextBox(
                          controller: _yearController,
                        )),
                  ],
                ),
                actions: [
                  Button(
                    child: const Text('Skip'),
                    onPressed: () {
                      Navigator.pop(context, {'skip': true});
                      // Delete file here
                    },
                  ),
                  FilledButton(
                    child: const Text('Rename'),
                    onPressed: () => Navigator.pop(context, {
                      'title': _titleController.text,
                      'year': _yearController.text
                    }),
                  ),
                ],
              ),
            );
            if (result == null || result['skip'] == true) {
              setState(() {
                _skipped.add(file.path!);
              });
              continue;
            }
            _titleController.clear();
            _yearController.clear();
            Title = result['title'];
            Year = result['year'];
          }
        }

        String newName =
            '${Title!.replaceAll(RegExp(r'[\/?:"*<>|]'), '')} ($Year)';
        File oldFile = File(file.path!);
        String newPath = '$path$newName${Platform.pathSeparator}';
        Directory(newPath).createSync(recursive: true);
        await oldFile.rename('$newPath$newName.$ext');
        setState(() {
          _currentlyProcessing = '';
          _completed.add(file.path!);
        });
      }

      setState(() {
        _progress = (i + 1) * 100 / total;
      });
    }
    setState(() {
      _processing = false;
    });
  }

  void pickFiles() async {
    try {
      _resetState();
      _paths = (await FilePicker.platform.pickFiles(
        compressionQuality: 30,
        type: FileType.video,
        allowMultiple: true,
        onFileLoading: (FilePickerStatus status) => print(status),
        dialogTitle: 'Select videos',
        lockParentWindow: true,
      ))
          ?.files;
    } on PlatformException catch (e) {
      developer.log('Unsupported operation$e');
    } catch (e) {
      developer.log(e.toString());
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Button(
                  onPressed: _isLoading ? null : pickFiles,
                  child: _isLoading
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: ProgressRing(
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FluentIcons.video_add),
                            SizedBox(width: 8),
                            Text('Select Movies to Rename'),
                          ],
                        ),
                ),
              ),
              if (_paths != null && _paths!.isNotEmpty) ...[
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(FluentIcons.clear),
                  onPressed: () {
                    setState(() {
                      _paths = null;
                    });
                  },
                )
              ]
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: _paths != null
                ? ListView.builder(
                    itemCount: _paths!.length,
                    itemBuilder: (context, index) {
                      final file = _paths![index];
                      return Row(
                        children: [
                          if (_completed.contains(file.path))
                            Icon(
                              FluentIcons.accept,
                              color: Colors.successPrimaryColor,
                              size: 12,
                            ),
                          if (_skipped.contains(file.path))
                            Icon(
                              FluentIcons.clear,
                              size: 12,
                            ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file.name,
                              //   softWrap: true,
                              style: TextStyle(
                                color: (_completed.contains(file.path))
                                    ? Color.fromARGB(255, 119, 119, 119)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Text('No movies selected'),
          ),
          if (_processing || _progress == 100.0) ...[
            SizedBox(height: 4),
            Text(
              _processing ? 'Processing: $_currentlyProcessing' : 'Completed!',
              style: FluentTheme.of(context).typography.caption,
            ),
            SizedBox(height: 4),
          ] else
            SizedBox(height: 24),
          FilledButton(
            onPressed: _paths == null || _processing || _progress == 100.0
                ? null
                : _renameMovies,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.rename),
                SizedBox(width: 8),
                Text('Rename Movies!'),
                SizedBox(width: 8),
                Icon(FluentIcons.accept),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
