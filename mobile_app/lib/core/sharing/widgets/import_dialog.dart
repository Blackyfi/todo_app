import 'package:flutter/material.dart';
import '../models/share_data.dart';
import '../services/sharing_manager.dart';

/// Dialog for importing shared data with decryption support
class ImportDialog extends StatefulWidget {
  final String? filePath;
  final String? rawContent;

  const ImportDialog({
    super.key,
    this.filePath,
    this.rawContent,
  }) : assert(filePath != null || rawContent != null);

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final _sharingManager = SharingManager();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showPassword = false;
  bool _isImporting = false;
  bool _isEncrypted = false;
  bool _needsPassword = false;
  String? _errorMessage;
  ShareData? _importedData;

  @override
  void initState() {
    super.initState();
    _checkIfEncrypted();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkIfEncrypted() async {
    try {
      if (widget.rawContent == null) {
        // Read file content
        setState(() => _isImporting = true);
        // This will be checked by the manager during import
      }

      final isEncrypted = widget.rawContent != null
          ? _sharingManager.isEncrypted(widget.rawContent!)
          : false;

      setState(() {
        _isEncrypted = isEncrypted;
        _isImporting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to read file: $e';
        _isImporting = false;
      });
    }
  }

  Future<void> _handleImport() async {
    setState(() {
      _isImporting = true;
      _errorMessage = null;
      _needsPassword = false;
    });

    try {
      final password = _isEncrypted ? _passwordController.text : null;

      ShareData shareData;
      if (widget.filePath != null) {
        shareData = await _sharingManager.importFromFile(
          filePath: widget.filePath!,
          password: password,
        );
      } else {
        shareData = await _sharingManager.importFromString(
          content: widget.rawContent!,
          password: password,
        );
      }

      setState(() {
        _importedData = shareData;
        _isImporting = false;
      });
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('Password required') ||
          errorString.contains('Authentication failed')) {
        setState(() {
          _needsPassword = true;
          _isEncrypted = true;
          _errorMessage = 'Incorrect password or encrypted data';
          _isImporting = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Import failed: $e';
          _isImporting = false;
        });
      }
    }
  }

  void _confirmImport() {
    if (_importedData != null) {
      Navigator.of(context).pop(_importedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Import Shared Data'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Import status or result
              if (_importedData != null) ...[
                _buildSuccessView(theme),
              ] else ...[
                _buildImportView(theme),
              ],
            ],
          ),
        ),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildImportView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File/Content info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _isEncrypted ? Icons.lock : Icons.file_present,
                color: _isEncrypted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEncrypted ? 'Encrypted Data' : 'Shared Data',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.filePath != null)
                      Text(
                        widget.filePath!.split('/').last,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Password field (if encrypted)
        if (_isEncrypted || _needsPassword) ...[
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter decryption password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_open),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _showPassword = !_showPassword);
                },
              ),
            ),
            validator: (value) {
              if (_isEncrypted && (value == null || value.isEmpty)) {
                return 'Password is required for encrypted data';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This data is encrypted. Enter the password to decrypt.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Import Successful!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Imported data info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Imported Data',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDataSummary(theme),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Click "Import" to add this data to your app',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataSummary(ThemeData theme) {
    if (_importedData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          Icons.category,
          'Type',
          _importedData!.description,
          theme,
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          Icons.calendar_today,
          'Created',
          _formatDate(_importedData!.createdAt),
          theme,
        ),
        if (_importedData!.isEncrypted) ...[
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.lock,
            'Encrypted',
            'Yes (AES-256-GCM)',
            theme,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Widget> _buildActions() {
    if (_importedData != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _confirmImport,
          icon: const Icon(Icons.download),
          label: const Text('Import'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _isImporting ? null : _handleImport,
        icon: _isImporting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.file_download),
        label: Text(_isImporting ? 'Importing...' : 'Decrypt & Import'),
      ),
    ];
  }
}
