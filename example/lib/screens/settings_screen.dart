import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
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
                const SizedBox(height: 16),
                const Divider(indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                const SectionHeader('Data Request Response'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Returned from onDataRequest when Transact asks for data. '
                    'Leave everything blank to send nothing back.',
                    style: TextStyle(
                        fontSize: 12, color: atomicOnSurfaceVariant),
                  ),
                ),
                ClearableTextField(
                  label: 'Card Number',
                  value: state.cardNumber,
                  onChanged: (v) => state.cardNumber = v,
                  hint: '4111111111111111',
                ),
                ClearableTextField(
                  label: 'Expiry',
                  value: state.cardExpiry,
                  onChanged: (v) => state.cardExpiry = v,
                  hint: 'MM/YY',
                ),
                ClearableTextField(
                  label: 'CVV',
                  value: state.cardCvv,
                  onChanged: (v) => state.cardCvv = v,
                  hint: '123',
                ),
                _CardTypePicker(
                  cardType: state.cardType,
                  onChanged: (v) => state.cardType = v,
                ),
                ClearableTextField(
                  label: 'First Name',
                  value: state.identityFirstName,
                  onChanged: (v) => state.identityFirstName = v,
                ),
                ClearableTextField(
                  label: 'Last Name',
                  value: state.identityLastName,
                  onChanged: (v) => state.identityLastName = v,
                ),
                ClearableTextField(
                  label: 'Address',
                  value: state.identityAddress,
                  onChanged: (v) => state.identityAddress = v,
                ),
                ClearableTextField(
                  label: 'City',
                  value: state.identityCity,
                  onChanged: (v) => state.identityCity = v,
                ),
                ClearableTextField(
                  label: 'State',
                  value: state.identityState,
                  onChanged: (v) => state.identityState = v,
                  hint: 'UT',
                ),
                ClearableTextField(
                  label: 'Postal Code',
                  value: state.identityPostalCode,
                  onChanged: (v) => state.identityPostalCode = v,
                ),
                ClearableTextField(
                  label: 'Phone',
                  value: state.identityPhone,
                  onChanged: (v) => state.identityPhone = v,
                ),
                ClearableTextField(
                  label: 'Email',
                  value: state.identityEmail,
                  onChanged: (v) => state.identityEmail = v,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextButton(
                    onPressed: state.clearDataRequestResponse,
                    child: const Text('Clear Data Request Response'),
                  ),
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

class _CardTypePicker extends StatelessWidget {
  final AtomicTransactCardType? cardType;
  final ValueChanged<AtomicTransactCardType?> onChanged;

  const _CardTypePicker({required this.cardType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Card Type',
            style: TextStyle(fontSize: 14, color: atomicOnSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AtomicTransactCardType.values.map((type) {
              final selected = type == cardType;
              return ChoiceChip(
                label: Text(type.name),
                selected: selected,
                // Tapping the selected chip clears it, since card type is optional.
                onSelected: (_) => onChanged(selected ? null : type),
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
