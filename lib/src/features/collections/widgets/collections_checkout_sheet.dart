// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/collections/widgets/collections_bank_sheet.dart';
import 'package:pay_with_mona/src/features/collections/widgets/collections_trigger_view.dart';
import 'package:pay_with_mona/src/models/collection_response.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/bottom_sheet_top_header.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';

class CollectionsCheckoutSheet extends StatefulWidget {
  const CollectionsCheckoutSheet({
    super.key,
    this.details,
    required this.method,
    required this.merchantName,
    required this.scheduleEntries,
    this.showSuccess = false,
    this.successMap,
    this.selectedBank,
    required this.debitType,
  });

  final Collection? details;
  final CollectionsMethod method;
  final String merchantName;
  final List<Map<String, dynamic>> scheduleEntries;
  final bool showSuccess;
  final Map<String, dynamic>? successMap;
  final BankOption? selectedBank;
  final String debitType;

  @override
  State<CollectionsCheckoutSheet> createState() =>
      _CollectionsCheckoutSheetState();
}

class _CollectionsCheckoutSheetState extends State<CollectionsCheckoutSheet> {
  final sdkNotifier = MonaSDKNotifier();
  String? _popupMessage;
  bool _showPopup = false;
  Timer? _popupTimer;
  bool _showSuccessState = false;

  void showSuccess() {
    setState(() {
      _showSuccessState = true;
    });
  }

  void showSuccessFromOutside() {
    setState(() {
      _showSuccessState = widget.showSuccess;
    });
  }

  String formatDate(String? iso) {
    if (iso == null) return '-';
    final parsed = DateTime.tryParse(iso);
    return parsed != null ? DateFormat('d MMM y').format(parsed) : iso;
  }

  @override
  void initState() {
    super.initState();
    showSuccessFromOutside();
    sdkNotifier.addListener(_onSdktateChange);
  }

  @override
  void dispose() {
    _popupTimer?.cancel();
    super.dispose();
  }

  void _onSdktateChange() => setState(() {});

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

