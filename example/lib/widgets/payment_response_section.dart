import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../screens/payment_response_screen.dart';
import '../theme/atomic_theme.dart';

/// Turns on the SDK deferred payment method strategy and shows what will be
/// returned from `onDataRequest` when Transact asks for it.
class PaymentResponseSection extends StatelessWidget {
  final AppState state;

  const PaymentResponseSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final on = state.useSdkPaymentResponse;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeaderRow(title: 'Payment response', badge: 'OPTIONAL'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: atomicSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: atomicOutline),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Use SDK payment response',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: atomicOnBackground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              on
                                  ? 'On — strategy is SDK'
                                  : 'Off — strategy stays API',
                              style: const TextStyle(
                                fontSize: 14,
                                color: atomicOnSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: on,
                        onChanged: (v) => state.useSdkPaymentResponse = v,
                        activeThumbColor: Colors.white,
                        activeTrackColor: atomicPurple,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(label: 'card', filled: state.hasCardData),
                            _Chip(
                                label: 'identity',
                                filled: state.hasIdentityData),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PaymentResponseScreen(state: state),
                          ));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: atomicPurpleLight,
                          side: const BorderSide(color: atomicOutline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  final String title;
  final String badge;

  const _SectionHeaderRow({required this.title, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
            color: atomicOnSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(height: 1)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: atomicOutline),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              letterSpacing: 1.2,
              color: atomicOnSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool filled;

  const _Chip({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: atomicBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: filled ? atomicOutline : atomicOutline.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: filled ? atomicOnBackground : atomicOnSurfaceVariant,
        ),
      ),
    );
  }
}
