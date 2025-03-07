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

  final Map<String, dynamic> value;

  final String? description;

  final String? language;

  final String? customer;

  final AtomicProductType? product;

  final AtomicProductType? additionalProduct;

  final String? company;

  final String? payroll;

  AtomicTransactInteraction({
    required this.name,
    required this.value,
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
      value: Map<String, dynamic>.from(json["value"] ?? {}),
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

class AtomicTransactAuthStatusUpdate {
  final String status;
  final AtomicTransactCompany company;

  AtomicTransactAuthStatusUpdate({
    required this.status,
    required this.company,
  });

  factory AtomicTransactAuthStatusUpdate.fromJson(Map<Object?, Object?> json) {
    return AtomicTransactAuthStatusUpdate(
      status: json['status']?.toString() ?? '',
      company: AtomicTransactCompany.fromJson(
          Map<String, dynamic>.from(json['company'] as Map<Object?, Object?>)),
    );
  }
}

class AtomicTransactTaskStatusUpdate {
  final String taskId;
  final String product;
  final String status;
  final String? failReason;
  final AtomicTransactCompany company;
  final Map<String, dynamic>? switchData;
  final Map<String, dynamic>? depositData;
  final Map<String, dynamic>? managedBy;

  AtomicTransactTaskStatusUpdate({
    required this.taskId,
    required this.product,
    required this.status,
    this.failReason,
    required this.company,
    this.switchData,
    this.depositData,
    this.managedBy,
  });

  factory AtomicTransactTaskStatusUpdate.fromJson(Map<Object?, Object?> json) {
    return AtomicTransactTaskStatusUpdate(
      taskId: json['taskId']?.toString() ?? '',
      product: json['product']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      failReason: json['failReason']?.toString(),
      company: AtomicTransactCompany.fromJson(
          Map<String, dynamic>.from(json['company'] as Map<Object?, Object?>)),
      switchData: json['switchData'] != null
          ? Map<String, dynamic>.from(
              json['switchData'] as Map<Object?, Object?>)
          : null,
      depositData: json['depositData'] != null
          ? Map<String, dynamic>.from(
              json['depositData'] as Map<Object?, Object?>)
          : null,
      managedBy: json['managedBy'] != null
          ? Map<String, dynamic>.from(
              json['managedBy'] as Map<Object?, Object?>)
          : null,
    );
  }
}

class AtomicTransactCompany {
  final String id;
  final String name;
  final AtomicTransactBranding? branding;

  AtomicTransactCompany({
    required this.id,
    required this.name,
    this.branding,
  });

  factory AtomicTransactCompany.fromJson(Map<Object?, Object?> json) {
    return AtomicTransactCompany(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branding: json['branding'] != null
          ? AtomicTransactBranding.fromJson(
              json['branding'] as Map<Object?, Object?>)
          : null,
    );
  }
}

class AtomicTransactBranding {
  final String color;
  final AtomicTransactLogo logo;

  AtomicTransactBranding({
    required this.color,
    required this.logo,
  });

  factory AtomicTransactBranding.fromJson(Map<Object?, Object?> json) {
    return AtomicTransactBranding(
      color: json['color']?.toString() ?? '',
      logo: AtomicTransactLogo.fromJson(json['logo'] as Map<Object?, Object?>),
    );
  }
}

class AtomicTransactLogo {
  final String url;
  final String? backgroundColor;

  AtomicTransactLogo({
    required this.url,
    this.backgroundColor,
  });

  factory AtomicTransactLogo.fromJson(Map<Object?, Object?> json) {
    return AtomicTransactLogo(
      url: json['url']?.toString() ?? '',
      backgroundColor: json['backgroundColor']?.toString(),
    );
  }
}
