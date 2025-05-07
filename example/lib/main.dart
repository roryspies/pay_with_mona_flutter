import 'package:flutter/material.dart';
import 'package:example/views/checkout_view.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(
            0xFF3045FB,
          ),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Flutter Demo Home Page',
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NGDeals")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CheckoutView()),
            );
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
