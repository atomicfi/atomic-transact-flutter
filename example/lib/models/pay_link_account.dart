/// A Pay Link action, launched with `AtomicTask.action`.
class PayLinkAction {
  final String id;
  final String type;

  const PayLinkAction({required this.id, required this.type});
}

/// A bill and the actions that apply to it, e.g. `cancel-plan`.
class PayLinkBill {
  final String name;
  final List<PayLinkAction> actions;

  const PayLinkBill({required this.name, required this.actions});
}

/// An account from `GET /pay-link/accounts`, trimmed to what the Actions tab
/// shows.
class PayLinkAccount {
  final String id;
  final String name;
  final List<PayLinkAction> actions;

  /// Bills that have actions of their own.
  final List<PayLinkBill> bills;

  const PayLinkAccount({
    required this.id,
    required this.name,
    required this.actions,
    required this.bills,
  });

  factory PayLinkAccount.fromJson(Map<String, dynamic> json) {
    final company = json['company'];
    final actions = _actions(json['actions']);

    // The API repeats an account's actions on each of its bills; list them once.
    final accountActionIds = actions.map((a) => a.id).toSet();
    final bills = <PayLinkBill>[];
    for (final bill in _list(json['bills'])) {
      if (bill is! Map) continue;
      final billActions = _actions(bill['actions'])
          .where((a) => !accountActionIds.contains(a.id))
          .toList();
      if (billActions.isEmpty) continue;

      bills.add(PayLinkBill(
        name: bill['name']?.toString() ?? 'Bill',
        actions: billActions,
      ));
    }

    return PayLinkAccount(
      id: json['_id']?.toString() ?? '',
      name: (company is Map ? company['name']?.toString() : null) ?? 'Account',
      actions: actions,
      bills: bills,
    );
  }

  bool get hasActions => actions.isNotEmpty || bills.isNotEmpty;

  static List<PayLinkAction> _actions(Object? value) {
    return [
      for (final action in _list(value))
        if (action is Map && action['actionId'] != null)
          PayLinkAction(
            id: action['actionId'].toString(),
            type: action['type']?.toString() ?? 'unknown',
          ),
    ];
  }

  static List<Object?> _list(Object? value) => value is List ? value : const [];
}
