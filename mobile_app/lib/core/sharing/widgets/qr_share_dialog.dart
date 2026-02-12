import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/share_data.dart';
import '../services/sharing_manager.dart';

/// Dialog for sharing data via QR code with encryption
/// Requires: qr_flutter package to be added to pubspec.yaml
///
/// Usage:
/// ```dart
/// // Add to pubspec.yaml:
/// // dependencies:
/// //   qr_flutter: ^4.1.0
///
/// // Then import and use QrImageView
/// ```
class QrShareDialog extends StatefulWidget {
  final ShareData shareData;
  final String title;

  const QrShareDialog({
    super.key,
    required this.shareData,
    this.title = 'Share via QR Code',
  });

  @override
  State<QrShareDialog> createState() => _QrShareDialogState();
}

class _QrShareDialogState extends State<QrShareDialog> {
  final _sharingManager = SharingManager();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _useEncryption = false;
  bool _showPassword = false;
  bool _isGenerating = false;
  String? _qrData;
  String? _errorMessage;
  bool _canFitInQr = true;

  @override
  void initState() {
    super.initState();
    _checkSize();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkSize() async {
    final canFit = await _sharingManager.canFitInQrCode(
      shareData: widget.shareData,
      password: null,
    );

    setState(() {
      _canFitInQr = canFit;
    });
  }

  Future<void> _generateQrCode() async {
    if (_useEncryption && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final password = _useEncryption ? _passwordController.text : null;

      final qrData = await _sharingManager.generateQrData(
        shareData: widget.shareData,
        password: password,
      );

      setState(() {
        _qrData = qrData;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isGenerating = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_qrData != null) {
      Clipboard.setData(ClipboardData(text: _qrData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR data copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: _qrData != null ? _buildQrView(theme) : _buildSetupView(theme),
        ),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildSetupView(ThemeData theme) {
    return Form(
      key: _formKey,
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
                Row(
                  children: [
                    Icon(
                      _canFitInQr ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: _canFitInQr ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _canFitInQr
                            ? 'Data size is suitable for QR code'
                            : 'Data may be too large for reliable QR scanning',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Encryption toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Encrypt with password'),
            subtitle: const Text('Protect your data with encryption'),
            value: _useEncryption,
            onChanged: (value) {
              setState(() {
                _useEncryption = value;
              });
            },
          ),

          // Password field
          if (_useEncryption) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter encryption password',
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
                    'Scanner will need this password to decrypt',
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
      ),
    );
  }

  Widget _buildQrView(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code placeholder
        // NOTE: To use actual QR code, add qr_flutter package:
        // QrImageView(
        //   data: _qrData!,
        //   version: QrVersions.auto,
        //   size: 300,
        //   backgroundColor: Colors.white,
        // )

        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_2,
                  size: 120,
                  color: Colors.black87,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'QR Code Generated!\n\nAdd qr_flutter package to display',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _useEncryption ? Icons.lock : Icons.qr_code,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _useEncryption
                          ? 'Encrypted QR Code'
                          : 'Plain QR Code',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Scan this QR code with the app to import the data',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Copy data button
        OutlinedButton.icon(
          onPressed: _copyToClipboard,
          icon: const Icon(Icons.copy),
          label: const Text('Copy QR Data'),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_qrData != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _isGenerating ? null : _generateQrCode,
        icon: _isGenerating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.qr_code_2),
        label: Text(_isGenerating ? 'Generating...' : 'Generate QR'),
      ),
    ];
  }
}
