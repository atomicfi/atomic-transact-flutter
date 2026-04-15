import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/atomic_theme.dart';
import '../widgets/clearable_text_field.dart';
import '../widgets/section_header.dart';
import '../widgets/toggle_row.dart';

class SettingsScreen extends StatelessWidget {
  final AppState state;

  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(title: const Text('Settings')),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Public Token'),
                ClearableTextField(
                  label: 'Public Token',
                  value: state.publicToken,
                  onChanged: (v) => state.publicToken = v,
                  hint: 'Paste your public token here',
                ),
                const SizedBox(height: 16),
                const Divider(indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                const SectionHeader('Transact URL'),
                _UrlModeSelector(
                  mode: state.urlMode,
                  onChanged: (m) => state.urlMode = m,
                ),
                if (state.urlMode == UrlMode.custom) ...[
                  ClearableTextField(
                    label: 'Custom Transact URL',
                    value: state.customTransactUrl,
                    onChanged: (v) => state.customTransactUrl = v,
                    hint: 'https://transact.atomicfi.com',
                  ),
                  ClearableTextField(
                    label: 'Custom API URL',
                    value: state.customApiUrl,
                    onChanged: (v) => state.customApiUrl = v,
                    hint: 'https://api.atomicfi.com',
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                const SectionHeader('UI Customization'),
                ToggleRow(
                  title: 'Dark Mode',
                  value: state.darkMode,
                  onChanged: (v) => state.darkMode = v,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UrlModeSelector extends StatelessWidget {
  final UrlMode mode;
  final ValueChanged<UrlMode> onChanged;

  const _UrlModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RadioGroup<UrlMode>(
        groupValue: mode,
        onChanged: (v) { if (v != null) onChanged(v); },
        child: Column(
          children: UrlMode.values.map((m) {
            final label = switch (m) {
              UrlMode.production => 'Production',
              UrlMode.sandbox => 'Sandbox',
              UrlMode.custom => 'Custom',
            };
            return RadioListTile<UrlMode>(
              title: Text(label),
              value: m,
              toggleable: false,
              activeColor: atomicPurple,
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ),
      ),
    );
  }
}
