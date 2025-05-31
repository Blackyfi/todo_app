import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:cross_file/cross_file.dart';  // Added this import
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final LoggerService _logger = LoggerService();
  List<File> _logFiles = [];
  String? _selectedLogContent;
  String? _selectedLogFileName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  Future<void> _loadLogFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logFiles = await _logger.getLogFiles();
      
      setState(() {
        _logFiles = logFiles;
        _isLoading = false;
      });
      
      // Automatically load the most recent log file if available
      if (logFiles.isNotEmpty) {
        _loadLogContent(logFiles.first);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading log files: $e')),
        );
      }
    }
  }

  Future<void> _loadLogContent(File file) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final content = await file.readAsString();
      
      setState(() {
        _selectedLogContent = content;
        _selectedLogFileName = path.basename(file.path);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _selectedLogContent = 'Error reading log file: $e';
        _selectedLogFileName = path.basename(file.path);
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to delete all log files? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'DELETE',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _logger.clearLogs();
        
        setState(() {
          _logFiles = [];
          _selectedLogContent = null;
          _selectedLogFileName = null;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All logs cleared')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing logs: $e')),
          );
        }
      }
    }
  }

  Future<void> _shareSelectedLog() async {
    if (_selectedLogFileName == null) return;
    
    try {
      final logFile = _logFiles.firstWhere(
        (file) => path.basename(file.path) == _selectedLogFileName,
      );
      
      // Share the log file
      await Share.shareXFiles(
        [XFile(logFile.path)],
        subject: 'Todo App Log - $_selectedLogFileName',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing log file: $e')),
        );
      }
    }
  }

  // Copy log content to clipboard
  Future<void> _copyLogToClipboard() async {
    if (_selectedLogContent == null || _selectedLogContent!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No log content to copy')),
      );
      return;
    }
    
    try {
      await Clipboard.setData(ClipboardData(text: _selectedLogContent!));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log content copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error copying to clipboard: $e')),
        );
      }
    }
  }

  // Extract logs as JSON
  Future<void> _extractLogsAsJson() async {
    if (_logFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No log files to extract')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      
      // Create a map of log file names to their content
      final Map<String, String> logsMap = {};
      
      for (final file in _logFiles) {
        final fileName = path.basename(file.path);
        final content = await file.readAsString();
        logsMap[fileName] = content;
      }
      
      // Convert to JSON
      final jsonData = jsonEncode(logsMap);
      
      // Create a temporary file to share
      final tempDir = await getTemporaryDirectory();
      final jsonFile = File('${tempDir.path}/todo_app_logs.json');
      await jsonFile.writeAsString(jsonData);
      
      setState(() {
        _isLoading = false;
      });
      
      // Share the JSON file
      await Share.shareXFiles(
        [XFile(jsonFile.path)],
        subject: 'Todo App Logs - JSON Export',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error extracting logs as JSON: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          if (_selectedLogFileName != null)
            IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: _copyLogToClipboard,
              tooltip: 'Copy log content',
            ),
          if (_selectedLogFileName != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareSelectedLog,
              tooltip: 'Share log file',
            ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: _extractLogsAsJson,
            tooltip: 'Extract logs as JSON',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _logFiles.isNotEmpty ? _clearLogs : null,
            tooltip: 'Clear all logs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logFiles.isEmpty
              ? const Center(
                  child: Text('No log files found'),
                )
              : Row(
                  children: [
                    // Log file list sidebar
                    SizedBox(
                      width: 180,
                      child: ListView.builder(
                        itemCount: _logFiles.length,
                        itemBuilder: (context, index) {
                          final file = _logFiles[index];
                          final fileName = path.basename(file.path);
                          final isSelected = fileName == _selectedLogFileName;
                          
                          return ListTile(
                            title: Text(
                              fileName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: isSelected,
                            onTap: () => _loadLogContent(file),
                          );
                        },
                      ),
                    ),
                    // Vertical divider
                    const VerticalDivider(width: 1),
                    // Log content area
                    Expanded(
                      child: _selectedLogContent == null
                          ? const Center(
                              child: Text('Select a log file to view'),
                            )
                          : Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: SelectableText(
                                  _selectedLogContent!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: _logFiles.isEmpty 
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _copyLogToClipboard,
                      icon: const Icon(Icons.content_copy),
                      label: const Text('Copy Logs'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _extractLogsAsJson,
                      icon: const Icon(Icons.code),
                      label: const Text('Export as JSON'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _clearLogs,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear Logs'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}