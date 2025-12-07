import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/security/models/auth_type.dart';
import '../../../core/security/providers/security_provider.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _credentialController = TextEditingController();
  bool _obscureCredential = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricAuth();
    });
  }

  @override
  void dispose() {
    _credentialController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricAuth() async {
    final securityProvider = context.read<SecurityProvider>();

    if (!securityProvider.biometricEnabled) return;

    final success = await securityProvider.authenticateWithBiometric();

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _unlock() async {
    final credential = _credentialController.text;

    if (credential.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your credential';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final securityProvider = context.read<SecurityProvider>();
    final success = await securityProvider.verifyCredential(credential);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = 'Incorrect ${securityProvider.authType == AuthType.pin ? "PIN" : "password"}';
        _credentialController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityProvider = context.watch<SecurityProvider>();
    final isPinMode = securityProvider.authType == AuthType.pin;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome Back',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your ${isPinMode ? "PIN" : "password"} to unlock',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _credentialController,
                            obscureText: _obscureCredential,
                            keyboardType: isPinMode
                                ? TextInputType.number
                                : TextInputType.visiblePassword,
                            maxLength: isPinMode ? 6 : null,
                            autofocus: !securityProvider.biometricEnabled,
                            onSubmitted: (_) => _unlock(),
                            decoration: InputDecoration(
                              labelText: isPinMode ? 'PIN' : 'Password',
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(
                                isPinMode ? Icons.pin : Icons.lock,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCredential ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() => _obscureCredential = !_obscureCredential);
                                },
                              ),
                              errorText: _errorMessage,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : _unlock,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock_open),
                            label: Text(_isLoading ? 'Unlocking...' : 'Unlock'),
                          ),
                          if (securityProvider.biometricEnabled) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _tryBiometricAuth,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Use Biometric'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Protected with AES-256 encryption',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
