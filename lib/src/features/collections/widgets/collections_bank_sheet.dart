// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/collections/widgets/collections_checkout_sheet.dart';
import 'package:pay_with_mona/src/models/collection_response.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';

import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';
import 'package:pay_with_mona/ui/widgets/bottom_sheet_top_header.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';

class CollectionsBankSheet extends StatefulWidget {
  const CollectionsBankSheet({
    super.key,
    this.details,
    required this.method,
    required this.merchantName,
    required this.scheduleEntries,
    required this.debitType,
    required this.accessRequestId,
  });

  final Collection? details;
  final CollectionsMethod method;
  final String merchantName;
  final String debitType;
  final List<Map<String, dynamic>> scheduleEntries;
  final String accessRequestId;

  @override
  State<CollectionsBankSheet> createState() => _CollectionsBankSheetState();
}

class _CollectionsBankSheetState extends State<CollectionsBankSheet> {
  final sdkNotifier = MonaSDKNotifier();
  String? _popupMessage;
  bool _showPopup = false;
  Timer? _popupTimer;
  BankOption? selectedBank;

  String formatDate(String? iso) {
    if (iso == null) return '-';
    final parsed = DateTime.tryParse(iso);
    return parsed != null ? DateFormat('d MMM y').format(parsed) : iso;
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

  void selectBank({required BankOption bank}) {
    setState(() {
      selectedBank = bank;
    });
  }

  @override
  void dispose() {
    _popupTimer?.cancel();
    super.dispose();
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
    final collection = widget.details!;
    final schedule = collection.schedule;
    // ignore: unused_local_variable
    final isScheduled = schedule.type == 'SCHEDULED';

    final savedBanks =
        sdkNotifier.currentPaymentResponseModel?.savedPaymentOptions?.bank;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        decoration: BoxDecoration(
          color: MonaColors.textField,
          borderRadius: BorderRadius.circular(10),
        ),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetTopHeader(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16))
                  .copyWith(top: context.h(20), bottom: context.h(21)),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.w(16)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Row(
                          spacing: context.w(8),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset('bank'.svg, height: context.h(48)),
                            SvgPicture.asset('forback'.svg,
                                height: context.h(22)),
                            CircleAvatar(
                              radius: context.w(24),
                              backgroundColor: MonaColors.primaryBlue,
                              backgroundImage: AssetImage(
                                "ng_deals_logo".png,
                              ),
                            ),
                          ],
                        ),
                        context.sbH(24),
                        Text(
                          "Select payment account ",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w600,
                            color: MonaColors.textHeading,
                          ),
                        ),
                        context.sbH(2),
                        Text(
                          "These are the account you linked, select the ones you’d like to link to NGdeals for repayments.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.sp(14),
                            color: MonaColors.textBody,
                          ),
                        ),
                        context.sbH(24),
                        if (savedBanks != null && savedBanks.isNotEmpty) ...[
                          Column(
                            children: savedBanks.map(
                              (bank) {
                                final selectedBankID =
                                    sdkNotifier.selectedBankOption?.bankId;

                                "Selected Bank ID: $selectedBankID";

                                return ListTile(
                                  onTap: () {
                                    selectBank(bank: bank);
                                  },

                                  /// ***
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: MonaColors.neutralWhite,
                                    child: Image.network(
                                      bank.logo ?? "",
                                    ),
                                  ),

                                  title: Text(
                                    bank.bankName ?? "",
                                    style: TextStyle(
                                      fontSize: context.sp(14),
                                      fontWeight: FontWeight.w500,
                                      color: MonaColors.textHeading,
                                    ),
                                  ),

                                  subtitle: Text(
                                    "Account - ${bank.accountNumber}",
                                    style: TextStyle(
                                      fontSize: context.sp(12),
                                      fontWeight: FontWeight.w400,
                                      color: MonaColors.textBody,
                                    ),
                                  ),

                                  trailing: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    height: context.h(24),
                                    width: context.w(24),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(context.h(24)),
                                      border: Border.all(
                                        width: 1.5,
                                        color: (selectedBank == bank)
                                            ? MonaColors.primaryBlue
                                            : MonaColors.bgGrey,
                                      ),
                                    ),
                                    child: Center(
                                      child: CircleAvatar(
                                        radius: context.w(6),
                                        backgroundColor: (selectedBank == bank)
                                            ? MonaColors.primaryBlue
                                            : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ],
                        context.sbH(24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.black,
                                size: 20,
                              ),
                              Text(
                                "Add an account",
                                style: TextStyle(
                                  fontSize: context.sp(15),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              Icon(
                                Icons.add,
                                color: Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                        context.sbH(24),
                        Builder(
                          builder: (context) {
                            return sdkNotifier.state == MonaSDKState.loading
                                ? Align(
                                    alignment: Alignment.center,
                                    child: CircularProgressIndicator(
                                      color: MonaColors.primaryBlue,
                                    ),
                                  )
                                : CustomButton(
                                    label: 'Approve debiting',
                                    onTap: () {
                                      if (selectedBank == null) {
                                        showPopupMessage(
                                            'Please select a bank');
                                        return;
                                      }
                                      sdkNotifier.setCallingBuildContext(
                                          context: context);
                                      sdkNotifier.createCollections(
                                        bankId: selectedBank?.bankId ??
                                            '680f5d983bccd31f1312645d',
                                        accessRequestId: widget.accessRequestId,
                                        onSuccess: (successMap) {
                                          Navigator.of(context).pop();
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (_) => Wrap(
                                              children: [
                                                CollectionsCheckoutSheet(
                                                  accessRequestId:
                                                      widget.accessRequestId,
                                                  debitType: widget.debitType,
                                                  selectedBank: selectedBank,
                                                  successMap: successMap,
                                                  showSuccess: true,
                                                  scheduleEntries:
                                                      widget.scheduleEntries,
                                                  method: widget.method,
                                                  details: Collection(
                                                    maxAmount: widget
                                                        .details!.maxAmount,
                                                    expiryDate: widget
                                                        .details!.expiryDate,
                                                    startDate: widget
                                                        .details!.startDate,
                                                    monthlyLimit: widget
                                                        .details!.monthlyLimit,
                                                    schedule: Schedule(
                                                      frequency:
                                                          schedule.frequency,
                                                      type: schedule.type,
                                                      entries: schedule.entries,
                                                      amount: schedule.amount,
                                                    ),
                                                    reference: widget
                                                        .details!.reference,
                                                    status: '',
                                                    nextCollectionAt: '',
                                                  ),
                                                  merchantName:
                                                      widget.merchantName,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        onFailure: () {
                                          showPopupMessage('An error occurred');
                                        },
                                      );
                                      // sdkNotifier
                                      //   ..setCallingBuildContext(
                                      //       context: context)
                                      //   ..triggerCollection(
                                      //     merchantId:
                                      //         '67e41f884126830aded0b43c',
                                      //     onSuccess: (p0) {
                                      //       Navigator.of(context).pop();
                                      //     },
                                      //   );
                                    },
                                  );
                          },
                        )
                      ],
                    ),
                  ),
                  if (_showPopup && _popupMessage != null)
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
                          color: Colors.red.shade700,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 2,
                    children: [
                      Text(
                        'Secured by ',
                        style: TextStyle(
                          fontSize: context.sp(12),
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Image.asset(
                        'textlogo'.png,
                        height: context.h(16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String getInitials(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.length < 2 ? trimmed : trimmed.substring(0, 2);
}
