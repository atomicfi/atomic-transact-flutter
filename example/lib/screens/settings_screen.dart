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
                ToggleRow(
                  title: 'Debug Mode',
                  value: state.debug,
                  onChanged: (v) => state.debug = v,
                ),
                const SizedBox(height: 16),
                const Divider(indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                const SectionHeader('Pause'),
                ToggleRow(
                  title: 'Pause After Initialize',
                  subtitle: 'Automatically pause Transact after a delay',
                  value: state.pauseAfterInit,
                  onChanged: (v) => state.pauseAfterInit = v,
                ),
                if (state.pauseAfterInit)
                  _PauseDelayPicker(
                    seconds: state.pauseDelaySeconds,
                    onChanged: (v) => state.pauseDelaySeconds = v,
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

class _PauseDelayPicker extends StatelessWidget {
  final int seconds;
  final ValueChanged<int> onChanged;

  const _PauseDelayPicker({required this.seconds, required this.onChanged});

  static const _options = [1, 2, 3, 5, 10, 15, 30];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delay (seconds)',
            style: TextStyle(fontSize: 14, color: atomicOnSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _options.map((s) {
              final selected = s == seconds;
              return ChoiceChip(
                label: Text('${s}s'),
                selected: selected,
                onSelected: (_) => onChanged(s),
                selectedColor: atomicPurple,
                backgroundColor: atomicSurface,
                side: BorderSide(
                  color: selected ? atomicPurple : atomicOutline,
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : atomicOnBackground,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
