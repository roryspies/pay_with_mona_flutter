import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:example/utils/custom_text_field.dart';
import 'package:example/utils/extensions.dart';
import 'package:example/utils/formatters.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/size_config.dart';

class CustomerInfoView extends StatefulWidget {
  const CustomerInfoView({super.key});

  @override
  State<CustomerInfoView> createState() => _CustomerInfoViewState();
}

class _CustomerInfoViewState extends State<CustomerInfoView> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _bvnController = TextEditingController();

  final showInfo = false.notifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setData();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _dobController.dispose();
    _bvnController.dispose();
    showInfo.dispose();
    super.dispose();
  }

  void setData() {
    // Replace these with actual values from your backend/local storage
    _firstNameController.text = 'John';
    _middleNameController.text = 'Doe';
    _lastNameController.text = 'Smith';
    _dobController.text = '1990-01-01';
    _bvnController.text = '12345678901';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      width: double.infinity,
      decoration: BoxDecoration(
        color: MonaColors.neutralWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(),
          // context.sbH(24),
          showInfo.sync(
            builder: (context, value, child) => showInfo.value
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(16))
                        .copyWith(bottom: context.h(24)),
                    child: Column(
                      spacing: context.h(12.5),
                      children: [
                        CustomTextField(
                          title: 'First Name',
                          controller: _firstNameController,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {},
                          ),
                          inputFormatters: [CapitalizeWordsTextFormatter()],
                        ),
                        CustomTextField(
                          title: 'Middle Name (Optional)',
                          controller: _middleNameController,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {},
                          ),
                          inputFormatters: [CapitalizeWordsTextFormatter()],
                        ),
                        CustomTextField(
                          title: 'Last Name',
                          controller: _lastNameController,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {},
                          ),
                          inputFormatters: [CapitalizeWordsTextFormatter()],
                        ),
                        CustomTextField(
                          title: 'Date of Birth',
                          controller: _dobController,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {},
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                            FilteringTextInputFormatter.singleLineFormatter,
                            DOBTextInputFormatter(),
                          ],
                        ),
                        CustomTextField(
                          title: 'BVN',
                          controller: _bvnController,
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
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: CustomTextField(
                        //         title: 'Date of Birth',
                        //         controller: _dobController,
                        //         suffixIcon: IconButton(
                        //           icon: Icon(Icons.edit),
                        //           onPressed: () {},
                        //         ),
                        //       ),
                        //     ),
                        //     context.sbW(21),
                        //     Expanded(
                        //       child: CustomTextField(
                        //         title: 'BVN',
                        //         controller: _bvnController,
                        //         suffixIcon: IconButton(
                        //           icon: Icon(Icons.edit),
                        //           onPressed: () {},
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  )
                : SizedBox.shrink(),
          ),

          // context.sbH(30),
          InkWell(
            onTap: () {
              _firstNameController.clear();
              _lastNameController.clear();
              _middleNameController.clear();
              _dobController.clear();
              _bvnController.clear();
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
    );
  }

  Widget _infoCard() {
    return InkWell(
      onTap: () {
        showInfo.value = !showInfo.value;
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.w(16))
            .copyWith(bottom: context.h(24)),
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
            CircleAvatar(
              radius: context.w(12),
              child: Text(
                "5",
                style: TextStyle(
                  color: MonaColors.primaryBlue,
                  fontSize: context.sp(10),
                ),
              ),
            ),
            context.sbW(4),
            Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(
                Icons.keyboard_arrow_up,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
