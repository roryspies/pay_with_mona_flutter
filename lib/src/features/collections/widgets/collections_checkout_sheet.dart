import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';

import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';

class CollectionsCheckoutSheet extends StatelessWidget {
  const CollectionsCheckoutSheet({
    super.key,
    this.details,
    required this.method,
  });

  final Map<String, dynamic>? details;
  final CollectionsMethod method;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, // for keyboard safety
      child: Container(
        decoration: BoxDecoration(
          color: MonaColors.textField,
          borderRadius: BorderRadius.circular(10),
        ),
        // padding: const EdgeInsets.all(16),

        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: context.h(36),
              width: double.infinity,
              decoration: BoxDecoration(
                color: MonaColors.primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(16),
              ).copyWith(
                top: context.h(20),
                bottom: context.h(21),
              ),
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
                            SvgPicture.asset(
                              'bank'.svg,
                              height: context.h(48),
                            ),
                            SvgPicture.asset(
                              'forback'.svg,
                              height: context.h(22),
                            ),
                            CircleAvatar(
                              radius: context.w(24),
                              child: Text(
                                'NG',
                                style: TextStyle(
                                    fontSize: context.sp(10),
                                    fontWeight: FontWeight.w500,
                                    color: MonaColors.textHeading),
                              ),
                            ),
                          ],
                        ),
                        context.sbH(24),
                        Text(
                          "NGdeals wants to automate repayments",
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
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: context.w(8)),
                          child: Row(
                            children: List.generate(
                              2,
                              (index) {
                                return Flexible(
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        index == 0
                                            ? 'person'.svg
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
                                              index == 0
                                                  ? "Debitor"
                                                  : method ==
                                                          CollectionsMethod
                                                              .scheduled
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
                                              "NGdeals",
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
                                );
                              },
                            ),
                          ),
                        ),
                        context.sbH(20),
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: context.w(8)),
                          child: Row(
                            children: List.generate(
                              2,
                              (index) {
                                return Flexible(
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        index == 0
                                            ? 'money'.svg
                                            : method ==
                                                    CollectionsMethod.scheduled
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
                                              index == 0
                                                  ? method ==
                                                          CollectionsMethod
                                                              .scheduled
                                                      ? 'Total debit limit'
                                                      : 'Amount'
                                                  : method ==
                                                          CollectionsMethod
                                                              .scheduled
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
                                              "NGdeals",
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
                                );
                              },
                            ),
                          ),
                        ),
                        context.sbH(20),
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: context.w(8)),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'reference'.svg,
                                height: context.h(24),
                              ),
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
                                      "NGdeals",
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
                        CustomButton(
                          label: 'Continue to Mona',
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

// class DetailsItem {
//   const DetailsItem(
//     this.label,
//     this.description,
//   );
//   final String label;
//   final String description;
// }

// class DetailsRow extends StatelessWidget {
//   final DetailsItem feature;

//   const DetailsRow({
//     super.key,
//     required this.feature,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SvgPicture.asset(
//           feature.name.svg,
//           height: context.h(24),
//         ),
//         context.sbW(20),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             spacing: context.h(1),
//             children: [
//               Text(
//                 feature.label,
//                 style: TextStyle(
//                     fontSize: context.sp(14),
//                     fontWeight: FontWeight.w600,
//                     color: MonaColors.textHeading),
//               ),
//               Text(
//                 feature.description,
//                 style: TextStyle(
//                     fontSize: context.sp(12),
//                     fontWeight: FontWeight.w400,
//                     color: MonaColors.textBody),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// enum InfoType {
//   account('Account info'),
//   spending('Spending records');

//   const InfoType(this.label);
//   final String label;
// }

// class InfoButton extends StatelessWidget {
//   final InfoType infoType;

//   const InfoButton({
//     super.key,
//     required this.infoType,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//           vertical: context.h(8), horizontal: context.w(8)),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8F8F8),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: const Color(0xFFE0E0E0),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         spacing: context.w(4),
//         children: [
//           SvgPicture.asset(
//             infoType.name.svg,
//             height: context.h(16),
//           ),
//           Text(
//             infoType.label,
//             style: TextStyle(
//               fontSize: context.sp(12),
//               fontWeight: FontWeight.w500,
//               color: MonaColors.textBody,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
