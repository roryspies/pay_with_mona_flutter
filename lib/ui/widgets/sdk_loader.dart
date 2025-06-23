// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';

class SDKLoader extends StatefulWidget {
  SDKLoader({
    super.key,
    String? loadingStateTitle,
    this.child,
  }) : loadingStateTitle = (loadingStateTitle?.isNotEmpty == true)
            ? loadingStateTitle!
            : "Processing";

  final String loadingStateTitle;
  final Widget? child;

  @override
  State<SDKLoader> createState() => _SDKLoaderState();
}

class _SDKLoaderState extends State<SDKLoader> {
  final _monaSDKNotifier = MonaSDKNotifier();
  final isLoadingValueNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _monaSDKNotifier.sdkStateStream.listen(
          (state) async {
            switch (state) {
              case MonaSDKState.loading:
                ('🔄 SDKLoader ==>>  SDK is Loading').log();
                isLoadingValueNotifier.value = true;
                break;

              default:
                ('🔄 SDKLoader ==>>  SDK is Not Loading').log();
                isLoadingValueNotifier.value = false;
                break;
            }
          },
          onError: (err) {
            ('Error from SDKLoader ::sdkStateStream: $err').log();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressIndicatorColour =
        _monaSDKNotifier.merchantBrandingDetails?.colors.primaryColour ??
            MonaColors.primaryBlue;

    return isLoadingValueNotifier.sync(
      builder: (context, isLoading, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: MonaColors.neutralWhite,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                16,
              ),
            ),
          ),
          child: AnimatedSwitcher(
            switchInCurve: Curves.fastOutSlowIn,
            switchOutCurve: Curves.fastOutSlowIn,
            duration: Duration(
              milliseconds: 50,
            ),

            ///
            child: switch (isLoading || widget.child == null) {
              true => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ///
                        context.sbH(32.0),

                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              progressIndicatorColour.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 4.0,
                              color: progressIndicatorColour,
                              strokeCap: StrokeCap.round,
                              backgroundColor:
                                  progressIndicatorColour.withOpacity(0.15),
                            ),
                          ),
                        ),

                        ///
                        context.sbH(16.0),

                        Text(
                          widget.loadingStateTitle,
                          style: TextStyle(
                            color: MonaColors.textBody,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        ///
                        context.sbH(32.0),

                        PoweredByMona()
                      ],
                    ),
                  ),
                ),

              /// ***
              false => widget.child ?? const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }
}
