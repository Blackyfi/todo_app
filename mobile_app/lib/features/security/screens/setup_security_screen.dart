import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/security/models/auth_type.dart';
import '../../../core/security/models/password_strength.dart';
import '../../../core/security/services/password_strength_analyzer.dart';
import '../../../core/security/providers/security_provider.dart';
import '../../../core/widgets/services/widget_service.dart';
import '../widgets/password_strength_indicator.dart';
import 'security_info_screen.dart';

class SetupSecurityScreen extends StatefulWidget {
  const SetupSecurityScreen({super.key});

  @override
  State<SetupSecurityScreen> createState() => _SetupSecurityScreenState();
}

class _SetupSecurityScreenState extends State<SetupSecurityScreen> {
  AuthType _selectedAuthType = AuthType.none;
  final _credentialController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCredential = true;
  bool _obscureConfirm = true;
  bool _enableBiometric = false;
  PasswordStrengthResult? _strengthResult;
  bool _isLoading = false;

  @override
  void dispose() {
    _credentialController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onCredentialChanged(String value) {
    if (_selectedAuthType == AuthType.none) return;

    setState(() {
      if (_selectedAuthType == AuthType.pin) {
        _strengthResult = PasswordStrengthAnalyzer.analyzePinStrength(value);
      } else {
        _strengthResult = PasswordStrengthAnalyzer.analyzePasswordStrength(value);
      }
    });
  }

  Future<void> _setupSecurity() async {
    if (_selectedAuthType == AuthType.none) {
      Navigator.pop(context);
      return;
    }

    final credential = _credentialController.text;
    final confirm = _confirmController.text;

    if (credential.isEmpty) {
      _showError('Please enter a ${_selectedAuthType == AuthType.pin ? "PIN" : "password"}');
      return;
    }

    if (credential != confirm) {
      _showError('Credentials do not match');
      return;
    }

    if (_selectedAuthType == AuthType.pin && !PasswordStrengthAnalyzer.isValidPin(credential)) {
      _showError('PIN must be 4-6 digits');
      return;
    }

    if (_selectedAuthType == AuthType.password && !PasswordStrengthAnalyzer.isValidPassword(credential)) {
      _showError('Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);

    final securityProvider = context.read<SecurityProvider>();
    final success = await securityProvider.setupSecurity(
      authType: _selectedAuthType,
      credential: credential,
      enableBiometric: _enableBiometric,
    );

    if (success) {
      // Disable all widgets when security is enabled
      final widgetService = WidgetService();
      await widgetService.disableAllWidgets();
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SecurityInfoScreen(isSetupComplete: true),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      _showError('Failed to setup security');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityProvider = context.watch<SecurityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Choose Protection Type',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAuthTypeOption(AuthType.pin),
                    const SizedBox(height: 12),
                    _buildAuthTypeOption(AuthType.password),
                    const SizedBox(height: 12),
                    _buildAuthTypeOption(AuthType.none),
                  ],
                ),
              ),
            ),
            if (_selectedAuthType != AuthType.none) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter ${_selectedAuthType == AuthType.pin ? "PIN" : "Password"}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _credentialController,
                        obscureText: _obscureCredential,
                        keyboardType: _selectedAuthType == AuthType.pin
                            ? TextInputType.number
                            : TextInputType.visiblePassword,
                        maxLength: _selectedAuthType == AuthType.pin ? 6 : null,
                        onChanged: _onCredentialChanged,
                        decoration: InputDecoration(
                          labelText: _selectedAuthType == AuthType.pin ? 'PIN' : 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCredential ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => _obscureCredential = !_obscureCredential);
                            },
                          ),
                        ),
                      ),
                      if (_strengthResult != null) ...[
                        const SizedBox(height: 16),
                        PasswordStrengthIndicator(result: _strengthResult!),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        keyboardType: _selectedAuthType == AuthType.pin
                            ? TextInputType.number
                            : TextInputType.visiblePassword,
                        maxLength: _selectedAuthType == AuthType.pin ? 6 : null,
                        decoration: InputDecoration(
                          labelText: 'Confirm ${_selectedAuthType == AuthType.pin ? "PIN" : "Password"}',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirm = !_obscureConfirm);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (securityProvider.canUseBiometric) ...[
                const SizedBox(height: 16),
                Card(
                  child: CheckboxListTile(
                    value: _enableBiometric,
                    onChanged: (value) {
                      setState(() => _enableBiometric = value ?? false);
                    },
                    title: const Text('Enable Biometric Authentication'),
                    subtitle: const Text('Use fingerprint or face recognition for quick access'),
                    secondary: const Icon(Icons.fingerprint),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isLoading ? null : _setupSecurity,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isLoading ? 'Setting up...' : 'Enable Security'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthTypeOption(AuthType authType) {
    final isSelected = _selectedAuthType == authType;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAuthType = authType;
          _credentialController.clear();
          _confirmController.clear();
          _strengthResult = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
        ),
        child: RadioGroup<AuthType>(
          groupValue: _selectedAuthType,
          onChanged: (value) {
            setState(() {
              _selectedAuthType = value!;
              _credentialController.clear();
              _confirmController.clear();
              _strengthResult = null;
            });
          },
          child: Row(
            children: [
              Radio<AuthType>(
                value: authType,
                toggleable: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          authType.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: authType == AuthType.password
                                ? Colors.green.withValues(alpha: 0.2)
                                : authType == AuthType.pin
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            authType.securityLevel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: authType == AuthType.password
                                  ? Colors.green.shade700
                                  : authType == AuthType.pin
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authType.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
