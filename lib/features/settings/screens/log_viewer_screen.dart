import 'dart:io';
import 'package:flutter/material.dart';
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          if (_selectedLogFileName != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareSelectedLog,
              tooltip: 'Share log file',
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
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
    );
  }
}