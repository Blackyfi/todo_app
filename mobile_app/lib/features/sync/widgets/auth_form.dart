import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/sync/utils/sync_validator.dart'
    as validator;

/// Form for logging into or registering on the sync server.
class AuthForm extends mat.StatefulWidget {
  final String? currentUsername;
  final Future<String?> Function(String username, String password) onLogin;
  final Future<String?> Function(String username, String password) onRegister;
  final Future<void> Function() onLogout;

  const AuthForm({
    super.key,
    this.currentUsername,
    required this.onLogin,
    required this.onRegister,
    required this.onLogout,
  });

  @override
  mat.State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends mat.State<AuthForm> {
  final _formKey = mat.GlobalKey<mat.FormState>();
  final _usernameController = mat.TextEditingController();
  final _passwordController = mat.TextEditingController();
  bool _loading = false;
  bool _isRegisterMode = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  bool get _isLoggedIn =>
      widget.currentUsername != null && widget.currentUsername!.isNotEmpty;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final user = _usernameController.text.trim();
    final pass = _passwordController.text;

    try {
      String? error;
      if (_isRegisterMode) {
        error = await widget.onRegister(user, pass);
        if (error == null) {
          // Auto-login after successful registration
          error = await widget.onLogin(user, pass);
        }
      } else {
        error = await widget.onLogin(user, pass);
      }

      if (mounted) {
        setState(() {
          _errorMessage = error;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  mat.Widget build(mat.BuildContext context) {
    if (_isLoggedIn) return _buildLoggedInView(context);
    return _buildLoginForm(context);
  }

  mat.Widget _buildLoggedInView(mat.BuildContext context) {
    return mat.Column(
      children: [
        mat.ListTile(
          leading: const mat.Icon(mat.Icons.check_circle, color: mat.Colors.green),
          title: mat.Text('Logged in as ${widget.currentUsername}'),
          subtitle: const mat.Text('Authenticated with server'),
        ),
        mat.Padding(
          padding: const mat.EdgeInsets.symmetric(horizontal: 16),
          child: mat.SizedBox(
            width: double.infinity,
            child: mat.OutlinedButton.icon(
              onPressed: () => widget.onLogout(),
              icon: const mat.Icon(mat.Icons.logout),
              label: const mat.Text('Log Out'),
              style: mat.OutlinedButton.styleFrom(
                foregroundColor: mat.Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
      ],
    );
  }

  mat.Widget _buildLoginForm(mat.BuildContext context) {
    final theme = mat.Theme.of(context);

    return mat.Form(
      key: _formKey,
      child: mat.Padding(
        padding: const mat.EdgeInsets.symmetric(horizontal: 16),
        child: mat.Column(
          children: [
            mat.TextFormField(
              controller: _usernameController,
              decoration: const mat.InputDecoration(
                labelText: 'Username',
                prefixIcon: mat.Icon(mat.Icons.person),
              ),
              validator: validator.SyncValidator.validateUsername,
              textInputAction: mat.TextInputAction.next,
            ),
            const mat.SizedBox(height: 12),
            mat.TextFormField(
              controller: _passwordController,
              decoration: mat.InputDecoration(
                labelText: 'Password',
                prefixIcon: const mat.Icon(mat.Icons.lock),
                suffixIcon: mat.IconButton(
                  icon: mat.Icon(
                    _obscurePassword
                        ? mat.Icons.visibility_off
                        : mat.Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator: validator.SyncValidator.validatePassword,
              textInputAction: mat.TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              const mat.SizedBox(height: 8),
              mat.Text(
                _errorMessage!,
                style: mat.TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const mat.SizedBox(height: 16),
            mat.SizedBox(
              width: double.infinity,
              child: mat.FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const mat.SizedBox(
                        width: 16,
                        height: 16,
                        child: mat.CircularProgressIndicator(
                          strokeWidth: 2,
                          color: mat.Colors.white,
                        ),
                      )
                    : mat.Icon(
                        _isRegisterMode
                            ? mat.Icons.person_add
                            : mat.Icons.login,
                      ),
                label: mat.Text(_isRegisterMode ? 'Register' : 'Log In'),
              ),
            ),
            mat.TextButton(
              onPressed: () => setState(() {
                _isRegisterMode = !_isRegisterMode;
                _errorMessage = null;
              }),
              child: mat.Text(
                _isRegisterMode
                    ? 'Already have an account? Log in'
                    : 'No account? Register',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
