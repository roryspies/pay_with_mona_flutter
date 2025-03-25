import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/utils/custom_text_field.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/my_icon.dart';
import 'package:pay_with_mona/src/utils/responsive_scaffold.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/views/review_and_pay_view.dart';

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
    return ResponsiveScaffold(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
        ),
        backgroundColor: MonaColors.bgGrey,
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(context.w(16)),
            width: double.infinity,
            decoration: BoxDecoration(
              color: MonaColors.neutralWhite,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoCard(),
                context.sbH(24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(16)),
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
                      ),
                      CustomTextField(
                        title: 'Middle Name (Optional)',
                        controller: _middleNameController,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {},
                        ),
                      ),
                      CustomTextField(
                        title: 'Last Name',
                        controller: _lastNameController,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {},
                        ),
                      ),
                      CustomTextField(
                        title: 'Date of Birth',
                        controller: _dobController,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {},
                        ),
                      ),
                      CustomTextField(
                        title: 'BVN',
                        controller: _bvnController,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {},
                        ),
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
                ),
                context.sbH(30),
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CredPal provided this information",
            style: TextStyle(
              fontSize: context.sp(14),
              fontWeight: FontWeight.w600,
              color: MonaColors.textHeading,
            ),
          ),
          context.sbH(2),
          Text(
            "Please validate this information for accuracy. It needs to match your BVN linked data",
            style: TextStyle(
              color: MonaColors.textBody,
              fontSize: context.sp(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: MonaColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReviewAndPayView()),
          );
        },
        child: Text(
          "Continue",
          style: TextStyle(
            fontSize: context.sp(14),
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
