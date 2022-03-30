import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AtomicConfig _config;

  @override
  void initState() {
    super.initState();

    _config = AtomicConfig(
      tasks: [AtomicTask(product: AtomicProductType.deposit)],
    );
  }

  void _onButtonPressed() {
    Atomic.transact(
      config: _config,
      onInteraction: (AtomicTransactInteraction interaction) {
        print("onInteraction");
        print("- name: ${interaction.name}");
        print("- description: ${interaction.description}");
        print("- language: ${interaction.language}");
        print("- customer: ${interaction.customer}");
        print("- company: ${interaction.company}");
        print("- product: ${interaction.product}");
        print("- additionalProduct: ${interaction.additionalProduct}");
        print("- payroll: ${interaction.payroll}");
        print("- data: ${interaction.value}");
      },
      onDataRequest: (AtomicTransactDataRequest request) {
        print("onDataRequest");
        print("- taskId: ${request.taskId}");
        print("- userId: ${request.userId}");
        print("- fields: ${request.fields}");
        print("- data: ${request.data}");
      },
      onCompletion: (AtomicTransactCompletionType type,
          AtomicTransactResponse? response, AtomicTransactError? error) {
        print("onCompletion");
        print("- type: ${type.name}");
        print("- error: ${error?.name}");
        print("- response.reason: ${response?.reason}");
        print("- response.handoff: ${response?.handoff}");
        print("- response.taskId: ${response?.taskId}");
        print("- response.data: ${response?.data}");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: _onButtonPressed,
            child: const Text("Launch Transact"),
          ),
        ),
      ),
    );
  }
}
