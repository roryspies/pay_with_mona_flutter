import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/models/collection_response.dart';

import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';

class CollectionsBankSheet extends StatefulWidget {
  const CollectionsBankSheet({
    super.key,
    this.details,
    required this.method,
    required this.merchantName,
  });

  final Map<String, dynamic>? details;
  final CollectionsMethod method;
  final String merchantName;

  @override
  State<CollectionsBankSheet> createState() => _CollectionsBankSheetState();
}

class _CollectionsBankSheetState extends State<CollectionsBankSheet> {
  final sdkNotifier = MonaSDKNotifier();
  String formatDate(String? iso) {
    if (iso == null) return '-';
    final parsed = DateTime.tryParse(iso);
    return parsed != null ? DateFormat('d MMM y').format(parsed) : iso;
  }

  @override
  void initState() {
    super.initState();
    sdkNotifier.addListener(_onSdktateChange);
  }

  void _onSdktateChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final collection =
        CollectionResponse.fromJson(widget.details!).requests.last.collection;
    final schedule = collection.schedule;
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
                                getInitials(widget.merchantName).toUpperCase(),
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
                                    sdkNotifier.setSelectedPaymentMethod(
                                      method: PaymentMethod.savedBank,
                                    );

                                    sdkNotifier.setSelectedBankOption(
                                      bankOption: bank,
                                    );
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
                                        color: (sdkNotifier
                                                        .selectedPaymentMethod ==
                                                    PaymentMethod.savedBank &&
                                                selectedBankID == bank.bankId)
                                            ? MonaColors.primaryBlue
                                            : MonaColors.bgGrey,
                                      ),
                                    ),
                                    child: Center(
                                      child: CircleAvatar(
                                        radius: context.w(6),
                                        backgroundColor: (sdkNotifier
                                                        .selectedPaymentMethod ==
                                                    PaymentMethod.savedBank &&
                                                selectedBankID == bank.bankId)
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
