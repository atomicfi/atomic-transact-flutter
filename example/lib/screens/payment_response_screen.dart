import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/atomic_theme.dart';

/// Editor for the data returned from `onDataRequest` when the SDK deferred
/// payment method strategy is on.
class PaymentResponseScreen extends StatefulWidget {
  final AppState state;

  const PaymentResponseScreen({super.key, required this.state});

  @override
  State<PaymentResponseScreen> createState() => _PaymentResponseScreenState();
}

class _PaymentResponseScreenState extends State<PaymentResponseScreen> {
  AppState get state => widget.state;

  bool _cardExpanded = true;
  bool _identityExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment response')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Sent back to Transact when it asks the app for a payment method. '
              'Card data is used for the switch; identity is always required.',
              style: TextStyle(fontSize: 13, color: atomicOnSurfaceVariant),
            ),
          ),
          _ExpandableCard(
            title: '${_cardTypeLabel(state.cardType)} card',
            badge: 'default',
            summary: state.cardSummary,
            complete: state.hasCardData,
            expanded: _cardExpanded,
            onToggle: () => setState(() => _cardExpanded = !_cardExpanded),
            children: [
              _FieldLabel('Card type'),
              _CardTypeSelector(
                selected: state.cardType,
                onChanged: (t) => setState(() => state.cardType = t),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Card number',
                initialValue: state.cardNumber,
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => state.cardNumber = v),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Expiry',
                      hint: 'MMYY',
                      initialValue: state.cardExpiry,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => state.cardExpiry = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'CVV',
                      initialValue: state.cardCvv,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => state.cardCvv = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ExpandableCard(
            title: 'Identity',
            badge: 'required',
            badgeColor: eventOrange,
            summary: state.identitySummary,
            complete: state.hasIdentityData,
            expanded: _identityExpanded,
            onToggle: () =>
                setState(() => _identityExpanded = !_identityExpanded),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'First name',
                      initialValue: state.identityFirstName,
                      onChanged: (v) =>
                          setState(() => state.identityFirstName = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'Last name',
                      initialValue: state.identityLastName,
                      onChanged: (v) =>
                          setState(() => state.identityLastName = v),
                    ),
                  ),
                ],
              ),
              _LabeledField(
                label: 'Address',
                initialValue: state.identityAddress,
                onChanged: (v) => setState(() => state.identityAddress = v),
              ),
              _LabeledField(
                label: 'Address 2',
                optional: true,
                initialValue: state.identityAddress2,
                onChanged: (v) => setState(() => state.identityAddress2 = v),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _LabeledField(
                      label: 'City',
                      initialValue: state.identityCity,
                      onChanged: (v) => setState(() => state.identityCity = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _LabeledField(
                      label: 'State',
                      initialValue: state.identityState,
                      onChanged: (v) => setState(() => state.identityState = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _LabeledField(
                      label: 'Postal code',
                      initialValue: state.identityPostalCode,
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          setState(() => state.identityPostalCode = v),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Phone',
                      optional: true,
                      initialValue: state.identityPhone,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => setState(() => state.identityPhone = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'Email',
                      optional: true,
                      initialValue: state.identityEmail,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => setState(() => state.identityEmail = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _cardTypeLabel(AtomicTransactCardType type) {
  return switch (type) {
    AtomicTransactCardType.credit => 'Credit',
    AtomicTransactCardType.debit => 'Debit',
  };
}

/// A section that shows a one-line summary when collapsed and its fields when open.
class _ExpandableCard extends StatelessWidget {
  final String title;
  final String badge;
  final Color? badgeColor;
  final String summary;
  final bool complete;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _ExpandableCard({
    required this.title,
    required this.badge,
    this.badgeColor,
    required this.summary,
    required this.complete,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final accent = badgeColor ?? atomicPurpleLight;

    return Container(
      decoration: BoxDecoration(
        color: atomicSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: complete ? eventGreen.withValues(alpha: 0.4) : atomicOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: complete
                          ? eventGreen.withValues(alpha: 0.15)
                          : atomicSurfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      complete ? Icons.check : Icons.add,
                      size: 20,
                      color: complete ? eventGreen : atomicOnSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: atomicOnBackground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Badge(label: badge, color: accent),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          style: const TextStyle(
                            fontSize: 13,
                            color: atomicOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.chevron_right,
                    color: atomicOnSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool optional;

  const _FieldLabel(this.label, {this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        optional ? '${label.toUpperCase()} · OPTIONAL' : label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: atomicOnSurfaceVariant,
        ),
      ),
    );
  }
}

/// Uppercase label above a filled field, matching the rest of this screen.
class _LabeledField extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool optional;
  final String? hint;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.optional = false,
    this.hint,
    this.keyboardType,
  });

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(widget.label, optional: widget.optional),
          TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            style: const TextStyle(fontSize: 15, color: atomicOnBackground),
            decoration: InputDecoration(
              hintText: widget.hint,
              isDense: true,
              fillColor: atomicBackground,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTypeSelector extends StatelessWidget {
  final AtomicTransactCardType selected;
  final ValueChanged<AtomicTransactCardType> onChanged;

  const _CardTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: atomicBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        // Fixed order rather than enum order, which puts debit first.
        children: const [
          AtomicTransactCardType.credit,
          AtomicTransactCardType.debit,
        ].map((type) {
          final isSelected = type == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? atomicPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _cardTypeLabel(type),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : atomicOnSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