  void showBankSheet() {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Wrap(
        children: [
          CollectionsBankSheet(
            debitType: widget.debitType,
            method: widget.method,
            merchantName: widget.merchantName,
            scheduleEntries: widget.scheduleEntries,
            details: widget.details,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.details!;
    final schedule = collection.schedule;
    final isScheduled = schedule.type == 'SCHEDULED';

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
                        _showSuccessState
                            ? SvgPicture.asset('hooray'.svg,
                                height: context.h(48))
                            : Row(
                                spacing: context.w(8),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset('bank'.svg,
                                      height: context.h(48)),
                                  SvgPicture.asset('forback'.svg,
                                      height: context.h(22)),
                                  CircleAvatar(
                                    radius: context.w(24),
                                    child: Text(
                                      getInitials(widget.merchantName)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: context.sp(10),
                                        fontWeight: FontWeight.w500,
                                        color: MonaColors.textHeading,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        context.sbH(24),

                        Text(
                          _showSuccessState
                              ? 'Your automatic payments are confirmed'
                              : "${widget.merchantName} wants to automate repayments",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w600,
                            color: MonaColors.textHeading,
                          ),
                        ),
                        context.sbH(2),
                        Text(
                          _showSuccessState
                              ? "See the details below"
                              : "Please verify the details below",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.sp(14),
                            color: MonaColors.textBody,
                          ),
                        ),
                        context.sbH(24),
                        if (_showSuccessState &&
                            widget.selectedBank != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Payment account',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: context.sp(12),
                                fontWeight: FontWeight.w400,
                                color: MonaColors.textHeading,
                              ),
                            ),
                          ),
                          context.sbH(6),
                          Row(
                            spacing: context.w(8),
                            children: [
                              CircleAvatar(
                                  radius: context.w(18),
                                  child: Image.network(
                                    widget.selectedBank?.logo ?? "",
                                  )),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.selectedBank?.bankName ??
                                        'Bank name',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: context.sp(14),
                                      fontWeight: FontWeight.w500,
                                      color: MonaColors.textHeading,
                                    ),
                                  ),
                                  Text(
                                    widget.selectedBank?.accountNumber ??
                                        'Account number',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: context.sp(12),
                                      fontWeight: FontWeight.w400,
                                      color: MonaColors.textBody,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          context.sbH(16),
                        ],

                        // Debitor & Duration/Frequency
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: context.w(8)),
                          child: Row(
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    SvgPicture.asset('person'.svg,
                                        height: context.h(24)),
                                    context.sbW(8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Debitor",
                                            style: TextStyle(
                                              fontSize: context.sp(10),
                                              fontWeight: FontWeight.w300,
                                              color: MonaColors.textBody,
                                            ),
                                          ),
                                          context.sbH(2),
                                          Text(
                                            widget.merchantName,
                                            style: TextStyle(
                                              fontSize: context.sp(14),
                                              fontWeight: FontWeight.w500,
                                              color: MonaColors.textHeading,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Flexible(
                                child: Row(
                                  children: [
                                    SvgPicture.asset('calendar'.svg,
                                        height: context.h(24)),
                                    context.sbW(8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isScheduled
                                                ? 'Duration'
                                                : 'Frequency',
                                            style: TextStyle(
                                              fontSize: context.sp(10),
                                              fontWeight: FontWeight.w300,
                                              color: MonaColors.textBody,
                                            ),
                                          ),
                                          context.sbH(2),
                                          Text(
                                            isScheduled
                                                ? formatDate(
                                                    collection.expiryDate)
                                                : schedule.frequency ?? '-',
                                            style: TextStyle(
                                              fontSize: context.sp(14),
                                              fontWeight: FontWeight.w500,
                                              color: MonaColors.textHeading,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        context.sbH(20),

                        // Amount + Monthly Limit or Start
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: context.w(8)),
                          child: Row(
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    SvgPicture.asset('money'.svg,
                                        height: context.h(24)),
                                    context.sbW(8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isScheduled
                                                ? 'Total debit limit'
                                                : 'Amount',
                                            style: TextStyle(
                                              fontSize: context.sp(10),
                                              fontWeight: FontWeight.w300,
                                              color: MonaColors.textBody,
                                            ),
                                          ),
                                          context.sbH(2),
                                          Text(
                                            '₦${collection.maxAmount}',
                                            style: TextStyle(
                                              fontSize: context.sp(14),
                                              fontWeight: FontWeight.w500,
                                              color: MonaColors.textHeading,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      isScheduled
                                          ? 'money'.svg
                                          : 'calendar'.svg,
                                      height: context.h(24),
                                    ),
                                    context.sbW(8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isScheduled
                                                ? 'Monthly debit limit'
                                                : 'Start',
                                            style: TextStyle(
                                              fontSize: context.sp(10),
                                              fontWeight: FontWeight.w300,
                                              color: MonaColors.textBody,
                                            ),
                                          ),
                                          context.sbH(2),
                                          Text(
                                            isScheduled
                                                ? '₦${collection.monthlyLimit ?? '-'}'
                                                : formatDate(
                                                    collection.startDate),
                                            style: TextStyle(
                                              fontSize: context.sp(14),
                                              fontWeight: FontWeight.w500,
                                              color: MonaColors.textHeading,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        context.sbH(20),

                        // Reference
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: context.w(8)),
                          child: Row(
                            children: [
                              SvgPicture.asset('reference'.svg,
                                  height: context.h(24)),
                              context.sbW(8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Reference",
                                      style: TextStyle(
                                        fontSize: context.sp(10),
                                        fontWeight: FontWeight.w300,
                                        color: MonaColors.textBody,
                                      ),
                                    ),
                                    context.sbH(2),
                                    Text(
                                      collection.reference,
                                      style: TextStyle(
                                        fontSize: context.sp(14),
                                        fontWeight: FontWeight.w500,
                                        color: MonaColors.textHeading,
                                      ),
                                    ),
                                  ],
                                ),
                              )
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
                                    label: _showSuccessState
                                        ? 'Continue'
                                        : 'Continue to Mona',
                                    onTap: () async {
                                      if (_showSuccessState) {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CollectionsTriggerView(
                                                    successMap:
                                                        widget.successMap,
                                                    merchantName:
                                                        widget.merchantName),
                                          ),
                                        );
                                        return;
                                      }

                                      await sdkNotifier.collectionHandOffToAuth(
                                          onKeyExchange: () {
                                        showBankSheet();
                                      });
                                    },
                                  );
                          },
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
                              margin: EdgeInsets.symmetric(
                                      horizontal: context.w(20))
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
