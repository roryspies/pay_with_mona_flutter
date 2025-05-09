import 'package:example/my_home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const PayWithMona());
}

class PayWithMona extends StatelessWidget {
  const PayWithMona({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pay With Mona',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(
            0xFF3045FB,
          ),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Pay With Mona',
      ),
    );
  }
}
