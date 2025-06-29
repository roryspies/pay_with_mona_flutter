// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:example/services/customer_details_notifier.dart';
import 'package:example/utils/custom_text_field.dart';
import 'package:example/utils/extensions.dart';
import 'package:example/utils/formatters.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

class CustomerInfoView extends ConsumerStatefulWidget {
  const CustomerInfoView({super.key});

  @override
  ConsumerState<CustomerInfoView> createState() => _CustomerInfoViewState();
}

class _CustomerInfoViewState extends ConsumerState<CustomerInfoView> {
  final _phoneNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _bvnController = TextEditingController();

  List<TextEditingController> controllers = [];

  final showInfo = false.notifier;

  final sdkNotifier = MonaSDKNotifier();
  bool isSignedIn = false;
  late final StreamSubscription<AuthState> _authStateSub;

  @override
  void initState() {
    super.initState();
    _authStateSub = sdkNotifier.authStateStream.listen(
      (state) {
        if (state == AuthState.loggedOut || state == AuthState.error) {
          authText = 'Not signed in';
          isSignedIn = false;
        } else {
          authText = 'Signed in';
          isSignedIn = true;
        }

        setState(() {});
      },
    );

    controllers = [
      _phoneNumberController,
      _bvnController,
      _firstNameController,
      _middleNameController,
      _dobController,
      _lastNameController,
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setData();
    });
  }

  @override
  void dispose() {
    _authStateSub.cancel();
    _phoneNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _dobController.dispose();
    _bvnController.dispose();
    showInfo.dispose();
    super.dispose();
  }

  void setData() {}

  int getFilledFieldCount() {
    final controllers = [
      _phoneNumberController,
      _firstNameController,
      _middleNameController,
      _lastNameController,
      _dobController,
      _bvnController,
    ];

    return controllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
  }

  String authText = 'Not signed in';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
      ).copyWith(
        top: context.h(16),
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: MonaColors.neutralWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                width: 48,
                height: 48,
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.zero,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: switch (isSignedIn) {
                    true => MonaColors.primary.withOpacity(0.1),
                    false => MonaColors.bgGrey,
                  },
                ),
                child: SvgPicture.asset(
                  "account".svg,
                  color: switch (isSignedIn) {
                    true => MonaColors.primary,
                    false => null,
                  },
                ),
              ),
              context.sbW(8),
              Text(
                authText,
                style: TextStyle(
                  fontSize: context.sp(16),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  context.closeKeyboard();
                  if (showInfo.value == true) {
                    showInfo.value = !showInfo.value;
                  }

                  sdkNotifier
                    ..resetSDKState()
                    ..permanentlyClearKeys();
                },
                child: authText.toLowerCase().toString() != "signed in"
                    ? SizedBox()
                    : Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Clear Exchange Keys",
                          style: TextStyle(
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.w400,
                            color: MonaColors.textHeading,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          _infoCard(),
          showInfo.sync(
            builder: (context, value, child) => showInfo.value
                ? Padding(
                    padding: EdgeInsets.only(
                      top: context.h(10),
                      bottom: context.h(36),
                    ),
                    child: Column(
                      spacing: context.h(12.5),
                      children: [
                        CustomTextField(
                          title: 'Phone Number',
                          controller: _phoneNumberController,
                          maxLength: 11,
                          onChanged: (value) {
                            if (value.length == 11) {
                              context.closeKeyboard();
                            }
                            ref
                                .read(customerDetailsNotifierProvider.notifier)
                                .updatePhone(
                                    phoneNumber: value, context: context);
                          },
                          suffixIcon: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {},
                          ),
                          inputFormatters: [CapitalizeWordsTextFormatter()],
                          keyboardType: TextInputType.numberWithOptions(),
                        ),
                        CustomTextField(
                          title: 'First Name',
                          controller: _firstNameController,
                          onChanged: (value) {
                            ref
                                .read(customerDetailsNotifierProvider.notifier)
                                .update(firstName: value);
                          },
                          suffixIcon: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {},
                          ),
                          inputFormatters: [CapitalizeWordsTextFormatter()],
                        ),
                        CustomTextField(
                          title: 'Middle Name (Optional)',
                          controller: _middleNameController,
                          onChanged: (value) {
                            ref
                                .read(customerDetailsNotifierProvider.notifier)
                                .update(middleName: value);
                          },
                          suffixIcon: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {},
                          ),
                          inputFormatters: [CapitalizeWordsTextFormatter()],
                        ),
                        CustomTextField(
                          title: 'Last Name',
                          controller: _lastNameController,
                          onChanged: (value) {
                            ref
                                .read(customerDetailsNotifierProvider.notifier)
                                .update(lastName: value);
                          },
                          suffixIcon: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {},
                          ),
                          inputFormatters: [CapitalizeWordsTextFormatter()],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                title: 'Date of Birth',
                                controller: _dobController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  ref
                                      .read(customerDetailsNotifierProvider
                                          .notifier)
                                      .updateDOB(
                                          dateOFBirth: value, context: context);
                                },
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {},
                                ),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(10),
                                  FilteringTextInputFormatter
                                      .singleLineFormatter,
                                  DOBTextInputFormatter(),
                                ],
                              ),
                            ),
                            context.sbW(21),
                            Expanded(
                              child: CustomTextField(
                                title: 'BVN',
                                controller: _bvnController,
                                onChanged: (value) {
                                  ref
                                      .read(customerDetailsNotifierProvider
                                          .notifier)
                                      .updateBVN(bvn: value, context: context);
                                },
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {},
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        context.sbH(16),
                        InkWell(
                          onTap: () {
                            context.closeKeyboard();
                            showInfo.value = !showInfo.value;
                            _phoneNumberController.clear();
                            _firstNameController.clear();
                            _lastNameController.clear();
                            _middleNameController.clear();
                            _dobController.clear();
                            _bvnController.clear();
                            ref
                                .read(customerDetailsNotifierProvider.notifier)
                                .clear();
                          },
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Clear",
                              style: TextStyle(
                                fontSize: context.sp(14),
                                fontWeight: FontWeight.w400,
                                color: MonaColors.textHeading,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return InkWell(
      onTap: () {
        showInfo.value = !showInfo.value;
      },
      child: Padding(
        padding: EdgeInsets.symmetric().copyWith(
          bottom: context.h(14),
          top: context.h(12),
        ),
        child: Row(
          children: [
            Text(
              "Customer Info provided",
              style: TextStyle(
                fontSize: context.sp(14),
                fontWeight: FontWeight.w600,
                color: MonaColors.textHeading,
              ),
            ),
            const Spacer(),
            controllers.multiSync(
              builder: (context, child) {
                return CircleAvatar(
                  radius: context.w(12),
                  child: Text(
                    ref
                        .watch(customerDetailsNotifierProvider.notifier)
                        .getFilledFieldCount()
                        .toString(),
                    style: TextStyle(
                      color: MonaColors.primary,
                      fontSize: context.sp(10),
                    ),
                  ),
                );
              },
            ),
            context.sbW(4),
            showInfo.sync(
              builder: (context, value, child) => Icon(
                showInfo.value
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
