import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/responsive_scaffold.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/payment_option_tile.dart';

class ReviewAndPayView extends StatefulWidget {
  const ReviewAndPayView({super.key});

  @override
  State<ReviewAndPayView> createState() => _ReviewAndPayViewState();
}

class _ReviewAndPayViewState extends State<ReviewAndPayView> {
  final paymentOption = ''.notifier;

  @override
  void dispose() {
    paymentOption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      child: Scaffold(
        backgroundColor: MonaColors.bgGrey,
        body: Column(
          children: [
            Container(
              height: context.w(57),
              padding: EdgeInsets.all(context.w(16)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: MonaColors.neutralWhite,
              ),
            ),
            context.sbH(15),
            Container(
              padding: EdgeInsets.all(context.w(20)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: MonaColors.neutralWhite,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: context.h(12),
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: CircleAvatar(
                      radius: context.w(10),
                      backgroundColor: Colors.black,
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: context.w(12),
                      ),
                    ),
                  ),
                  Text(
                    "Review and Pay",
                    style: TextStyle(
                      fontSize: context.sp(18),
                      fontWeight: FontWeight.w700,
                      color: MonaColors.textHeading,
                    ),
                  ),
                ],
              ),
            ),
            context.sbH(8),
            Container(
              padding: EdgeInsets.all(context.w(20)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: MonaColors.neutralWhite,
              ),
              child: Column(
                spacing: context.h(32),
                children: [
                  Text(
                    "Payment Summary",
                    style: TextStyle(
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w500,
                      color: MonaColors.textHeading,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total",
                        style: TextStyle(
                          fontSize: context.sp(16),
                          fontWeight: FontWeight.w500,
                          color: MonaColors.textHeading,
                        ),
                      ),
                      Text(
                        "₦",
                        style: TextStyle(
                          fontSize: context.sp(16),
                          fontWeight: FontWeight.w500,
                          color: MonaColors.textHeading,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            context.sbH(8),
            Container(
              padding: EdgeInsets.all(context.w(20)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: MonaColors.neutralWhite,
              ),
              child: paymentOption.sync(
                builder: (context, value, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: context.h(32),
                    children: [
                      Text(
                        "Payment Summary",
                        style: TextStyle(
                          fontSize: context.sp(16),
                          fontWeight: FontWeight.w500,
                          color: MonaColors.textHeading,
                        ),
                      ),
                      Column(
                        spacing: context.h(24),
                        children: [
                          PaymentOptionTile(
                            title: "Pay by Transfer",
                            descriptiom:
                                "Pay for your order with cash on delivery",
                            icon: Icon(Icons.money),
                            type: 'transfer',
                            paymentOption: paymentOption,
                          ),
                          PaymentOptionTile(
                            title: "Pay by Card",
                            descriptiom: "Visa, Verve and Mastercard accepted",
                            icon: Icon(Icons.credit_card),
                            type: 'card',
                            paymentOption: paymentOption,
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: paymentOption.value.isEmpty
                                ? MonaColors.primaryBlue.withAlpha(100)
                                : MonaColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () async {
                            final theme = Theme.of(context);
                            await launchUrl(
                              Uri.parse(
                                  'https://pay.mona.ng/login?keyId=AWShnfEL2MhocHC_gg1XY2f7S7KcE0cXKSAteKFhOkTtj0NMs2mHiH4eSe2KaLDPz1TcZte_Q5uvApqHrqmo66c&sessionId=Kcg1YEryPr&phone=8068097731&authnOptions=%7B%22challenge%22%3A%22SMPDg1g_1K1OTaMntd4jvSD7SmPZj0vfDfV7tvdFHcY-V2aG7vX38ebyhFKf3fnwQpzM06jepPW_IDSPRBBaeKFPNQtZ6koSySzuFokWvpoeJOdSvq0p0YJ1bc9gZwhoO6Neg11onWHO0l77eaiOr0nd-ayu1IN3Fgef-87ZZu8%22%2C%22timeout%22%3A42%2C%22rpId%22%3A%22pay.mona.ng%22%2C%22userVerification%22%3A%22required%22%2C%22id%22%3A%22AWShnfEL2MhocHC_gg1XY2f7S7KcE0cXKSAteKFhOkTtj0NMs2mHiH4eSe2KaLDPz1TcZte_Q5uvApqHrqmo66c%22%2C%22user%22%3A%7B%22id%22%3A%2267daf58dc14a0ec8614e8fa6%22%2C%22displayName%22%3A%22Iteoluwakiisi+Dedeke%22%2C%22name%22%3A%22Iteoluwakiisi+Dedeke%22%7D%7D'),
                              customTabsOptions: CustomTabsOptions.partial(
                                shareState: CustomTabsShareState.off,
                                configuration: PartialCustomTabsConfiguration(
                                  initialHeight: 650,
                                  activityHeightResizeBehavior:
                                      CustomTabsActivityHeightResizeBehavior
                                          .fixed,
                                ),
                                colorSchemes: CustomTabsColorSchemes.defaults(
                                  toolbarColor: MonaColors.primaryBlue,
                                ),
                                showTitle: false,
                              ),
                              safariVCOptions:
                                  SafariViewControllerOptions.pageSheet(
                                configuration:
                                    const SheetPresentationControllerConfiguration(
                                  detents: {
                                    SheetPresentationControllerDetent.large,
                                    SheetPresentationControllerDetent.medium,
                                  },
                                  prefersScrollingExpandsWhenScrolledToEdge:
                                      true,
                                  prefersGrabberVisible: true,
                                  prefersEdgeAttachedInCompactHeight: true,
                                ),
                                preferredBarTintColor: MonaColors.primaryBlue,
                                preferredControlTintColor:
                                    theme.colorScheme.onSurface,
                                dismissButtonStyle:
                                    SafariViewControllerDismissButtonStyle
                                        .close,
                              ),
                            );
                          },
                          child: Text(
                            "Proceed to pay ",
                            style: TextStyle(
                              fontSize: context.sp(14),
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
