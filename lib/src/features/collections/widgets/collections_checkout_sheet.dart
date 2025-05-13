import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/models/colllection_response.dart';

import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';

class CollectionsCheckoutSheet extends StatelessWidget {
  const CollectionsCheckoutSheet({
    super.key,
    this.details,
    required this.method,
    required this.merchantName,
  });

  final Map<String, dynamic>? details;
  final CollectionsMethod method;
  final String merchantName;

  String formatDate(String? iso) {
    if (iso == null) return '-';
    final parsed = DateTime.tryParse(iso);
    return parsed != null ? DateFormat('d MMM y').format(parsed) : iso;
  }

  @override
  Widget build(BuildContext context) {
    final collection =
        CollectionResponse.fromJson(details!).requests.last.collection;
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
            Container(
              height: context.h(36),
              width: double.infinity,
              decoration: BoxDecoration(
                color: MonaColors.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
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
                              child: Text(
                                getInitials(merchantName).toUpperCase(),
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
                          "${collection.reference} wants to automate repayments",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w600,
                            color: MonaColors.textHeading,
                          ),
                        ),
                        context.sbH(2),
                        Text(
                          "Please verify the details below",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.sp(14),
                            color: MonaColors.textBody,
                          ),
                        ),
                        context.sbH(24),

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
                                            '₦${isScheduled ? collection.maxAmount : schedule.amount ?? '-'}',
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
                                                ? collection.monthlyLimit ?? '-'
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
                            final sdkNotifier = MonaSDKNotifier();
                            return sdkNotifier.state == MonaSDKState.loading
                                ? Align(
                                    alignment: Alignment.center,
                                    child: CircularProgressIndicator(
                                      color: MonaColors.primaryBlue,
                                    ),
                                  )
                                : CustomButton(
                                    label: 'Continue to Mona',
                                    onTap: () {
                                      sdkNotifier
                                        ..setCallingBuildContext(
                                            context: context)
                                        ..triggerCollection(
                                          merchantId:
                                              '67e41f884126830aded0b43c',
                                          onSuccess: (p0) {
                                            Navigator.of(context).pop();
                                          },
                                        );
                                    },
                                  );
                          },
                        )
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
