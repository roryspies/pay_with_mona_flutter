import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/views/customer_info_view.dart';

class PayWithMona {
  static void startPayment(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerInfoView()),
    );
  }
}
