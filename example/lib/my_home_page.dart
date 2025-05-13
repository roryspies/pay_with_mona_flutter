import 'package:example/views/checkout_view.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NGDeals"),
      ),

      ///
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(
                double.infinity,
                40.0,
              ),
              backgroundColor: Color(
                0xFF3045FB,
              ),
              elevation: 8.0,
              padding: EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  8.0,
                ),
              ),
            ),
            onPressed: () async {
              /* Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutView(),
                ),
              ); */
            },
            child: const Text(
              "Pay Now",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
