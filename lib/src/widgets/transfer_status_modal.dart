// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/secured_by_mona.dart';

class TransferStatusModal extends StatelessWidget {
  const TransferStatusModal({super.key});

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
                child: Image.asset(
                  "lagos_city".png,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),

            ///
            context.sbH(8),

            ///
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MonaColors.neutralWhite,
                borderRadius: BorderRadius.circular(
                  8.0,
                ),
              ),
              child: Column(
                children: [
                  ///
                  Text(
                    "Hang Tight, We're On It!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MonaColors.textHeading,
                    ),
                  ),

                  context.sbH(8),

                  Text(
                    "Your transfer is on the way—we’ll confirm as soon as it lands.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: MonaColors.textBody,
                    ),
                  ),

                  context.sbH(8),

                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 8,
                        decoration: BoxDecoration(
                          color: MonaColors.successColour,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      ///
                      context.sbW(4),

                      // Sent icon
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          context.sbH(16),
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: MonaColors.successColour,
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          context.sbH(4),
                          Text("Sent"),
                        ],
                      ),

                      context.sbW(4),

                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: MonaColors.successColour.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),

                      context.sbW(4),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          context.sbH(16),
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: MonaColors.successColour,
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          context.sbH(4),
                          Text("Received"),
                        ],
                      ),

                      context.sbW(4),

                      Container(
                        width: 48,
                        height: 8,
                        decoration: BoxDecoration(
                          color: MonaColors.successColour.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),

                  context.sbH(8),
                ],
              ),
            ),

            ///
            context.sbH(8),

            ///
            SecuredByMona(),
          ],
        ),
      ),
    );
  }
}
