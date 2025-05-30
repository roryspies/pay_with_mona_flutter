import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerDetailsNotifierProvider =
    NotifierProvider<CustomerDetailsNotifier, CustomerDetails>(() {
  return CustomerDetailsNotifier();
});

class CustomerDetailsNotifier extends Notifier<CustomerDetails> {
  @override
  CustomerDetails build() {
    return CustomerDetails(
      phoneNumber: '',
      firstName: '',
      middleName: '',
      lastName: '',
      dateOfBirth: '',
      bvn: '',
    );
  }

  void update({
    String? phoneNumber,
    String? firstName,
    String? middleName,
    String? lastName,
    String? dateOfBirth,
    String? bvn,
    void Function()? onEffect,
  }) async {
    final cleanedPhoneNumber =
        phoneNumber != null ? removeLeadingZero(phoneNumber) : null;

    state = state.copyWith(
      phoneNumber: cleanedPhoneNumber,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      bvn: bvn,
    );
  }

  void updatePhone({
    String? phoneNumber,
    void Function()? onEffect,
    required BuildContext context,
  }) async {
    final isValidNigerianNumber = phoneNumber != null &&
        phoneNumber.length == 11 &&
        phoneNumber.startsWith('0');

    final cleanedPhoneNumber =
        isValidNigerianNumber ? removeLeadingZero(phoneNumber) : phoneNumber;

    state = state.copyWith(phoneNumber: cleanedPhoneNumber);
  }

  void updateDOB({
    String? dateOFBirth,
    void Function()? onEffect,
    required BuildContext context,
  }) async {
    if (dateOFBirth == null || dateOFBirth.length < 10) {
      return;
    }

    state = state.copyWith(dateOfBirth: dateOFBirth);
  }

  void updateBVN({
    String? bvn,
    void Function()? onEffect,
    required BuildContext context,
  }) async {
    if (bvn == null || bvn.length < 10) {
      return;
    }

    state = state.copyWith(dateOfBirth: bvn);
  }

  String removeLeadingZero(String phoneNumber) {
    if (phoneNumber.startsWith('0') && phoneNumber.length == 11) {
      return phoneNumber.substring(1);
    }
    return phoneNumber;
  }

  int getFilledFieldCount() {
    final fields = [
      state.phoneNumber,
      state.firstName,
      state.middleName,
      state.lastName,
      state.dateOfBirth,
      state.bvn,
    ];

    return fields.where((field) => field.trim().isNotEmpty).length;
  }

  void clear() {
    state = const CustomerDetails();
  }
}

class CustomerDetails {
  final bool isLoading;
  final String phoneNumber;
  final String firstName;
  final String middleName;
  final String lastName;
  final String dateOfBirth;
  final String bvn;

  const CustomerDetails({
    this.isLoading = false,
    this.phoneNumber = '',
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.dateOfBirth = '',
    this.bvn = '',
  });

  CustomerDetails copyWith({
    bool? isLoading,
    String? phoneNumber,
    String? firstName,
    String? middleName,
    String? lastName,
    String? dateOfBirth,
    String? bvn,
  }) {
    return CustomerDetails(
      isLoading: isLoading ?? this.isLoading,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bvn: bvn ?? this.bvn,
    );
  }
}
