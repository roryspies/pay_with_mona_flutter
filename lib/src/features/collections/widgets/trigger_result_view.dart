import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/core/services/collections_services.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';

class TriggerResultView extends StatelessWidget {
  const TriggerResultView({
    super.key,
    this.successMap,
  });
  final Map<String, dynamic>? successMap;

  @override
  Widget build(BuildContext context) {
    final response = successMap;
    if (response == null) {
      return const Center(child: Text('No data'));
    }

    final List<dynamic> requests = response['data']?['requests'] ?? [];

    final List<Map<String, dynamic>> scheduleEntries =
        requests.expand((request) {
      final collection = request['collection'];
      final reference = collection?['reference'] ?? 'Unknown';
      final entries =
          collection?['schedule']?['entries'] as List<dynamic>? ?? [];

      return entries.map((entry) => {
            'date': entry['date'],
            'amount': entry['amount'],
            'reference': reference,
          });
    }).toList();
    return Scaffold(
      backgroundColor: MonaColors.bgGrey,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: MonaColors.neutralWhite,
                padding: EdgeInsets.all(context.w(20)),
                child: Column(
                  spacing: context.h(4),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: SvgPicture.asset(
                        'hooray'.svg,
                        height: context.h(48),
                      ),
                    ),
                    Text(
                      "Collection triggered successfully",
                      style: TextStyle(
                        fontSize: context.sp(16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              context.sbH(10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.w(20)),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: MonaColors.neutralWhite,
                ),
                child: Column(
                  children: [
                    Text(
                      "Collections Scheduled",
                      style: TextStyle(
                        fontSize: context.sp(16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    context.sbH(24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Expanded(
                            child: Text('Amount',
                                style: TextStyle(fontWeight: FontWeight.w600))),
                        Expanded(
                            child: Text('Reference',
                                style: TextStyle(fontWeight: FontWeight.w600))),
                        Expanded(
                            child: Text('Date and Time',
                                style: TextStyle(fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    // Entries
                    ...scheduleEntries.map((entry) {
                      final dateTime =
                          DateTime.tryParse(entry['date']) ?? DateTime.now();
                      final formattedDate =
                          DateFormat("d'th' MMM yyyy").format(dateTime);
                      final formattedTime = DateFormat.jm().format(dateTime);
                      final reference = entry['reference'];
                      final amount = entry['amount'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(
                                    '₦${_formatAmount(divideBy100(amount))}')),
                            Expanded(child: Text(reference ?? '')),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(formattedDate,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    context.sbH(32),

                    //!
                    CustomButton(
                      onTap: () {
                        MonaSDKNotifier().resetSDKState();

                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      label: 'Return to home',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatAmount(dynamic amount) {
  final value = double.tryParse(amount.toString()) ?? 0;
  final formatter = NumberFormat("#,##0", "en_NG");
  return formatter.format(value);
}
