import 'package:flutter/material.dart';

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
      case PaymentMethod.savedBank:
        return "bank";
      case PaymentMethod.savedCard:
        return "card";
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
        return "Pay By Bank Transfer";
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

enum PaymentTaskType { sign, pin, otp }

enum MerchantPaymentSettingsEnum {
  monaSuccess,
  debitSuccess,
  walletReceiveInProgress,
  walletReceiveComplete;

  String get displayName {
    switch (this) {
      case monaSuccess:
        return "Mona success";
      case debitSuccess:
        return "Debit success";
      case walletReceiveInProgress:
        return "Wallet receive in progress";
      case walletReceiveComplete:
        return "Wallet receive completed";
    }
  }

  String get paymentName {
    switch (this) {
      case monaSuccess:
        return "mona_success";
      case debitSuccess:
        return "debit_success";
      case walletReceiveInProgress:
        return "wallet_received";
      case walletReceiveComplete:
        return "wallet_completed";
    }
  }
}
