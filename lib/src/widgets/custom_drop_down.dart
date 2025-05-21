import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';

class CustomDropDown<T> extends StatefulWidget {
  const CustomDropDown({
    super.key,
    required this.items,
    required this.onChanged,
    required this.value,
    this.title,
    this.height,
    this.width,
    this.backgroundColor,
    this.itemBuilder,
  });

  final List<T> items;
  final T value;
  final ValueChanged<T> onChanged;
  final String? title;
  final double? height;
  final double? width;
  final Color? backgroundColor;

  /// Optional: custom item display
  final String Function(T item)? itemBuilder;

  @override
  State<CustomDropDown<T>> createState() => _CustomDropDownState<T>();
}

class _CustomDropDownState<T> extends State<CustomDropDown<T>> {
  String _displayItem(T item) {
    if (item is CollectionsMethod) {
      if (item == CollectionsMethod.none) {
        return 'Please select';
      }
      return item.name.toString().toTitleCase();
    }

    if (item is DebitType) {
      if (item == DebitType.none) {
        return 'Please select';
      }
      return '${item.name.toString().toTitleCase()} initiated';
    }

    if (item is SubscriptionFrequency) {
      if (item == SubscriptionFrequency.none) {
        return 'Please select';
      }
      return item.name.toString().toTitleCase();
    }
    return widget.itemBuilder?.call(item) ?? item.toString().toTitleCase();
  }

  @override
  Widget build(BuildContext context) {
    int selectedIndex = widget.items.indexOf(widget.value);
    bool isFirstItem = selectedIndex == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null && widget.title!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: context.h(4)),
            child: Text(
              widget.title!,
              style: TextStyle(
                color: const Color(0xFF3D3F30),
                fontWeight: FontWeight.w600,
                fontSize: context.sp(12),
              ),
            ),
          ),
        Container(
          height: widget.height ?? context.h(44),
          width: widget.width,
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(4)),
            color: widget.backgroundColor ?? MonaColors.textField,
            border: Border.all(
              width: 1.5,
              color: Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: Duration(milliseconds: 300),
                alignment:
                    isFirstItem ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  height: context.h(44),
                  width: context.w(150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.r(4)),
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                height: widget.height ?? context.h(44),
                width: widget.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final item in widget.items)
                      InkWell(
                        onTap: () {
                          widget.onChanged(item);
                        },
                        child: SizedBox(
                          height: context.h(44),
                          width: context.w(150),
                          child: Center(
                            child: Text(
                              _displayItem(item),
                              style: TextStyle(
                                fontSize: context.sp(14),
                                color: MonaColors.textHeading,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//!
class CustomDropDownn<T> extends StatefulWidget {
  const CustomDropDownn({
    super.key,
    required this.items,
    required this.onChanged,
    required this.value,
    this.title,
    this.height,
    this.width,
    this.backgroundColor,
    this.itemBuilder,
  });

  final List<T> items;
  final T value;
  final ValueChanged<T> onChanged;
  final String? title;
  final double? height;
  final double? width;
  final Color? backgroundColor;

  /// Optional: custom item display
  final String Function(T item)? itemBuilder;

  @override
  State<CustomDropDownn<T>> createState() => _CustomDropDownnState<T>();
}

class _CustomDropDownnState<T> extends State<CustomDropDownn<T>> {
  final ValueNotifier<bool> showDropdown = ValueNotifier(false);

  String _displayItem(T item) {
    if (item is CollectionsMethod) {
      if (item == CollectionsMethod.none) {
        return 'Please select';
      }
      return item.name.toString().toTitleCase();
    }

    if (item is TimeFactor) {
      return '1 ${item.name.toString()}';
    }

    if (item is SubscriptionFrequency) {
      if (item == SubscriptionFrequency.none) {
        return 'Please select';
      }
      return item.name.toString().toTitleCase();
    }
    return widget.itemBuilder?.call(item) ?? item.toString().toTitleCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null && widget.title!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: context.h(4)),
            child: Text(
              widget.title!,
              style: TextStyle(
                color: const Color(0xFF3D3F30),
                fontWeight: FontWeight.w600,
                fontSize: context.sp(12),
              ),
            ),
          ),
        ValueListenableBuilder<bool>(
          valueListenable: showDropdown,
          builder: (context, value, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: context.w(16)).copyWith(
                top: context.h(10),
                bottom: context.h(10),
              ),
              height: widget.height ??
                  (showDropdown.value
                      ? (context.h(44 + (widget.items.length * 44)))
                      : context.h(44)),
              width: widget.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.r(4)),
                color: widget.backgroundColor ?? MonaColors.textField,
                border: Border.all(
                  width: 1.5,
                  color: Colors.transparent,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => showDropdown.value = !showDropdown.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _displayItem(widget.value),
                            style: TextStyle(
                              color: MonaColors.textHeading,
                              fontWeight: FontWeight.w400,
                              fontSize: context.sp(14),
                            ),
                          ),
                          Icon(
                            showDropdown.value
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: MonaColors.textHeading,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    if (showDropdown.value) ...[
                      const SizedBox(height: 10),
                      for (final item in widget.items)
                        InkWell(
                          onTap: () {
                            widget.onChanged(item);
                            showDropdown.value = false;
                          },
                          child: SizedBox(
                            height: context.h(44),
                            child: Center(
                              child: Row(
                                children: [
                                  Text(
                                    _displayItem(item),
                                    style: TextStyle(
                                      fontSize: context.sp(13),
                                      color: MonaColors.textBody,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
