// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:example/services/customer_details_notifier.dart';
import 'package:example/services/payment_notifier.dart';
import 'package:example/utils/custom_button.dart';
import 'package:example/utils/custom_text_field.dart';
import 'package:example/utils/extensions.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/responsive_scaffold.dart';
import 'package:example/utils/size_config.dart';
import 'package:example/views/checkout_view.dart';
import 'package:example/views/customer_info_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});

  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView> {
  late PayWithMona _payWithMona;
  final paymentNotifier = PaymentNotifier();
  final _sdkNotifier = MonaSDKNotifier();
  final _amountController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _payWithMona = PayWithMona.instance;
    paymentNotifier.addListener(_onPaymentStateChange);
    _amountController.text = '20';
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _sdkNotifier.merchantBrandingDetails?.toJson().log();
        _sdkNotifier
          ..confirmLoggedInUser()
          ..sdkStateStream.listen(
            (state) async {
              switch (state) {
                case MonaSDKState.loading:
                  ('🔄 CheckoutView ==>>  SDK is Loading').log();
                  if (mounted) setState(() => isLoading = true);
                  break;
                default:
                  if (mounted) setState(() => isLoading = false);
                  break;
              }
            },
            onError: (err) {
              ('Error from transactionStateStream: $err').log();
            },
          );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    paymentNotifier.removeListener(_onPaymentStateChange);
    paymentNotifier.dispose();

    super.dispose();
  }

  void _onPaymentStateChange() {
    setState(() {});
  }

  void nav(String transactionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutView(
          transactionId: transactionId,
          amount: num.parse(_amountController.text.trim()) * 100,
        ),
      ),
    );
  }

  void showSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Payment initiation failed. Unable to get demo transactionId'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      child: Scaffold(
        backgroundColor: MonaColors.bgGrey,
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: context.h(47),
                      color: MonaColors.neutralWhite,
                    ),
                    context.sbH(13),
                    CustomerInfoView(),
                    context.sbH(15),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(20),
                        vertical: context.h(20),
                      ),
                      color: MonaColors.neutralWhite,
                      child: Column(
                        children: [
                          Row(
                            spacing: context.w(8),
                            children: [
                              CircleAvatar(
                                radius: context.w(24),
                                backgroundColor:
                                    MonaColors.primary.withOpacity(0.1),
                                backgroundImage: switch (
                                    _sdkNotifier.merchantBrandingDetails !=
                                        null) {
                                  true => NetworkImage(_sdkNotifier
                                      .merchantBrandingDetails!.image),
                                  false => AssetImage(
                                      "ng_deals_logo".png,
                                    ),
                                },
                              ),
                              Text(
                                _sdkNotifier
                                        .merchantBrandingDetails?.tradingName ??
                                    "NGDeals",
                                style: TextStyle(
                                  fontSize: context.sp(36),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          context.sbH(32),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Products",
                              style: TextStyle(
                                fontSize: context.sp(16),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          context.sbH(32),
                          Column(
                            spacing: context.h(32),
                            children: List.generate(availableProducts.length,
                                (index) {
                              Products product = availableProducts[index];
                              return Row(
                                children: [
                                  CustomButton(
                                    isLoading: product == Products.checkout
                                        ? isLoading
                                        : false,
                                    width: product == Products.checkout
                                        ? context.w(190)
                                        : context.w(335),
                                    onTap: () async {
                                      context.closeKeyboard();
                                      if (isLoading) {
                                        return;
                                      }
                                      switch (product) {
                                        case Products.checkout:
                                          _sdkNotifier.setCallingBuildContext(
                                            context: context,
                                          );

                                          final result =
                                              await Future.wait<Object?>(
                                            [
                                              _sdkNotifier.initiatePayment(
                                                tnxAmountInKobo: num.parse(
                                                      _amountController
                                                          .value.text
                                                          .trim(),
                                                    ) *
                                                    100,
                                              ),
                                              //_sdkNotifier.validatePII()
                                            ],
                                          );

                                          final bool initiateSuccessful =
                                              result[0] as bool;

                                          if (initiateSuccessful) {
                                            nav('');
                                            return;
                                          }

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Payment initiation failed. Please try again.'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );

                                          break;

                                        case Products.collections:
                                          // Navigator.of(context).push(
                                          //   MaterialPageRoute(
                                          //     builder: (_) =>
                                          //         const CreateCollectionView(
                                          //       merchantName: 'ngdeals',
                                          //     ),
                                          //   ),
                                          // );
                                          break;

                                        case Products.dataShare:
                                          _payWithMona.showDataShareSheet(
                                            context: context,
                                            firstName: 'Ada',
                                            lastName: 'Obi',
                                            dateOfBirth: DateTime(1992, 1, 1),
                                            transactionId: 'txn_1234',
                                            merchantName: '`NGDeals`',
                                            phoneNumber: '08012345678',
                                            primaryColor: Colors.deepPurple,
                                            secondaryColor: Colors.orange,
                                          );
                                          break;
                                        default:
                                      }
                                    },
                                    label: product.label,
                                  ),
                                  if (product == Products.checkout) ...[
                                    context.sbW(10),
                                    Expanded(
                                      child: CustomTextField(
                                        contentPadding: EdgeInsets.symmetric(
                                                horizontal: context.w(15))
                                            .copyWith(top: context.h(15)),
                                        height: context.h(52),
                                        controller: _amountController,
                                        prefixText: '₦',
                                        hintText: '20',
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {},
                                        ),
                                        onEditingComplete: () {
                                          context.closeKeyboard();
                                          "EDITING COMPLETE".log();
                                        },
                                        onFieldSubmitted: (p0) {
                                          context.closeKeyboard();
                                          "FIELD SUBMITTED COMPLETE".log();
                                        },
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          // ThousandsFormatter(),
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }),
                          )
                        ],
                      ),
                    ),

                    context.sbH(16),

                    /// ***
                    _payWithMona.paymentUpdateSettingsWidget(
                      transactionAmountInKobo: num.parse(
                            _amountController.value.text.trim(),
                          ) *
                          100,
                    ),
                  ],
                ),
              ),
              if (paymentNotifier.state == PaymentState.loading ||
                  ref.watch(customerDetailsNotifierProvider).isLoading)
                Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.black.withAlpha(150),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: MonaColors.primary,
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

enum Products {
  checkout('Checkout', true),
  cardPresent('Card Present', false),
  collections('Collections', true),
  dataShare('DataShare', true),
  ident('IDent', false);

  const Products(this.label, this.available);
  final String label;
  final bool available;
}

List<Products> availableProducts =
    Products.values.where((product) => product.available).toList();

String removeLeadingZero(String phoneNumber) {
  if (phoneNumber.startsWith('0') && phoneNumber.length == 11) {
    return phoneNumber.substring(1);
  }
  return phoneNumber;
}
