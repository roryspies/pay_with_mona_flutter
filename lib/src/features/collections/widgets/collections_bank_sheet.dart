// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/features/collections/widgets/collections_checkout_sheet.dart';
import 'package:pay_with_mona/src/models/collection_response.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/sdk_utils.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';
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
    sdkNotifier.updateSdkStateToIdle();
    sdkNotifier.addListener(_onSdkStateChange);
  }

  void _onSdkStateChange() {
    if (mounted) setState(() {});
  }

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

  void showPopupMessage(
    String message, {
    Duration duration = const Duration(
      seconds: 2,
    ),
  }) {
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
    "COLLECTIONS BANK SHEET !!!".log();
    final collection = widget.details!;
    final schedule = collection.schedule;
    // ignore: unused_local_variable
    final isScheduled = schedule.type == 'SCHEDULED';

    final savedBanks =
        sdkNotifier.currentPaymentResponseModel?.savedPaymentOptions?.bank;

    return Padding(
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
                    SvgPicture.asset('forback'.svg, height: context.h(22)),
                    CircleAvatar(
                      radius: context.w(24),
                      backgroundColor: (sdkNotifier.merchantBrandingDetails
                                  ?.colors.primaryColour ??
                              MonaColors.primaryBlue)
                          .withOpacity(0.1),
                      backgroundImage: switch (
                          sdkNotifier.merchantBrandingDetails != null &&
                              sdkNotifier
                                  .merchantBrandingDetails!.image.isNotEmpty) {
                        true => NetworkImage(
                            sdkNotifier.merchantBrandingDetails!.image,
                          ),
                        false => null,
                      },
                      child: switch (
                          sdkNotifier.merchantBrandingDetails != null &&
                              sdkNotifier
                                  .merchantBrandingDetails!.image.isNotEmpty) {
                        true => null,
                        false => Text(
                            getInitials(widget.merchantName),
                            style: TextStyle(
                              fontSize: context.sp(25),
                              fontWeight: FontWeight.w600,
                              color: (sdkNotifier.merchantBrandingDetails
                                      ?.colors.primaryColour ??
                                  MonaColors.primaryBlue),
                            ),
                          ),
                      },
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

                        if (bank.bankName!.toLowerCase().contains('opay') ||
                            bank.bankName!.toLowerCase().contains('palm') ||
                            bank.bankName!.toLowerCase().contains('kuda') ||
                            bank.bankName!.toLowerCase().contains('monie')) {
                          return SizedBox.shrink();
                        }

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
                                    ? (sdkNotifier.merchantBrandingDetails
                                            ?.colors.primaryColour ??
                                        MonaColors.primaryBlue)
                                    : MonaColors.bgGrey,
                              ),
                            ),
                            child: Center(
                              child: CircleAvatar(
                                radius: context.w(6),
                                backgroundColor: (selectedBank == bank)
                                    ? (sdkNotifier.merchantBrandingDetails
                                            ?.colors.primaryColour ??
                                        MonaColors.primaryBlue)
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
                InkWell(
                  onTap: () {
                    sdkNotifier.addBankAccountForCollections(
                        collectionId: widget.accessRequestId);
                  },
                  child: Padding(
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
                ),
                context.sbH(24),
                Builder(
                  builder: (context) {
                    return CustomButton(
                      isLoading: sdkNotifier.state == MonaSDKState.loading,
                      label: 'Approve debiting',
                      onTap: () async {
                        if (selectedBank == null) {
                          showPopupMessage('Please select a bank');
                          return;
                        }

                        /* sdkNotifier.setCallingBuildContext(
                          context: context,
                        ); */

                        await sdkNotifier.createCollections(
                          bankId: selectedBank?.bankId ?? '',
                          accessRequestId: widget.accessRequestId,
                          onSuccess: (successMap) async {
                            "CollectionsBankSheet ::: createCollections ::: onSuccess"
                                .log();
                            Navigator.of(MonaSDKNotifier().callingContext)
                                .pop();

                            await Future.delayed(Duration(milliseconds: 500));

                            ///
                            SDKUtils.showSDKModalBottomSheet(
                              callingContext: MonaSDKNotifier().callingContext,
                              child: CollectionsCheckoutSheet(
                                accessRequestId: widget.accessRequestId,
                                debitType: widget.debitType,
                                selectedBank: selectedBank,
                                successMap: successMap,
                                showSuccess: true,
                                scheduleEntries: widget.scheduleEntries,
                                method: widget.method,
                                details: Collection(
                                  maxAmount: widget.details!.maxAmount,
                                  expiryDate: widget.details!.expiryDate,
                                  startDate: widget.details!.startDate,
                                  monthlyLimit: widget.details!.monthlyLimit,
                                  schedule: Schedule(
                                    frequency: schedule.frequency,
                                    type: schedule.type,
                                    entries: schedule.entries,
                                    amount: schedule.amount,
                                  ),
                                  reference: widget.details!.reference,
                                  status: '',
                                  nextCollectionAt: '',
                                ),
                                merchantName: widget.merchantName,
                              ),
                            );
                            /* await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => Wrap(
                                children: [
                                  CollectionsCheckoutSheet(
                                    accessRequestId: widget.accessRequestId,
                                    debitType: widget.debitType,
                                    selectedBank: selectedBank,
                                    successMap: successMap,
                                    showSuccess: true,
                                    scheduleEntries: widget.scheduleEntries,
                                    method: widget.method,
                                    details: Collection(
                                      maxAmount: widget.details!.maxAmount,
                                      expiryDate: widget.details!.expiryDate,
                                      startDate: widget.details!.startDate,
                                      monthlyLimit:
                                          widget.details!.monthlyLimit,
                                      schedule: Schedule(
                                        frequency: schedule.frequency,
                                        type: schedule.type,
                                        entries: schedule.entries,
                                        amount: schedule.amount,
                                      ),
                                      reference: widget.details!.reference,
                                      status: '',
                                      nextCollectionAt: '',
                                    ),
                                    merchantName: widget.merchantName,
                                  ),
                                ],
                              ),
                            ); */
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

          ///
          if (_showPopup && _popupMessage != null) ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(
                milliseconds: 300,
              ),
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
          ],

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
    ).ignorePointer(
      isLoading: sdkNotifier.state == MonaSDKState.loading,
    );
  }
}

String getInitials(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.length < 2 ? trimmed : trimmed.substring(0, 2);
}
