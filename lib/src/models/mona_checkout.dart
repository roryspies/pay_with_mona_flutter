import 'package:flutter/material.dart';

class MonaCheckOut {
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? bvn;
  final String transactionId;
  final String merchantName;
  final Color primaryColor;
  final Color secondaryColor;

  MonaCheckOut({
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.dateOfBirth,
    this.bvn,
    required this.transactionId,
    required this.merchantName,
    required this.primaryColor,
    required this.secondaryColor,
  });

  // Convert from JSON
  factory MonaCheckOut.fromJson(Map<String, dynamic> json) {
    return MonaCheckOut(
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth:
          DateTime.tryParse(json['date_of_birth'] ?? '') ?? DateTime.now(),
      bvn: json['bvn'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      merchantName: json['merchant_name'] ?? '',
      primaryColor: json['primary_color'] ?? Colors.black,
      secondaryColor: json['secondary_color'] ?? Colors.black,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      "first_name": firstName,
      "middle_name": middleName,
      "last_name": lastName,
      "date_of_birth": dateOfBirth.toIso8601String(),
      "bvn": bvn,
      "transaction_id": transactionId,
      "merchant_name": merchantName,
      "primary_color": primaryColor,
      "secondary_color": secondaryColor,
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
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return MonaCheckOut(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bvn: bvn ?? this.bvn,
      transactionId: transactionId ?? this.transactionId,
      merchantName: merchantName ?? this.merchantName,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }

  @override
  String toString() {
    return 'MonaCheckOut(firstName: $firstName, middleName: $middleName, lastName: $lastName, dateOfBirth: $dateOfBirth, bvn: $bvn, transactionId: $transactionId, merchantName: $merchantName, primaryColor: $primaryColor, secondaryColor: $secondaryColor)';
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
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor;
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
        primaryColor.hashCode ^
        secondaryColor.hashCode;
  }
}
