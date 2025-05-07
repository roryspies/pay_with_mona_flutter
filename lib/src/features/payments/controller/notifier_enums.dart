import 'package:flutter/material.dart';

enum PaymentState { idle, loading, success, error }

enum PaymentUserType {
  monaUser,
  nonMonaUser;

  String get userType {
    switch (this) {
      case PaymentUserType.monaUser:
        return "customer";
      case PaymentUserType.nonMonaUser:
        return "merchant";
    }
  }

  String get title {
    switch (this) {
      case PaymentUserType.monaUser:
        return "Customer";
      case PaymentUserType.nonMonaUser:
        return "Merchant";
    }
  }
}

enum PaymentMethod {
  none,
  savedBank,
  savedCard,
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
      default:
        return "";
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
      default:
        return "";
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
      default:
        return "";
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

      /// Using none as default as other options are not used.
      default:
        return Icons.close;
    }
  }
}
