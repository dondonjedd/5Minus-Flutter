import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'text_input.dart';

enum TextInputEnum { email, field, phone, password }

enum TextInputStyle {
  line,
  fill,
  outline,
}

class TextInputBuildContext {
  final TextInputEnum textInputType;
  TextEditingController? controller;
  String? label;
  String? hint;
  String? prefixText;
  Widget? prefixIcon;
  String? suffixText;
  Widget? suffixIcon;
  int? maxLine;
  int? minLine;
  String? regexFormat;
  Color? backgroundColor;
  bool? enableSpacing;
  bool? enableViewOnly;
  bool? enableObscurity;
  bool? enableAutocorrect;
  bool? enablePrefixIconConstraint;
  bool? enableSuffixIconConstraint;
  void Function(String?)? onEdit;
  void Function(String?)? onSubmit;
  String? Function(String?)? onValidate;
  TextCapitalization? capitalization;
  TextInputAction? action;
  TextInputStyle? style;
  TextInputType? type;
  String? actionSelect;
  String? actionClear;

  TextInputBuildContext({
    required this.textInputType,
    this.action,
    this.actionClear,
    this.actionSelect,
    this.backgroundColor,
    this.capitalization,
    this.controller,
    this.enableAutocorrect,
    this.enableObscurity,
    this.enablePrefixIconConstraint,
    this.enableSpacing,
    this.enableSuffixIconConstraint,
    this.enableViewOnly,
    this.hint,
    this.label,
    this.maxLine,
    this.minLine,
    this.onEdit,
    this.onSubmit,
    this.onValidate,
    this.prefixIcon,
    this.prefixText,
    this.regexFormat,
    this.style,
    this.suffixIcon,
    this.suffixText,
    this.type,
  });
}

class TextInputFactory {
  TextInputFactory._();

  static TextInput createTextInput(TextInputBuildContext buildContext) {
    TextInput result = DefaultTextInput();

    switch (buildContext.textInputType) {
      case TextInputEnum.email:
        result = EmailInput(
            action: buildContext.action,
            backgroundColor: buildContext.backgroundColor,
            controller: buildContext.controller,
            enablePrefixIconConstraint: buildContext.enablePrefixIconConstraint,
            enableSpacing: buildContext.enableSpacing,
            enableSuffixIconConstraint: buildContext.enableSuffixIconConstraint,
            enableViewOnly: buildContext.enableViewOnly,
            hint: buildContext.hint,
            label: buildContext.label,
            onEdit: buildContext.onEdit,
            onSubmit: buildContext.onSubmit,
            onValidate: buildContext.onValidate,
            prefixIcon: buildContext.prefixIcon,
            prefixText: buildContext.prefixText,
            style: buildContext.style,
            suffixIcon: buildContext.suffixIcon,
            suffixText: buildContext.suffixText);
        break;
      case TextInputEnum.field:
        result = FieldInput();
        break;
      case TextInputEnum.phone:
        result = PhoneInput();
        break;
      case TextInputEnum.password:
        result = PasswordInput(
            actionClear: buildContext.actionClear,
            actionSelect: buildContext.actionSelect,
            backgroundColor: buildContext.backgroundColor,
            controller: buildContext.controller,
            enableSpacing: buildContext.enableSpacing,
            enableViewOnly: buildContext.enableViewOnly,
            hint: buildContext.hint,
            label: buildContext.label,
            onEdit: buildContext.onEdit,
            onSubmit: buildContext.onSubmit,
            onValidate: buildContext.onValidate,
            prefixIcon: buildContext.prefixIcon,
            prefixText: buildContext.prefixText,
            style: buildContext.style);
        break;
    }

    return result;
  }

  TextInput result = DefaultTextInput();
}
