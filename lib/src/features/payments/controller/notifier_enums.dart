import 'package:flutter/material.dart';

enum PaymentState { idle, loading, success, error }

enum PaymentMethod {
  none,
  card,
  transfer;

  String get type {
    switch (this) {
      case PaymentMethod.card:
        return "card";
      case PaymentMethod.transfer:
        return "transfer";
      case PaymentMethod.none:
        return "none";
    }
  }

  String get title {
    switch (this) {
      case PaymentMethod.card:
        return "Pay by Card";
      case PaymentMethod.transfer:
        return "Pay by Transfer";
      case PaymentMethod.none:
        return "No payment method selected";
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.card:
        return "Visa, Verve and Mastercard accepted";
      case PaymentMethod.transfer:
        return "Pay for your order with cash on delivery";
      case PaymentMethod.none:
        return "No payment method selected";
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.transfer:
        return Icons.money;
      case PaymentMethod.none:
        return Icons.close;
    }
  }
}
