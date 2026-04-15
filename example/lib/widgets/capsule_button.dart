import 'package:flutter/material.dart';
import '../theme/atomic_theme.dart';

class CapsuleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CapsuleButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? atomicPurple.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? atomicPurple : atomicOutline,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check, size: 16, color: atomicPurple),
              ),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? atomicPurple : atomicOnBackground,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
