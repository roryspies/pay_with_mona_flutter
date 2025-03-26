import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/payment_option_tile.dart';

class PayWithMonaWidget extends StatefulWidget {
  const PayWithMonaWidget({super.key});

  @override
  State<PayWithMonaWidget> createState() => _PayWithMonaWidgetState();
}

class _PayWithMonaWidgetState extends State<PayWithMonaWidget> {
  final paymentOption = ''.notifier;

  @override
  void dispose() {
    paymentOption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    descriptiom: "Pay for your order with cash on delivery",
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
                          'https://pay.mona.ng/67e3f18d7adde3996e4ab593?embedding=true&embeddingUrl=http%3A%2F%2Flocalhost%3A4008%2F&method=bank&bankId='),
                      customTabsOptions: CustomTabsOptions.partial(
                        shareState: CustomTabsShareState.off,
                        configuration: PartialCustomTabsConfiguration(
                          initialHeight: 650,
                          activityHeightResizeBehavior:
                              CustomTabsActivityHeightResizeBehavior.fixed,
                        ),
                        colorSchemes: CustomTabsColorSchemes.defaults(
                          toolbarColor: MonaColors.primaryBlue,
                        ),
                        showTitle: false,
                      ),
                      safariVCOptions: SafariViewControllerOptions.pageSheet(
                        configuration:
                            const SheetPresentationControllerConfiguration(
                          detents: {
                            SheetPresentationControllerDetent.large,
                            SheetPresentationControllerDetent.medium,
                          },
                          prefersScrollingExpandsWhenScrolledToEdge: true,
                          prefersGrabberVisible: true,
                          prefersEdgeAttachedInCompactHeight: true,
                        ),
                        preferredBarTintColor: MonaColors.primaryBlue,
                        preferredControlTintColor: theme.colorScheme.onSurface,
                        dismissButtonStyle:
                            SafariViewControllerDismissButtonStyle.close,
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
    );
  }
}
