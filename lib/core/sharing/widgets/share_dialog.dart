import 'package:flutter/material.dart';
import '../models/share_data.dart';
import '../services/sharing_manager.dart';

/// Dialog for sharing data with encryption options
class ShareDialog extends StatefulWidget {
  final ShareData shareData;
  final String title;

  const ShareDialog({
    super.key,
    required this.shareData,
    this.title = 'Share',
  });

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final _sharingManager = SharingManager();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _useEncryption = false;
  bool _showPassword = false;
  bool _isSharing = false;
  String? _estimatedSize;

  @override
  void initState() {
    super.initState();
    _updateEstimatedSize();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _updateEstimatedSize() {
    final size = _sharingManager.estimateSize(
      widget.shareData,
      encrypted: _useEncryption,
    );

    setState(() {
      if (size < 1024) {
        _estimatedSize = '$size bytes';
      } else if (size < 1024 * 1024) {
        _estimatedSize = '${(size / 1024).toStringAsFixed(1)} KB';
      } else {
        _estimatedSize = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    });
  }

  Future<void> _handleShare() async {
    if (_useEncryption) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() => _isSharing = true);

    try {
      final password = _useEncryption ? _passwordController.text : null;

      await _sharingManager.share(
        shareData: widget.shareData,
        password: password,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _useEncryption
                  ? 'Encrypted share created successfully'
                  : 'Share created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data info
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
                      widget.shareData.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: $_estimatedSize',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Encryption toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Encrypt with password'),
                subtitle: const Text('Protect your data with a password'),
                value: _useEncryption,
                onChanged: (value) {
                  setState(() {
                    _useEncryption = value;
                    _updateEstimatedSize();
                  });
                },
              ),

              // Password field (shown when encryption enabled)
              if (_useEncryption) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter a strong password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
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
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
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
                        'The recipient will need this password to decrypt',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (_useEncryption) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AES-256-GCM encryption with PBKDF2 key derivation',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSharing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSharing ? null : _handleShare,
          icon: _isSharing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_useEncryption ? Icons.lock : Icons.share),
          label: Text(_isSharing ? 'Sharing...' : 'Share'),
        ),
      ],
    );
  }
}
