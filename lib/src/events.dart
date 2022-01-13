import 'types.dart';

class AtomicTransactDataRequest {
  final String taskId;
  final String userId;
  final List<String> fields;
  final Map<String, dynamic> data;

  AtomicTransactDataRequest({
    required this.taskId,
    required this.userId,
    required this.fields,
    required this.data,
  });

  factory AtomicTransactDataRequest.fromJson(dynamic json) {
    return AtomicTransactDataRequest(
      taskId: json["taskId"] ?? '',
      userId: json["userId"] ?? '',
      fields: json["fields"] ?? [],
      data: Map<String, dynamic>.from(json["data"] ?? {}),
    );
  }
}

/// Response returned when transact is closed
class AtomicTransactResponse {
  /// Task Id of the transact operation
  final String? taskId;

  /// Handoff allows views to be handled outside of Transact. In place of the view, corresponding SDK events will be emitted that allows apps to respond and handle these views. [Handoff Pages](https://docs.atomicfi.com/#handoff-pages)
  final String? handoff;

  /// The reason that transact was closed. Such as `zero-search-results`, `task-pending`, or `unknown`
  final String? reason;

  /// All information returned from transact
  final Map<String, dynamic> data;

  AtomicTransactResponse({
    this.taskId,
    this.handoff,
    this.reason,
    required this.data,
  });

  factory AtomicTransactResponse.fromJson(dynamic json) {
    return AtomicTransactResponse(
      taskId: json["taskId"],
      handoff: json["handoff"],
      reason: json["reason"],
      data: Map<String, dynamic>.from(json["data"] ?? {}),
    );
  }
}

class AtomicTransactInteraction {
  final String name;

  final Map<String, dynamic> data;

  final String? description;

  final String? language;

  final String? customer;

  final AtomicProductType? product;

  final AtomicProductType? additionalProduct;

  final String? company;

  final String? payroll;

  AtomicTransactInteraction({
    required this.name,
    required this.data,
    this.description,
    this.language,
    this.customer,
    this.product,
    this.additionalProduct,
    this.company,
    this.payroll,
  });

  factory AtomicTransactInteraction.fromJson(dynamic json) {
    final typesMap = AtomicProductType.values.asNameMap();

    return AtomicTransactInteraction(
      name: json["name"] ?? '',
      data: Map<String, dynamic>.from(json["data"] ?? {}),
      description: json["description"],
      language: json["language"],
      customer: json["customer"],
      product: typesMap.containsKey(json["product"])
          ? typesMap[json["product"]]
          : null,
      additionalProduct: typesMap.containsKey(json["additionalProduct"])
          ? typesMap[json["additionalProduct"]]
          : null,
      company: json["company"],
      payroll: json["payroll"],
    );
  }
}
