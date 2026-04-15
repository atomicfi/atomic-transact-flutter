import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClearableTextField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;

  const ClearableTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value.isEmpty)
                IconButton(
                  icon: const Icon(Icons.paste, size: 20),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      onChanged(data!.text!);
                    }
                  },
                ),
              if (value.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => onChanged(''),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
