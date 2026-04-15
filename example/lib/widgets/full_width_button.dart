import 'package:flutter/material.dart';
import '../theme/atomic_theme.dart';

class FullWidthButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onPressed;

  const FullWidthButton({
    super.key,
    required this.text,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: atomicPurple,
            disabledBackgroundColor: atomicPurple.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
