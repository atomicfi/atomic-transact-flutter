import 'package:flutter/material.dart';
import 'capsule_button.dart';
import 'section_header.dart';

class SingleSelectGrid<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelect;

  const SingleSelectGrid({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              return CapsuleButton(
                label: labelOf(opt),
                selected: opt == selected,
                onTap: () => onSelect(opt),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class MultiSelectGrid<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final Set<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onToggle;

  const MultiSelectGrid({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              return CapsuleButton(
                label: labelOf(opt),
                selected: selected.contains(opt),
                onTap: () => onToggle(opt),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
