import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart' as services;
import 'package:todo_app/features/sync/models/sync_settings.dart'
    as settings_model;
import 'package:todo_app/features/sync/utils/sync_validator.dart'
    as validator;

/// Form widget for configuring the sync server connection.
class ServerConfigForm extends mat.StatefulWidget {
  final settings_model.SyncSettings settings;
  final ValueChanged<settings_model.SyncSettings> onSave;
  final Future<void> Function(settings_model.SyncSettings) onTest;

  const ServerConfigForm({
    super.key,
    required this.settings,
    required this.onSave,
    required this.onTest,
  });

  @override
  mat.State<ServerConfigForm> createState() => _ServerConfigFormState();
}

class _ServerConfigFormState extends mat.State<ServerConfigForm> {
  final _formKey = mat.GlobalKey<mat.FormState>();
  late mat.TextEditingController _urlController;
  late mat.TextEditingController _portController;
  late bool _useSsl;
  late bool _acceptSelfSigned;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController =
        mat.TextEditingController(text: widget.settings.serverUrl);
    _portController = mat.TextEditingController(
      text: widget.settings.serverPort.toString(),
    );
    _useSsl = widget.settings.useSsl;
    _acceptSelfSigned = widget.settings.acceptSelfSignedCert;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _portController.dispose();
    super.dispose();
  }

  settings_model.SyncSettings _buildSettings() {
    return widget.settings.copyWith(
      serverUrl: _urlController.text.trim(),
      serverPort: int.tryParse(_portController.text.trim()) ?? 8443,
      useSsl: _useSsl,
      acceptSelfSignedCert: _acceptSelfSigned,
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      await widget.onTest(_buildSettings());
      if (mounted) setState(() => _testResult = 'Connected successfully');
    } catch (e) {
      if (mounted) setState(() => _testResult = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(_buildSettings());
  }

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);

    return mat.Form(
      key: _formKey,
      child: mat.Column(
        crossAxisAlignment: mat.CrossAxisAlignment.start,
        children: [
          mat.TextFormField(
            controller: _urlController,
            decoration: const mat.InputDecoration(
              labelText: 'Server Address',
              hintText: 'e.g. 192.168.1.100 or myserver.com',
              prefixIcon: mat.Icon(mat.Icons.dns),
            ),
            validator: validator.SyncValidator.validateServerUrl,
          ),
          const mat.SizedBox(height: 12),
          mat.TextFormField(
            controller: _portController,
            decoration: const mat.InputDecoration(
              labelText: 'Port',
              hintText: '8443',
              prefixIcon: mat.Icon(mat.Icons.numbers),
            ),
            keyboardType: mat.TextInputType.number,
            inputFormatters: [
              services.FilteringTextInputFormatter.digitsOnly,
            ],
            validator: validator.SyncValidator.validatePort,
          ),
          const mat.SizedBox(height: 8),
          mat.SwitchListTile(
            title: const mat.Text('Use HTTPS'),
            subtitle: const mat.Text('Encrypt data in transit'),
            value: _useSsl,
            onChanged: (v) => setState(() => _useSsl = v),
          ),
          mat.SwitchListTile(
            title: const mat.Text('Accept self-signed certificates'),
            subtitle: const mat.Text(
              'Required for most self-hosted servers',
            ),
            value: _acceptSelfSigned,
            onChanged: (v) => setState(() => _acceptSelfSigned = v),
          ),
          if (_testResult != null) ...[
            const mat.SizedBox(height: 8),
            mat.Text(
              _testResult!,
              style: mat.TextStyle(
                color: _testResult!.startsWith('Connected')
                    ? mat.Colors.green
                    : theme.colorScheme.error,
              ),
            ),
          ],
          const mat.SizedBox(height: 16),
          mat.Row(
            children: [
              mat.Expanded(
                child: mat.OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const mat.SizedBox(
                          width: 16,
                          height: 16,
                          child: mat.CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const mat.Icon(mat.Icons.wifi_find),
                  label: const mat.Text('Test'),
                ),
              ),
              const mat.SizedBox(width: 12),
              mat.Expanded(
                child: mat.FilledButton.icon(
                  onPressed: _save,
                  icon: const mat.Icon(mat.Icons.save),
                  label: const mat.Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
