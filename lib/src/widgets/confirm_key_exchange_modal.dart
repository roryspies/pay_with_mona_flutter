import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';

class ConfirmKeyExchangeModal extends StatefulWidget {
  const ConfirmKeyExchangeModal({
    super.key,
  });

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
        color: MonaColors.neutralWhite,
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
                        onTap: () {},
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
          ],
        ),
      ),
    );
  }
}
