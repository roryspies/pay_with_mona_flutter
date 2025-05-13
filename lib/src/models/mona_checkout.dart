// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';

class MonaCheckOut {
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? bvn;
  final String transactionId;
  final String merchantName;
  final String phoneNumber;
  final Color primaryColor;
  final Color secondaryColor;
  final num amount;

  MonaCheckOut({
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.dateOfBirth,
    this.bvn,
    required this.transactionId,
    required this.merchantName,
    required this.phoneNumber,
    required this.primaryColor,
    required this.secondaryColor,
    required this.amount,
  });

  factory MonaCheckOut.fromJSON({
    required Map<String, dynamic> json,
  }) {
    return MonaCheckOut(
      firstName: json['first_name'] as String? ?? '',
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String? ?? '',
      dateOfBirth:
          DateTime.tryParse(json['date_of_birth'] ?? '') ?? DateTime.now(),
      bvn: json['bvn'] as String?,
      transactionId: json['transaction_id'] as String? ?? '',
      merchantName: json['merchant_name'] as String? ?? '',
      phoneNumber: json['phone'] as String? ?? '',
      primaryColor: json['primary_color'] as int != null
          ? Color(json['primary_color'] as int)
          : Colors.black,
      secondaryColor: json['secondary_color'] as int != null
          ? Color(json['secondary_color'] as int)
          : Colors.black,
      amount: json['amount'] as num? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "first_name": firstName,
      "middle_name": middleName,
      "last_name": lastName,
      "date_of_birth": dateOfBirth.toIso8601String(),
      "bvn": bvn,
      "transaction_id": transactionId,
      "merchant_name": merchantName,
      "phone": phoneNumber,
      "primary_color": primaryColor.value,
      "secondary_color": secondaryColor.value,
      "amount": amount,
    };
  }

  MonaCheckOut copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirth,
    String? bvn,
    String? transactionId,
    String? merchantName,
    String? phoneNumber,
    Color? primaryColor,
    Color? secondaryColor,
    num? amount,
  }) {
    return MonaCheckOut(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bvn: bvn ?? this.bvn,
      transactionId: transactionId ?? this.transactionId,
      merchantName: merchantName ?? this.merchantName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      amount: amount ?? this.amount,
    );
  }

  @override
  String toString() {
    return 'MonaCheckOut('
        'firstName: $firstName, '
        'middleName: $middleName, '
        'lastName: $lastName, '
        'dateOfBirth: $dateOfBirth, '
        'bvn: $bvn, '
        'transactionId: $transactionId, '
        'merchantName: $merchantName, '
        'phoneNumber: $phoneNumber, '
        'primaryColor: $primaryColor, '
        'secondaryColor: $secondaryColor, '
        'amount: $amount'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MonaCheckOut &&
        other.firstName == firstName &&
        other.middleName == middleName &&
        other.lastName == lastName &&
        other.dateOfBirth == dateOfBirth &&
        other.bvn == bvn &&
        other.transactionId == transactionId &&
        other.merchantName == merchantName &&
        other.phoneNumber == phoneNumber &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.amount == amount;
  }

  @override
  int get hashCode {
    return firstName.hashCode ^
        middleName.hashCode ^
        lastName.hashCode ^
        dateOfBirth.hashCode ^
        bvn.hashCode ^
        transactionId.hashCode ^
        merchantName.hashCode ^
        phoneNumber.hashCode ^
        primaryColor.hashCode ^
        secondaryColor.hashCode ^
        amount.hashCode;
  }
}
