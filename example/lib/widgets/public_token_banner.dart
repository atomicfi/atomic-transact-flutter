import 'package:flutter/material.dart';
import '../theme/atomic_theme.dart';

class PublicTokenBanner extends StatelessWidget {
  final String publicToken;
  final VoidCallback onNavigateToSettings;

  const PublicTokenBanner({
    super.key,
    required this.publicToken,
    required this.onNavigateToSettings,
  });

  @override
  Widget build(BuildContext context) {
    if (publicToken.isNotEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onNavigateToSettings,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: eventRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: eventRed.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: eventRed, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Public token is required. Tap to go to Settings.',
                style: TextStyle(color: eventRed, fontSize: 13),
              ),
            ),
            Icon(Icons.chevron_right, color: eventRed, size: 20),
          ],
        ),
      ),
    );
  }
}
