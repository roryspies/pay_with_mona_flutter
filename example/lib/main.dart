import 'package:example/firebase_options.dart';
import 'package:example/views/products_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: const PayWithMona()));
}

class PayWithMona extends StatelessWidget {
  const PayWithMona({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NG Deals',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ProductsView(),
    );
  }
}
