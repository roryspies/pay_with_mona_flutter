import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';

class CollectionsCheckoutSheet extends StatelessWidget {
  const CollectionsCheckoutSheet({super.key});

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
                            CircleAvatar(
                              radius: context.w(28),
                              backgroundImage: AssetImage('logo'.png),
                            ),
                            SvgPicture.asset(
                              'securelink'.svg,
                              height: context.h(16),
                            ),
                            CircleAvatar(
                              radius: context.w(28),
                              backgroundImage: AssetImage('credpal'.png),
                            ),
                          ],
                        ),
                        context.sbH(10),
                        Text(
                          "CredPal uses Mona to requests for your transaction information.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w600,
                            color: MonaColors.textHeading,
                          ),
                        ),
                      ],
                    ),
                  ),
                  context.sbH(8),
                  Container(
                    padding: EdgeInsets.all(context.w(16)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HERE\'S HOW MONA HELPS',
                          style: TextStyle(
                              fontSize: context.sp(10),
                              fontWeight: FontWeight.w500,
                              color: MonaColors.textHeading),
                        ),
                        const SizedBox(height: 30),
                        ...FeatureItem.values
                            .map((feature) => [
                                  FeatureRow(
                                    feature: feature,
                                  ),
                                  if (feature != FeatureItem.values.last)
                                    context.sbH(24),
                                ])
                            .expand((element) => element),
                      ],
                    ),
                  ),
                  context.sbH(8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.w(16)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: context.h(10),
                      children: [
                        Text(
                          'REQUESTED INFORMATION',
                          style: TextStyle(
                            fontSize: context.sp(10),
                            fontWeight: FontWeight.w500,
                            color: MonaColors.textBody,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InfoButton(infoType: InfoType.account),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: InfoButton(infoType: InfoType.spending),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  context.sbH(8),
                  CustomButton(
                    label: 'Continue to Mona',
                  ),
                  context.sbH(13),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'By continuing you agree to Mona\'s',
                      style: TextStyle(
                        fontSize: context.sp(10),
                        fontWeight: FontWeight.w400,
                        color: MonaColors.textBody,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: ' Terms of Service\n',
                          style: TextStyle(
                            fontSize: context.sp(10),
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF326099),
                          ),
                        ),
                        TextSpan(
                          text:
                              'Only the account data you select will be securely shared ',
                          style: TextStyle(
                            fontSize: context.sp(10),
                            fontWeight: FontWeight.w400,
                            color: MonaColors.textBody,
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

enum FeatureItem {
  quickEasy(
      'Quick & Easy', 'New users verify once, then sharing is just one tap.'),
  securePrivate('Secure & Private',
      'Your info is encrypted and only CredPal can see it.'),
  control('You\'re in Control', 'You choose what to share—nothing more.');

  const FeatureItem(this.label, this.description);
  final String label;
  final String description;
}

class FeatureRow extends StatelessWidget {
  final FeatureItem feature;

  const FeatureRow({
    super.key,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          feature.name.svg,
          height: context.h(36),
        ),
        context.sbW(20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: context.h(1),
            children: [
              Text(
                feature.label,
                style: TextStyle(
                    fontSize: context.sp(14),
                    fontWeight: FontWeight.w600,
                    color: MonaColors.textHeading),
              ),
              Text(
                feature.description,
                style: TextStyle(
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.w400,
                    color: MonaColors.textBody),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum InfoType {
  account('Account info'),
  spending('Spending records');

  const InfoType(this.label);
  final String label;
}

class InfoButton extends StatelessWidget {
  final InfoType infoType;

  const InfoButton({
    super.key,
    required this.infoType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: context.h(8), horizontal: context.w(8)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        spacing: context.w(4),
        children: [
          SvgPicture.asset(
            infoType.name.svg,
            height: context.h(16),
          ),
          Text(
            infoType.label,
            style: TextStyle(
              fontSize: context.sp(12),
              fontWeight: FontWeight.w500,
              color: MonaColors.textBody,
            ),
          ),
        ],
      ),
    );
  }
}
