// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';

class ConfirmKeyExchangeModal extends StatefulWidget {
  const ConfirmKeyExchangeModal({
    super.key,
    //required this.userImageURL,
  });

  //final String userImageURL;

  @override
  State<ConfirmKeyExchangeModal> createState() =>
      _ConfirmKeyExchangeModalState();
}

class _ConfirmKeyExchangeModalState extends State<ConfirmKeyExchangeModal> {
  final _sdkNotifier = MonaSDKNotifier();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _sdkNotifier
          ..authStateStream.listen(
            (state) async {
              switch (state) {
                case AuthState.performingLogin:
                  ('🔄 ConfirmKeyExchangeModal ==>>  SDK is Loading').log();

                  if (mounted) setState(() => isLoading = true);

                  break;
                default:
                  if (mounted) setState(() => isLoading = false);

                  break;
              }
            },
            onError: (err) {
              ('Error from ConfirmKeyExchangeModal ::authStateStream: $err')
                  .log();
            },
          )
          ..sdkStateStream.listen(
            (state) async {
              switch (state) {
                case MonaSDKState.loading:
                  ('🔄 ConfirmKeyExchangeModal ==>>  SDK is Loading').log();

                  if (mounted) setState(() => isLoading = true);

                  break;
                default:
                  if (mounted) setState(() => isLoading = false);

                  break;
              }
            },
            onError: (err) {
              ('Error from ConfirmKeyExchangeModal ::: sdkStateStream: $err')
                  .log();
            },
          );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(8),
        ),
        color: MonaColors.bgGrey,
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 40,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  color: MonaColors.primaryBlue,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        "lagos_city".png,
                        fit: BoxFit.fitWidth,
                      ),
                    ),

                    ///
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop(false);
                        },
                        child: CircleAvatar(
                          backgroundColor:
                              MonaColors.neutralWhite.withOpacity(0.2),
                          radius: 12,
                          child: Icon(
                            Icons.close,
                            color: MonaColors.textHeading,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ///
            context.sbH(8.0),

            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MonaColors.neutralWhite,
                borderRadius: BorderRadius.circular(8),
              ),

              ///
              child: Column(
                children: [
                  ///
                  context.sbH(16.0),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            MonaColors.primaryBlue.withOpacity(0.1),
                        child: Image.asset(
                          "logo".png,
                        ),
                      ),
                      context.sbW(16.0),
                      SvgPicture.asset(
                        "key_enrolment_check_mark".svg,
                      ),
                      context.sbW(16.0),
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: MonaColors.primaryBlue,
                        child: Text(
                          "NG",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: MonaColors.neutralWhite,
                          ),
                        ),
                      ),
                    ],
                  ),

                  ///
                  context.sbH(16.0),

                  Text(
                    "One Last Thing! ",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  ///
                  context.sbH(8.0),
                  Text(
                    "Set up biometrics for faster, one-tap \npayments — every time you check out.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: MonaColors.textBody,
                    ),
                  ),

                  ///
                  context.sbH(16.0),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MonaColors.primaryBlue.withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          "vault".svg,
                        ),
                        Expanded(
                          child: Text(
                            "This is to make sure that you are the only one who can authorize payments.",
                            style: TextStyle(
                              fontSize: 12,
                              color: MonaColors.primaryBlue,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  ///
                  context.sbH(16.0),

                  ///
                  CustomButton(
                    label: "Set Up",
                    onTap: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              ),
            ),

            SecuredByMona(),

            ///
            context.sbH(8.0),
          ],
        ),
      ),
    );
  }
}
