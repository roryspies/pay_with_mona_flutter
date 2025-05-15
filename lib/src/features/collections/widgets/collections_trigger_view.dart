import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/core/events/mona_sdk_state_stream.dart';

import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/collections/widgets/collections_checkout_sheet.dart';
import 'package:pay_with_mona/src/features/collections/widgets/trigger_result_view.dart';
import 'package:pay_with_mona/src/models/colllection_response.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/formatters.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';
import 'package:pay_with_mona/src/widgets/custom_drop_down.dart';
import 'package:pay_with_mona/src/widgets/custom_text_field.dart';

class CollectionsTriggerView extends StatefulWidget {
  const CollectionsTriggerView({
    super.key,
    required this.merchantName,
    this.successMap,
  });

  final String merchantName;
  final Map<String, dynamic>? successMap;

  @override
  State<CollectionsTriggerView> createState() => _CollectionsTriggerViewState();
}

class _CollectionsTriggerViewState extends State<CollectionsTriggerView> {
  final timeFactor = TimeFactor.day.notifier;
  final sdkNotifier = MonaSDKNotifier();

  final showMore = false.notifier;

  @override
  void initState() {
    super.initState();
    sdkNotifier.addListener(_onSdktateChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sdkNotifier.sdkStateStream.listen(
        (state) {
          switch (state) {
            case MonaSDKState.idle:
              ('🎉  PayWithMonaWidget ==>> SDK is Idle').log();
              break;
            case MonaSDKState.loading:
              ('🔄 PayWithMonaWidget ==>>  SDK is Loading').log();
              break;
            case MonaSDKState.error:
              ('⛔  PayWithMonaWidget ==>> SDK Has Errors').log();
              break;
            case MonaSDKState.success:
              ('👍  PayWithMonaWidget ==>> SDK is in Success state').log();
              break;
            default:
              ('🏫  PayWithMonaWidget ==>> $state').log();
              break;
          }
        },
        onError: (err) {
          ('Error from transactionStateStream: $err').log();
        },
      );
    });
  }

  @override
  void dispose() {
    showMore.dispose();
    super.dispose();
  }

  void _onSdktateChange() => setState(() {});

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void nav() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TriggerResultView(successMap: widget.successMap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final response = widget.successMap;
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
                height: context.h(47),
                width: double.infinity,
                color: MonaColors.neutralWhite,
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.keyboard_arrow_left,
                        color: Colors.black,
                        size: context.sp(30),
                      ),
                    ),
                    Text(
                      'Collections scheduled',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: context.sp(16),
                        color: Colors.black,
                      ),
                    ),
                    Opacity(
                      opacity: 0,
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.keyboard_arrow_left,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              //! table in this container
              Container(
                width: double.infinity,
                margin:
                    EdgeInsets.symmetric(horizontal: context.w(16)).copyWith(
                  bottom: context.h(22),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(20),
                  vertical: context.h(20),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: MonaColors.neutralWhite,
                ),
                child: Column(
                  children: [
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
                            Expanded(child: Text('₦${_formatAmount(amount)}')),
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
                  ],
                ),
              ),
              [timeFactor].multiSync(builder: (context, child) {
                return Container(
                  width: double.infinity,
                  margin:
                      EdgeInsets.symmetric(horizontal: context.w(16)).copyWith(
                    bottom: context.h(40),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(20),
                    vertical: context.h(20),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: MonaColors.neutralWhite,
                  ),
                  child: Column(
                    children: [
                      CustomDropDownn(
                        title: '1 minute is equal to',
                        items: timeFactors,
                        value: timeFactor.value,
                        onChanged: (value) {
                          timeFactor.value = value;
                        },
                      ),
                      context.sbH(10.5),
                      sdkNotifier.state == MonaSDKState.loading
                          ? Align(
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                color: MonaColors.primaryBlue,
                              ),
                            )
                          : CustomButton(
                              onTap: () {
                                sdkNotifier
                                  ..setCallingBuildContext(context: context)
                                  ..triggerCollection(
                                      merchantId: '67e41f884126830aded0b43c',
                                      timeFactor: switch (timeFactor.value) {
                                        TimeFactor.day => 1,
                                        TimeFactor.week => 7,
                                        TimeFactor.month => 30,
                                      },
                                      onSuccess: (p0) async {
                                        showSnackBar(
                                            'Collection triggered successfully');

                                        await Future.delayed(
                                            Duration(seconds: 2));

                                        nav();
                                      },
                                      onError: (message) {
                                        showSnackBar(message);
                                      });
                              },
                              label: 'Continue',
                            ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentScheduleTextController {
  final int index;
  final TextEditingController paymentTextcontroller;
  final TextEditingController dateTextcontroller;

  PaymentScheduleTextController({
    required this.index,
    required this.paymentTextcontroller,
    required this.dateTextcontroller,
  });

  PaymentScheduleTextController copyWith({
    int? index,
    TextEditingController? paymentTextcontroller,
    TextEditingController? dateTextcontroller,
  }) {
    return PaymentScheduleTextController(
      index: index ?? this.index,
      paymentTextcontroller:
          paymentTextcontroller ?? this.paymentTextcontroller,
      dateTextcontroller: dateTextcontroller ?? this.dateTextcontroller,
    );
  }
}

String? convertToIsoDate(dynamic input) {
  try {
    if (input is String) {
      // Try to parse as "HH:mm dd/MM/yy" format first
      try {
        final parsedDateTime = DateFormat('HH:mm dd/MM/yy').parseStrict(input);
        return parsedDateTime
            .toIso8601String(); // Return full ISO string with time
      } catch (_) {
        // Fall back to original format "dd/MM/yyyy" if first format fails
        final parsedDate = DateFormat('dd/MM/yyyy').parseStrict(input);
        return parsedDate.toIso8601String().split('T').first;
      }
    } else if (input is DateTime) {
      return input.toIso8601String();
    } else {
      throw FormatException('Unsupported type');
    }
  } catch (e) {
    print('Error converting date: $e');
    return null;
  }
}

String _formatAmount(dynamic amount) {
  final value = double.tryParse(amount.toString()) ?? 0;
  final formatter = NumberFormat("#,##0", "en_NG");
  return formatter.format(value);
}
