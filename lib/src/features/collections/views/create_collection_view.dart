import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final collectionMethod = CollectionsMethod.none;

  List<TextEditingController> controllers = [];

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
              Container(
                width: double.infinity,
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
                            value: collectionMethod,
                            onChanged: (value) {},
                          ),
                          CustomTextField(
                            title: 'Total debit limit',
                            controller: _debitLimitController,
                            onChanged: (value) {},
                            suffixIcon: IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {},
                            ),
                          ),
                          CustomTextField(
                            title: 'Expiration date',
                            controller: _expDateController,
                            onChanged: (value) {},
                            suffixIcon: IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {},
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.singleLineFormatter,
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
                      ),
                    ),
                    CustomButton(
                      onTap: () {},
                      label: 'Continue',
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
