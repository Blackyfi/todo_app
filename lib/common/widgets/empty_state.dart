import 'package:flutter/material.dart' as mat;

class EmptyState extends mat.StatelessWidget {
  final String message;
  final mat.IconData icon;
  final mat.VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyState({
    mat.Key? key,
    required this.message,
    this.icon = mat.Icons.info_outline,
    this.onActionPressed,
    this.actionLabel,
  }) : super(key: key);

  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.Center(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16.0),
        child: mat.Column(
          mainAxisAlignment: mat.MainAxisAlignment.center,
          children: [
            mat.Icon(
              icon,
              size: 80,
              color: mat.Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const mat.SizedBox(height: 16),
            mat.Text(
              message,
              textAlign: mat.TextAlign.center,
              style: mat.Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: mat.Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const mat.SizedBox(height: 24),
              mat.FilledButton(
                onPressed: onActionPressed,
                child: mat.Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
