import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'text_input_factory.dart';

abstract class TextInput {
  TextEditingController? _controller;
  String? _label;
  String? _hint;
  String? _prefixText;
  Widget? _prefixIcon;
  String? _suffixText;
  Widget? _suffixIcon;
  int? _maxLine;
  int? _minLine;
  String? _regexFormat;
  Color? _backgroundColor;
  bool? _enableSpacing;
  bool? _enableViewOnly;
  bool? _enableObscurity;
  bool? _enableAutocorrect;
  bool? _enablePrefixIconConstraint;
  bool? _enableSuffixIconConstraint;
  void Function(String?)? _onEdit;
  void Function(String?)? _onSubmit;
  String? Function(String?)? _onValidate;
  TextCapitalization? _capitalization;
  TextInputAction? _action;
  TextInputStyle? _style;
  TextInputType? _type;

  Widget getTextInput(BuildContext context) {
    final inputComponent = TextFormField(
      controller: _controller,
      readOnly: _enableViewOnly ?? false,
      obscureText: _enableObscurity ?? false,
      enableInteractiveSelection: _enableViewOnly != null ? (!_enableViewOnly!) : null,
      decoration: _inputDecoration(
        label: _label,
        hint: _hint,
        backgroundColor: _backgroundColor,
        prefixText: _prefixText,
        prefixIcon: _prefixIcon,
        suffixText: _suffixText,
        suffixIcon: _suffixIcon,
        enablePaddingVertical: _maxLine != null ? _maxLine! > 1 : true,
        enablePrefixIconConstraint: _enablePrefixIconConstraint ?? false,
        enableSuffixIconConstraint: _enableSuffixIconConstraint ?? false,
        brightness: Theme.of(context).brightness,
        style: _style = TextInputStyle.fill,
      ),
      maxLines: _maxLine,
      minLines: _minLine,
      inputFormatters: _regexFormat?.isNotEmpty == true ? [FilteringTextInputFormatter.allow(RegExp(_regexFormat ?? ''))] : null,
      textInputAction: _action,
      textCapitalization: _capitalization ?? TextCapitalization.none,
      keyboardType: _type,
      onChanged: _onEdit,
      onFieldSubmitted: _onSubmit,
      validator: _onValidate,
    );

    if (_enableSpacing ?? false) {
      return Padding(
        padding: const EdgeInsets.only(
          bottom: 12,
        ),
        child: inputComponent,
      );
    }

    return inputComponent;
  }

  InputDecoration _inputDecoration({
    required final String? label,
    required final String? hint,
    required final Color? backgroundColor,
    required final String? prefixText,
    required final Widget? prefixIcon,
    required final String? suffixText,
    required final Widget? suffixIcon,
    required final bool enablePaddingVertical,
    required final bool enablePrefixIconConstraint,
    required final bool enableSuffixIconConstraint,
    required final Brightness brightness,
    required final TextInputStyle style,
  }) {
    final EdgeInsets padding;
    final InputBorder inputBorder;
    final FloatingLabelBehavior floatingLabelBehavior;
    final Color? backgroundColorComponent;

    switch (style) {
      case TextInputStyle.line:
        padding = EdgeInsets.zero;
        inputBorder = const UnderlineInputBorder();
        floatingLabelBehavior = FloatingLabelBehavior.auto;
        backgroundColorComponent = backgroundColor;
        break;
      case TextInputStyle.fill:
        padding = enablePaddingVertical
            ? const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              )
            : const EdgeInsets.symmetric(
                horizontal: 12,
              );
        inputBorder = const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
          borderSide: BorderSide.none,
        );
        floatingLabelBehavior = FloatingLabelBehavior.never;
        backgroundColorComponent = backgroundColor ?? (brightness == Brightness.light ? const Color(0xFFEEEEEE) : const Color(0x61000000));
        break;
      case TextInputStyle.outline:
        padding = enablePaddingVertical
            ? const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              )
            : const EdgeInsets.symmetric(
                horizontal: 12,
              );
        inputBorder = const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
        );
        floatingLabelBehavior = FloatingLabelBehavior.auto;
        backgroundColorComponent = backgroundColor;
        break;
    }

    return InputDecoration(
      filled: backgroundColorComponent is Color,
      fillColor: backgroundColorComponent,
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFDADADA)),
      border: inputBorder,
      contentPadding: padding,
      floatingLabelBehavior: floatingLabelBehavior,
      prefixIcon: prefixIcon == null
          ? null
          : enablePrefixIconConstraint
              ? prefixIcon
              : UnconstrainedBox(
                  child: prefixIcon,
                ),
      prefixText: prefixText,
      suffixText: suffixText,
      suffixIcon: suffixIcon == null
          ? null
          : enableSuffixIconConstraint
              ? suffixIcon
              : UnconstrainedBox(
                  child: suffixIcon,
                ),
      alignLabelWithHint: true,
      errorMaxLines: 3,
    );
  }
}

