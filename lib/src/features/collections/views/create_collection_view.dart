import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/formatters.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';
import 'package:pay_with_mona/src/widgets/custom_drop_down.dart';
import 'package:pay_with_mona/src/widgets/custom_text_field.dart';

class CreateCollectionView extends StatefulWidget {
  const CreateCollectionView({
    super.key,
    this.merchantName,
  });

  final String? merchantName;

  @override
  State<CreateCollectionView> createState() => _CreateCollectionViewState();
}

class _CreateCollectionViewState extends State<CreateCollectionView> {
  final _merchantNameController = TextEditingController();
  final _debitLimitController = TextEditingController();
  final _expDateController = TextEditingController();
  final _referenceController = TextEditingController();
  final collectionMethod = CollectionsMethod.none.notifier;
  final subscriptionFrequency = SubscriptionFrequency.none.notifier;

  List<TextEditingController> controllers = [];

  final firstPayment = PaymentScheduleTextController(
    index: 0,
    paymentTextcontroller: TextEditingController(),
    dateTextcontroller: TextEditingController(),
  );

  List<PaymentScheduleTextController> paymentScheduleTextControllers = [];

  final showMore = false.notifier;

  @override
  void initState() {
    super.initState();
    controllers = [
      _debitLimitController,
      _merchantNameController,
      _expDateController,
      _referenceController,
    ];
    paymentScheduleTextControllers = [firstPayment];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setData();
    });
  }

  @override
  void dispose() {
    _debitLimitController.dispose();
    _merchantNameController.dispose();
    _expDateController.dispose();
    _referenceController.dispose();
    showMore.dispose();
    super.dispose();
  }

  void setData() {
    _merchantNameController.text = widget.merchantName ?? '';
  }

  void addController(
      {required PaymentScheduleTextController
          newPaymentScheduleTextController}) {
    setState(() {
      paymentScheduleTextControllers = [
        ...paymentScheduleTextControllers,
        newPaymentScheduleTextController
      ];
    });
  }

  void removeController({required int indexId}) {
    setState(() {
      paymentScheduleTextControllers = paymentScheduleTextControllers
          .where((p) => p.index != indexId)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      'Collections',
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
              [collectionMethod, subscriptionFrequency].multiSync(
                  builder: (context, child) {
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    bottom: context.h(40),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(20),
                    vertical: context.h(20),
                  ),
                  color: MonaColors.neutralWhite,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.w(12))
                            .copyWith(bottom: context.h(32)),
                        child: Column(
                          spacing: context.h(12.5),
                          children: [
                            CustomTextField(
                              title: 'Debitor',
                              controller: _merchantNameController,
                              onChanged: (value) {},
                              inputFormatters: [],
                            ),
                            CustomDropDown(
                              title: 'Type',
                              items: collectionMethods,
                              value: collectionMethod.value,
                              onChanged: (value) {
                                collectionMethod.value = value;
                              },
                            ),
                            if (collectionMethod.value !=
                                CollectionsMethod.none) ...[
                              if (collectionMethod.value ==
                                  CollectionsMethod.subscription)
                                CustomDropDown(
                                  title: 'Frequency',
                                  items: subscriptionFrequencies,
                                  value: subscriptionFrequency.value,
                                  onChanged: (value) {
                                    subscriptionFrequency.value = value;
                                  },
                                ),
                              CustomTextField(
                                title: collectionMethod.value ==
                                        CollectionsMethod.scheduled
                                    ? 'Total debit limit'
                                    : 'Amount',
                                controller: _debitLimitController,
                                onChanged: (value) {},
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {},
                                ),
                              ),
                              CustomTextField(
                                title: collectionMethod.value ==
                                        CollectionsMethod.scheduled
                                    ? 'Expiration date'
                                    : 'Start date',
                                controller: _expDateController,
                                onChanged: (value) {},
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: now,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null) {
                                      _expDateController.text =
                                          DateFormat('dd/MM/yyyy')
                                              .format(pickedDate);
                                    }
                                  },
                                ),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(10),
                                  FilteringTextInputFormatter
                                      .singleLineFormatter,
                                  DOBTextInputFormatter(),
                                ],
                              ),
                              CustomTextField(
                                title: 'Reference',
                                controller: _referenceController,
                                onChanged: (value) {},
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                            if (collectionMethod.value ==
                                CollectionsMethod.scheduled)
                              Column(
                                spacing: context.h(24),
                                children: List.generate(
                                  paymentScheduleTextControllers.length,
                                  (index) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: CustomTextField(
                                            title: 'Payment ${index + 1}',
                                            controller:
                                                paymentScheduleTextControllers[
                                                        index]
                                                    .paymentTextcontroller,
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {},
                                            suffixIcon: IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () {},
                                            ),
                                            inputFormatters: [
                                              // LengthLimitingTextInputFormatter(10),
                                              // FilteringTextInputFormatter
                                              //     .singleLineFormatter,
                                              // DOBTextInputFormatter(),
                                            ],
                                          ),
                                        ),
                                        context.sbW(21),
                                        Expanded(
                                          child: CustomTextField(
                                            title: 'Date & Time',
                                            readOnly: true,
                                            onTap: () async {
                                              final now = DateTime.now();

                                              final pickedDate =
                                                  await showDatePicker(
                                                context: context,
                                                initialDate: now,
                                                firstDate: DateTime(1900),
                                                lastDate: DateTime(2100),
                                              );

                                              if (pickedDate != null) {
                                                final pickedTime =
                                                    await showTimePicker(
                                                  context: context,
                                                  initialTime:
                                                      TimeOfDay.fromDateTime(
                                                          now),
                                                );

                                                if (pickedTime != null) {
                                                  final fullDateTime = DateTime(
                                                    pickedDate.year,
                                                    pickedDate.month,
                                                    pickedDate.day,
                                                    pickedTime.hour,
                                                    pickedTime.minute,
                                                  );

                                                  // Format: 14:00 26/10/25
                                                  paymentScheduleTextControllers[
                                                          index]
                                                      .dateTextcontroller
                                                      .text = DateFormat(
                                                          'HH:mm dd/MM/yy')
                                                      .format(fullDateTime);
                                                }
                                              }
                                            },
                                            controller:
                                                paymentScheduleTextControllers[
                                                        index]
                                                    .dateTextcontroller,
                                            onChanged: (value) {},
                                            // suffixIcon: IconButton(
                                            //   icon: Icon(Icons.edit),
                                            //   onPressed: () {},
                                            // ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                  11),
                                            ],
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        if (index > 0) ...[
                                          context.sbW(10),
                                          InkWell(
                                            onTap: () {
                                              removeController(
                                                  indexId:
                                                      paymentScheduleTextControllers[
                                                              index]
                                                          .index);
                                            },
                                            child: CircleAvatar(
                                              radius: 10,
                                              child: Icon(Icons.remove),
                                            ),
                                          )
                                        ]
                                      ],
                                    );
                                  },
                                ),
                              ),
                            if (collectionMethod.value ==
                                CollectionsMethod.scheduled)
                              context.sbH(12),
                            if (collectionMethod.value ==
                                CollectionsMethod.scheduled)
                              InkWell(
                                onTap: () {
                                  addController(
                                      newPaymentScheduleTextController:
                                          PaymentScheduleTextController(
                                    index:
                                        paymentScheduleTextControllers.length,
                                    paymentTextcontroller:
                                        TextEditingController(),
                                    dateTextcontroller: TextEditingController(),
                                  ));
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      Icons.add,
                                    ),
                                    Text(
                                      'Add payment',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: context.sp(14),
                                        color: Colors.black,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    Opacity(
                                      opacity: 0,
                                      child: Icon(
                                        Icons.add,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                      CustomButton(
                        onTap: () {},
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
