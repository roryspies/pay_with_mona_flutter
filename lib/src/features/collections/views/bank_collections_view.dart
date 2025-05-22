import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/core/services/collections_services.dart';

import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/collections/widgets/trigger_result_view.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';
import 'package:pay_with_mona/src/widgets/custom_drop_down.dart';

class BankCollectionsView extends StatefulWidget {
  const BankCollectionsView({super.key, required this.merchantName});
  final String merchantName;

  @override
  State<BankCollectionsView> createState() => _BankCollectionsViewState();
}

class _BankCollectionsViewState extends State<BankCollectionsView> {
  final sdkNotifier = MonaSDKNotifier();
  final timeFactor = TimeFactor.day.notifier;
  String? _popupMessage;
  bool _showPopup = false;
  Timer? _popupTimer;
  BankOption? selectedBank;
  bool isError = false;

  Future<Map<String, dynamic>>? _collectionsFuture;

  void nav() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TriggerResultView(successMap: {}),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    sdkNotifier.addListener(_onSdkStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sdkNotifier.validatePII();
    });
  }

  void _onSdkStateChange() => setState(() {});

  void _onBankSelected(BankOption? bank) {
    setState(() {
      selectedBank = bank;
      _collectionsFuture = bank == null
          ? null
          : sdkNotifier.fetchCollectionsForBank(bankId: bank.bankId!);
    });
  }

  List<Map<String, dynamic>> _parseScheduleEntries(
      Map<String, dynamic> response) {
    final List<dynamic> requests = response['data']?['requests'] ?? [];

    if (requests.isEmpty) {
      'IT IS EMPTY'.log();
      return [];
    }

    'IT IS NOT EMPTY'.log();

    final latestRequest = requests.last;
    final collection = latestRequest['collection'];
    final reference = collection?['reference'] ?? 'Unknown';
    final entries = collection?['schedule']?['entries'] as List<dynamic>? ?? [];

    return entries
        .map((entry) => {
              'date': entry['date'],
              'amount': entry['amount'],
              'reference': reference,
            })
        .toList();
  }

  String _formatAmount(dynamic amount) {
    final value = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat("#,##0", "en_NG").format(value);
  }

  void showPopupMessage(String message,
      {Duration duration = const Duration(seconds: 2)}) {
    setState(() {
      _popupMessage = message;
      _showPopup = true;
    });

    // Auto-hide after duration
    _popupTimer?.cancel();
    _popupTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _showPopup = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedBanks =
        sdkNotifier.currentPaymentResponseModel?.savedPaymentOptions?.bank;
    return Scaffold(
      backgroundColor: MonaColors.bgGrey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // AppBar Replacement
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    BackButton(),
                    const SizedBox(width: 10),
                    const Text(
                      'Collections Scheduled',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Dropdown

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: savedBanks != null
                  ? DropdownButtonFormField<BankOption>(
                      style: TextStyle(
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Select Bank',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedBank,
                      items: savedBanks
                          .map((bank) => DropdownMenuItem<BankOption>(
                                value: bank,
                                child: Row(
                                  spacing: 10,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        bank.logo ?? '',
                                      ),
                                      radius: 16,
                                    ),
                                    Text(
                                      '${bank.bankName ?? ''} - ${bank.accountNumber ?? ''}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: _onBankSelected,
                    )
                  : const SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          'No collections available',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // FutureBuilder for collection data
            if (_collectionsFuture != null)
              FutureBuilder<Map<String, dynamic>>(
                future: _collectionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('No data found.'));
                  }

                  final entries = _parseScheduleEntries(snapshot.data!);

                  if (entries.isEmpty) {
                    return const Center(
                        child: Text('No entries for this collection.'));
                  }

                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Expanded(
                                child: Text('Amount',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                child: Text('Reference',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                child: Text('Date & Time',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const Divider(),
                        ...entries.map((entry) {
                          final dateTime = DateTime.tryParse(entry['date']) ??
                              DateTime.now();
                          final formattedDate =
                              DateFormat("d MMM yyyy").format(dateTime);
                          final formattedTime =
                              DateFormat.jm().format(dateTime);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(
                                        '₦${_formatAmount(entry['amount'])}')),
                                Expanded(child: Text(entry['reference'])),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(formattedDate),
                                      Text(formattedTime,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),

            if (_collectionsFuture != null) ...[
              context.sbH(40),
              [timeFactor].multiSync(builder: (context, child) {
                return Container(
                  width: double.infinity,
                  margin:
                      EdgeInsets.symmetric(horizontal: context.w(16)).copyWith(
                    bottom: context.h(40),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(20),
                    vertical: context.h(20),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: MonaColors.neutralWhite,
                  ),
                  child: Column(
                    children: [
                      CustomDropDownn(
                        title: '1 minute is equal to',
                        items: timeFactors,
                        value: timeFactor.value,
                        onChanged: (value) {
                          timeFactor.value = value;
                        },
                      ),
                      context.sbH(10.5),
                      sdkNotifier.state == MonaSDKState.loading
                          ? Align(
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                color: MonaColors.primaryBlue,
                              ),
                            )
                          : CustomButton(
                              onTap: () {
                                sdkNotifier
                                  ..setCallingBuildContext(context: context)
                                  ..triggerCollection(
                                      merchantId: '67e41f884126830aded0b43c',
                                      timeFactor: switch (timeFactor.value) {
                                        TimeFactor.day => 24 * 60,
                                        TimeFactor.week => 7 * 24 * 60,
                                        TimeFactor.month => 30 * 24 * 60,
                                      },
                                      onSuccess: (p0) async {
                                        setState(() {
                                          isError = false;
                                        });
                                        showPopupMessage(
                                            'Collection triggered successfully');

                                        await Future.delayed(
                                            Duration(seconds: 2));

                                        nav();
                                      },
                                      onError: (message) {
                                        isError = true;
                                        showPopupMessage(message);
                                      });
                              },
                              label: 'Continue',
                            ),
                    ],
                  ),
                );
              }),
            ],

            if (_showPopup && _popupMessage != null) ...[
              context.sbH(40),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: child,
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: context.w(20))
                      .copyWith(top: context.h(24)),
                  padding: EdgeInsets.symmetric(
                    vertical: context.h(10),
                    horizontal: context.w(16),
                  ),
                  decoration: BoxDecoration(
                    color:
                        isError ? Colors.red.shade700 : Colors.green.shade700,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: context.w(20),
                      ),
                      context.sbW(8),
                      Expanded(
                        child: Text(
                          _popupMessage!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              context.sbH(20),
            ],
          ],
        ),
      ),
    );
  }
}

class PaymentScheduleTextController {
  final int index;
  final TextEditingController paymentTextController;
  final TextEditingController dateTextController;

  PaymentScheduleTextController({
    required this.index,
    required this.paymentTextController,
    required this.dateTextController,
  });

  PaymentScheduleTextController copyWith({
    int? index,
    TextEditingController? paymentTextController,
    TextEditingController? dateTextController,
  }) {
    return PaymentScheduleTextController(
      index: index ?? this.index,
      paymentTextController:
          paymentTextController ?? this.paymentTextController,
      dateTextController: dateTextController ?? this.dateTextController,
    );
  }
}

String? convertToIsoDate(dynamic input) {
  try {
    if (input is String) {
      // Try to parse as "HH:mm dd/MM/yy" format first
      try {
        final parsedDateTime = DateFormat('HH:mm dd/MM/yy').parseStrict(input);
        return parsedDateTime
            .toIso8601String(); // Return full ISO string with time
      } catch (_) {
        // Fall back to original format "dd/MM/yyyy" if first format fails
        final parsedDate = DateFormat('dd/MM/yyyy').parseStrict(input);
        return parsedDate.toIso8601String().split('T').first;
      }
    } else if (input is DateTime) {
      return input.toIso8601String();
    } else {
      throw FormatException('Unsupported type');
    }
  } catch (e) {
    ('Error converting date: $e').log();
    return null;
  }
}

String _formatAmount(dynamic amount) {
  final value = double.tryParse(amount.toString()) ?? 0;
  final formatter = NumberFormat("#,##0", "en_NG");
  return formatter.format(value);
}
