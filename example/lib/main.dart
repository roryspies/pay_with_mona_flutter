import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pay With Mona Example")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            PayWithMona.startPayment(context);
          },
          child: const Text(
            "Pay Now",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
