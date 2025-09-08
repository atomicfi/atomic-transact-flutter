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
  void _onButtonPressed() {
    final AtomicConfig config = AtomicConfig(
      scope: 'user-link',
      publicToken: '',
      tasks: [AtomicTask(product: AtomicProductType.deposit)],
      theme: AtomicTheme(dark: true),
    );

    Atomic.transact(
      config: config,
      environment: TransactEnvironment.production,
      presentationStyleIOS: AtomicPresentationStyleIOS.formSheet,
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
      onAuthStatusUpdate: (AtomicTransactAuthStatusUpdate authStatus) {
        print("onAuthStatusUpdate");
        print("- status: ${authStatus.status}");
      },
      onTaskStatusUpdate: (AtomicTransactTaskStatusUpdate taskStatus) {
        print("onTaskStatusUpdate");
        print("- status: ${taskStatus.status}");
        print("- taskId: ${taskStatus.taskId}");
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

  void _onActionButtonPressed() {
    Atomic.presentAction(
      id: '',
      environment: TransactEnvironment.custom(
          'http://localhost:4545', 'http://localhost:3003'),
      theme: AtomicTheme(dark: true),
      presentationStyleIOS: AtomicPresentationStyleIOS.formSheet,
      onLaunch: () {
        print("onLaunch");
      },
      onAuthStatusUpdate: (AtomicTransactAuthStatusUpdate authStatus) {
        print("onAuthStatusUpdate");
        print("- status: ${authStatus.status}");
      },
      onTaskStatusUpdate: (AtomicTransactTaskStatusUpdate taskStatus) {
        print("onTaskStatusUpdate");
        print("- status: ${taskStatus.status}");
        print("- taskId: ${taskStatus.taskId}");
      },
      onCompletion: (AtomicTransactCompletionType type,
          AtomicTransactResponse? response, AtomicTransactError? error) {
        print("onCompletion");
        print("- type: ${type.name}");
        print("- error: ${error?.name}");
        print("- response.reason: ${response?.reason}");
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _onButtonPressed,
                child: const Text("Launch Transact"),
              ),
              ElevatedButton(
                onPressed: _onActionButtonPressed,
                child: const Text("Launch Action"),
              ),
              ElevatedButton(
                onPressed: () {
                  _onButtonPressed();
                  Future.delayed(Duration(seconds: 10), () {
                    Atomic.close();
                  });
                },
                child: const Text("Launch And Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
