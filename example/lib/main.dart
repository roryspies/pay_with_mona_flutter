import 'package:example/firebase_options.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/views/products_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await PayWithMona.initialize(merchantKey: "mona_pub_76e93ca1");

  runApp(
    ProviderScope(
      child: const PayWithMonaExampleApp(),
    ),
  );
}

class PayWithMonaExampleApp extends StatelessWidget {
  const PayWithMonaExampleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NG Deals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: MonaColors.primary,
        ),
        useMaterial3: true,
      ),
      home: ProductsView(),
    );
  }
}