class DefaultTextInput extends TextInput {
  DefaultTextInput();
  @override
  Widget getTextInput(BuildContext context) {
    return TextFormField();
  }
}

class EmailInput extends TextInput {
  EmailInput({
    TextEditingController? controller,
    String? label,
    String? hint,
    Widget? prefixIcon,
    String? prefixText,
    Widget? suffixIcon,
    String? suffixText,
    Color? backgroundColor,
    bool? enableSpacing = true,
    bool? enableViewOnly = false,
    bool? enablePrefixIconConstraint = false,
    bool? enableSuffixIconConstraint = false,
    void Function(String?)? onEdit,
    void Function(String?)? onSubmit,
    final String? Function(String?)? onValidate,
    TextInputAction? action = TextInputAction.next,
    TextInputStyle? style = TextInputStyle.outline,
  }) {
    _controller = controller;
    _label = label;
    _hint = hint;
    _prefixIcon = prefixIcon;
    _prefixText = prefixText;
    _suffixIcon = suffixIcon;
    _suffixText = suffixText;
    _backgroundColor = backgroundColor;
    _enableSpacing = enableSpacing;
    _enableViewOnly = enableViewOnly;
    _enablePrefixIconConstraint = enablePrefixIconConstraint;
    _enableSuffixIconConstraint = enableSuffixIconConstraint;
    _onEdit = onEdit;
    _onSubmit = onSubmit;
    _onValidate = onValidate;
    _action = action;
    _style = style;

    _regexFormat = null;
    _maxLine = 1;
    _minLine = 1;
    _capitalization = TextCapitalization.none;
    _enableObscurity = false;
    _enableAutocorrect = false;
    _type = TextInputType.emailAddress;
  }
}

class FieldInput extends TextInput {
  FieldInput();
}

class PhoneInput extends TextInput {
  PhoneInput();
}

class PasswordInput extends TextInput {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? actionSelect;
  final String? actionClear;

  final String? prefixText;
  final Widget? prefixIcon;

  final Color? backgroundColor;

  final bool? enableSpacing;
  final bool? enableViewOnly;

  final void Function(String?)? onEdit;
  final void Function(String?)? onSubmit;
  final String? Function(String?)? onValidate;

  final TextInputStyle? style;
  PasswordInput({
    this.controller,
    this.label,
    this.hint,
    this.actionSelect,
    this.actionClear,
    this.prefixIcon,
    this.prefixText,
    this.backgroundColor,
    this.enableSpacing = true,
    this.enableViewOnly = false,
    this.onEdit,
    this.onSubmit,
    this.onValidate,
    this.style = TextInputStyle.outline,
  }) {
    _controller = controller;
    _label = label;
    _hint = hint;
    _prefixIcon = prefixIcon;
    _prefixText = prefixText;
    _backgroundColor = backgroundColor;
    _enableSpacing = enableSpacing;
    _enableViewOnly = enableViewOnly;
    _onEdit = onEdit;
    _onSubmit = onSubmit;
    _onValidate = onValidate;
    _style = style;
  }

  @override
  Widget getTextInput(BuildContext context) {
    bool isHidden = true;
    return StatefulBuilder(
      builder: (context, setState) {
        final inputComponent = TextFormField(
          controller: _controller,
          readOnly: _enableViewOnly ?? false,
          obscureText: isHidden,
          enableInteractiveSelection: _enableViewOnly != null ? (!_enableViewOnly!) : null,
          decoration: _inputDecoration(
            label: _label,
            hint: _hint,
            backgroundColor: _backgroundColor,
            prefixText: _prefixText,
            prefixIcon: _prefixIcon,
            suffixText: _suffixText,
            suffixIcon: IconButton(
              icon: isHidden ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
              onPressed: () {
                isHidden = !isHidden;
                setState(() {});
              },
            ),
            enablePaddingVertical: _maxLine != null ? _maxLine! > 1 : true,
            enablePrefixIconConstraint: _enablePrefixIconConstraint ?? false,
            enableSuffixIconConstraint: _enableSuffixIconConstraint ?? false,
            brightness: Theme.of(context).brightness,
            style: _style ?? TextInputStyle.line,
          ),
          maxLines: 1,
          minLines: _minLine,
          inputFormatters: _regexFormat?.isNotEmpty == true ? [FilteringTextInputFormatter.allow(RegExp(_regexFormat ?? ''))] : null,
          textInputAction: _action,
          textCapitalization: _capitalization ?? TextCapitalization.none,
          keyboardType: _type,
          onChanged: _onEdit,
          onFieldSubmitted: _onSubmit,
          validator: _onValidate,
        );

        if (_enableSpacing ?? false) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: inputComponent,
          );
        }

        return inputComponent;
      },
    );
  }
}
