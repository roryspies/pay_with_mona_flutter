import 'package:example/utils/extensions.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/regex.dart';
import 'package:example/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.title,
    this.height,
    this.width,
    this.padding,
    this.textFontSize,
    this.hintFontSize,
    required this.controller,
    this.style,
    this.hintText,
    this.hintStyle,
    this.prefix,
    this.initialValue,
    this.obscureText,
    this.enabled,
    this.maxLines,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.onSaved,
    this.suffixIcon,
    this.prefixIcon,
    this.borderOutline,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.isPasswordField = false,
    this.isEmailField = false,
    this.autofocus = false,
    this.maxLength,
    this.border,
    this.backgroundColor,
    this.prefixIconConstraints,
    this.contentPadding,
    this.textAlign,
    this.textDirection,
    this.suffixIconConstraints,
    this.fontWeight,
    this.filled,
    this.fillColor,
    this.focusNode,
    this.cursorColor,
    this.onTapOutside,
    this.readOnly = false,
    this.useFontFamilyHint = true,
    this.useFontFamilyText = true,
    this.borderEnabled = true,
    this.inputFormatters,
    this.onTap,
    this.onEditingComplete,
    this.prefixText,
  });

  final String? title;
  final double? padding;
  final double? height;
  final double? width;
  final double? textFontSize;
  final double? hintFontSize;

  final TextEditingController controller;
  final String? hintText;
  final String? prefixText;
  final String? initialValue;
  final bool? obscureText;
  final bool? enabled;
  final bool borderEnabled;
  final bool useFontFamilyHint;
  final bool useFontFamilyText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final Function? onSaved;
  final Widget? suffixIcon;
  final Widget? icon;
  final Widget? prefix;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final BoxBorder? border;
  final Color? backgroundColor;
  final Color? fillColor;
  final OutlineInputBorder? borderOutline;
  final OutlineInputBorder? enabledBorder;
  final OutlineInputBorder? focusedBorder;
  final OutlineInputBorder? errorBorder;
  final OutlineInputBorder? focusedErrorBorder;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final EdgeInsetsGeometry? contentPadding;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final FontWeight? fontWeight;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final Color? cursorColor;
  final bool autofocus;
  final bool? filled;
  final FocusNode? focusNode;
  final void Function(PointerDownEvent)? onTapOutside;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final bool isPasswordField;
  final bool isEmailField;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final borderColor = _errorText != null ? Colors.red : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null && widget.title!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: context.h(4)),
            child: Text(
              widget.title!,
              style: TextStyle(
                color: Color(0xFF3D3F30),
                fontWeight: FontWeight.w600,
                fontSize: context.sp(12),
              ),
            ),
          ),
        Container(
          height: widget.height ?? context.h(44),
          width: widget.width,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(4)),
            color: widget.backgroundColor ?? MonaColors.textField,
            border: Border.all(
              width: 1.5,
              color: widget.borderEnabled ? borderColor : Colors.transparent,
            ),
          ),
          child: TextFormField(
            onTap: widget.onTap,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            maxLines: widget.maxLines ?? 1,
            cursorColor: widget.cursorColor,
            textDirection: widget.textDirection ?? TextDirection.ltr,
            controller: widget.controller,
            obscureText: widget.obscureText ?? false,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            maxLength: widget.maxLength,
            textAlign: widget.textAlign ?? TextAlign.start,
            autofocus: widget.autofocus,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: [
              FilteringTextInputFormatter.deny(
                  RegExp(AppRegex.regexToRemoveEmoji)),
              if (widget.inputFormatters != null) ...widget.inputFormatters!,
            ],
            style: widget.style ??
                TextStyle(
                  fontWeight: widget.fontWeight ?? FontWeight.w400,
                  color: MonaColors.textHeading,
                  fontSize: widget.textFontSize ?? context.sp(14),
                ),
            decoration: InputDecoration(
              prefixText: widget.prefixText,
              filled: widget.filled,
              fillColor: widget.fillColor ?? MonaColors.textField,
              isDense: true,
              contentPadding: widget.contentPadding ??
                  EdgeInsets.symmetric(
                    horizontal: context.w(15),
                    vertical: 8.0,
                  ),
              hintText: widget.hintText,
              hintStyle: widget.hintStyle ??
                  TextStyle(
                    color: MonaColors.hint,
                    fontSize: widget.hintFontSize ?? context.sp(14),
                  ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              counter: SizedBox.shrink(),
            ),
            onChanged: (value) {
              widget.onChanged?.call(value);
            },
            onTapOutside: (event) => context.closeKeyboard(),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: EdgeInsets.only(top: context.h(4)),
            child: Text(
              _errorText!,
              style: TextStyle(color: Colors.red, fontSize: context.sp(12)),
            ),
          ),
      ],
    );
  }
}
