import 'dart:async';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utility/date_time_utility.dart';

enum TextInputStyle {
  line,
  fill,
  outline,
}

class TextInputComponent extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;

  final String? prefixText;
  final Widget? prefixIcon;
  final String? suffixText;
  final Widget? suffixIcon;

  final int maxLine;
  final int minLine;

  final String? regexFormat;

  final Color? backgroundColor;

  final bool enableSpacing;
  final bool enableViewOnly;
  final bool enableObscurity;
  final bool enableAutocorrect;
  final bool enablePrefixIconConstraint;
  final bool enableSuffixIconConstraint;
  final bool autofocus;

  final void Function(String?)? onEdit;
  final void Function(String?)? onSubmit;
  final String? Function(String?)? onValidate;

  final TextCapitalization capitalization;
  final TextInputAction action;
  final TextInputStyle style;
  final TextInputType type;

  final List<TextInputFormatter>? inputFormatters;

  const TextInputComponent({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.maxLine = 1,
    this.minLine = 1,
    this.regexFormat,
    this.backgroundColor,
    this.enableSpacing = true,
    this.enableViewOnly = false,
    this.enableObscurity = false,
    this.enableAutocorrect = false,
    this.enablePrefixIconConstraint = false,
    this.enableSuffixIconConstraint = false,
    this.autofocus = false,
    this.onEdit,
    this.onSubmit,
    this.onValidate,
    this.capitalization = TextCapitalization.none,
    this.action = TextInputAction.next,
    this.style = TextInputStyle.outline,
    this.type = TextInputType.text,
    this.inputFormatters,
  });

  const TextInputComponent.name({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.maxLine = 1,
    this.minLine = 1,
    this.regexFormat,
    this.backgroundColor,
    this.enableSpacing = true,
    this.enableViewOnly = false,
    this.enablePrefixIconConstraint = false,
    this.enableSuffixIconConstraint = false,
    this.autofocus = false,
    this.onEdit,
    this.onSubmit,
    this.onValidate,
    this.action = TextInputAction.next,
    this.style = TextInputStyle.outline,
    this.inputFormatters,
  })  : capitalization = TextCapitalization.words,
        enableObscurity = false,
        enableAutocorrect = false,
        type = TextInputType.name;

  const TextInputComponent.field({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.maxLine = 6,
    this.minLine = 3,
    this.regexFormat,
    this.backgroundColor,
    this.enableSpacing = true,
    this.enableViewOnly = false,
    this.enablePrefixIconConstraint = false,
    this.enableSuffixIconConstraint = false,
    this.autofocus = false,
    this.onEdit,
    this.onValidate,
    this.suffixIcon,
    this.action = TextInputAction.newline,
    this.style = TextInputStyle.outline,
    this.inputFormatters,
  })  : capitalization = TextCapitalization.words,
        prefixIcon = null,
        prefixText = null,
        suffixText = null,
        enableObscurity = false,
        enableAutocorrect = false,
        onSubmit = null,
        type = TextInputType.name;

  const TextInputComponent.email({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.backgroundColor,
    this.enableSpacing = true,
    this.enableViewOnly = false,
    this.enablePrefixIconConstraint = false,
    this.enableSuffixIconConstraint = false,
    this.autofocus = false,
    this.onEdit,
    this.onSubmit,
    this.onValidate,
    this.action = TextInputAction.next,
    this.style = TextInputStyle.outline,
    this.inputFormatters,
  })  : regexFormat = null,
        maxLine = 1,
        minLine = 1,
        capitalization = TextCapitalization.none,
        enableObscurity = false,
        enableAutocorrect = false,
        type = TextInputType.emailAddress;

  const TextInputComponent.phone({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.backgroundColor,
    this.enableSpacing = true,
    this.enableViewOnly = false,
    this.enablePrefixIconConstraint = false,
    this.enableSuffixIconConstraint = false,
    this.autofocus = false,
    this.onEdit,
    this.onSubmit,
    this.onValidate,
    this.action = TextInputAction.next,
    this.style = TextInputStyle.outline,
    this.inputFormatters,
  })  : regexFormat = null,
        maxLine = 1,
        minLine = 1,
        capitalization = TextCapitalization.none,
        enableObscurity = false,
        enableAutocorrect = false,
        type = TextInputType.phone;

  const TextInputComponent.number({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.backgroundColor,
    this.enableSpacing = true,
    this.enableViewOnly = false,
    this.enablePrefixIconConstraint = false,
    this.enableSuffixIconConstraint = false,
    this.autofocus = false,
    this.onEdit,
    this.onSubmit,
    this.onValidate,
    this.action = TextInputAction.next,
    this.style = TextInputStyle.outline,
    this.inputFormatters,
  })  : regexFormat = r'\d',
        maxLine = 1,
        minLine = 1,
        capitalization = TextCapitalization.none,
        enableObscurity = false,
        enableAutocorrect = false,
        type = TextInputType.number;

  const TextInputComponent.decimal({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.backgroundColor,
    this.enableSpacing = true,
    this.enableViewOnly = false,
    this.enablePrefixIconConstraint = false,
    this.enableSuffixIconConstraint = false,
    this.autofocus = false,
    final int? integerSize,
    final int? fractionSize,
    final bool enableDigitSign = true,
    this.onEdit,
    this.onSubmit,
    this.onValidate,
    this.action = TextInputAction.next,
    this.style = TextInputStyle.outline,
    this.inputFormatters,
  })  : regexFormat =
            '^${enableDigitSign ? '[-,+]?' : ''}\\d${integerSize is int ? '{0,$integerSize}' : '*'}(\\.\\d${fractionSize is int ? '{0,$fractionSize}' : '*'})?',
        maxLine = 1,
        minLine = 1,
        capitalization = TextCapitalization.none,
        enableObscurity = false,
        enableAutocorrect = false,
        type = const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        );

  @override
  Widget build(BuildContext context) {
    final inputComponent = TextFormField(
      autofocus: autofocus,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 14),
      controller: controller,
      readOnly: enableViewOnly,
      obscureText: enableObscurity,
      enableInteractiveSelection: !enableViewOnly,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        backgroundColor: backgroundColor,
        prefixText: prefixText,
        prefixIcon: prefixIcon,
        suffixText: suffixText,
        suffixIcon: suffixIcon,
        enablePaddingVertical: maxLine > 1,
        enablePrefixIconConstraint: enablePrefixIconConstraint,
        enableSuffixIconConstraint: enableSuffixIconConstraint,
        brightness: Theme.of(context).brightness,
        style: style,
      ),
      maxLines: maxLine,
      minLines: minLine,
      inputFormatters: inputFormatters ?? (regexFormat?.isNotEmpty == true ? [FilteringTextInputFormatter.allow(RegExp(regexFormat ?? ''))] : null),
      textInputAction: action,
      textCapitalization: capitalization,
      keyboardType: type,
      onChanged: onEdit,
      onFieldSubmitted: onSubmit,
      validator: onValidate,
    );

    if (enableSpacing) {
      return Padding(
        padding: const EdgeInsets.only(
          bottom: 12,
        ),
        child: inputComponent,
      );
    }

    return inputComponent;
  }
}

class ActionTextInputComponent extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? actionSelect;
  final String? actionClear;

  final String? prefixText;
  final Widget? prefixIcon;

  final Color? backgroundColor;

  final bool enableViewOnly;

  final void Function(String?)? onEdit;
  final void Function(String?)? onSubmit;
  final String? Function(String?)? onValidate;
  final FutureOr<void>? Function()? onSelect;
  final FutureOr<void>? Function()? onClear;

  final TextInputStyle style;

  const ActionTextInputComponent({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.actionSelect,
    this.actionClear,
    this.prefixIcon,
    this.prefixText,
    this.backgroundColor,
    this.enableViewOnly = true,
    this.onEdit,
    this.onSubmit,
    this.onValidate,
    this.onSelect,
    this.onClear,
    this.style = TextInputStyle.outline,
  });

  @override
  Widget build(BuildContext context) {
    final actionButtonStyle = _actionButtonStyle(context);

    return TextInputComponent(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon,
      prefixText: prefixText,
      suffixIcon: AnimatedBuilder(
        animation: controller ?? TextEditingController(),
        builder: (context, child) {
          final isSelected = controller?.text.isNotEmpty == true;

          if (onClear != null && isSelected) {
            return ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus();
                await onClear?.call();
                controller?.text = '';
              },
              style: actionButtonStyle,
              child: Text(actionClear ?? 'Clear'),
            );
          } else {
            return ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus();
                await onSelect?.call();
              },
              style: actionButtonStyle,
              child: Text(actionSelect ?? 'Select'),
            );
          }
        },
      ),
      backgroundColor: backgroundColor,
      enableViewOnly: enableViewOnly,
      enableSuffixIconConstraint: style != TextInputStyle.line,
      onEdit: onEdit,
      onSubmit: onSubmit,
      onValidate: onValidate,
      style: style,
    );
  }

  ButtonStyle _actionButtonStyle(final BuildContext context) {
    if (style == TextInputStyle.line) {
      return ElevatedButton.styleFrom(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
        ),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
      );
    } else {
      return ElevatedButton.styleFrom(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(12),
          ),
        ),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
      );
    }
  }
}

class SecureTextInputComponent extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? actionSelect;
  final String? actionClear;

  final String? prefixText;
  final Widget? prefixIcon;

  final Color? backgroundColor;

  final bool enableSpacing;
  final bool enableViewOnly;

  final void Function(String?)? onEdit;
  final void Function(String?)? onSubmit;
  final String? Function(String?)? onValidate;

  final TextInputStyle style;

  const SecureTextInputComponent({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    bool isHidden = true;

    return StatefulBuilder(
      builder: (context, setState) {
        return TextInputComponent(
          controller: controller,
          label: label,
          hint: hint,
          enableSpacing: enableSpacing,
          prefixIcon: prefixIcon,
          prefixText: prefixText,
          enableObscurity: isHidden,
          suffixIcon: IconButton(
            icon: Icon(
              isHidden ? Icons.visibility : Icons.visibility_off,
              color: const Color(0XFFADADAD),
            ),
            onPressed: () {
              isHidden = !isHidden;
              setState(() {});
            },
          ),
          backgroundColor: backgroundColor,
          enableViewOnly: enableViewOnly,
          enableSuffixIconConstraint: style != TextInputStyle.line,
          onEdit: onEdit,
          onSubmit: onSubmit,
          onValidate: onValidate,
          style: style,
        );
      },
    );
  }
}

class OptionTextInputComponent extends StatelessWidget {
  final String? label;
  final String? hint;
  final int? initialValue;
  final List<String> optionList;

  final String? prefixText;
  final Widget? prefixIcon;
  final String? suffixText;
  final Widget? suffixIcon;

  final Color? backgroundColor;

  final bool enableSpacing;
  final bool enableViewOnly;
  final bool enableObscurity;
  final bool enablePrefixIconConstraint;
  final bool enableSuffixIconConstraint;

  final void Function(int)? onSelect;
  final String? Function(int?)? onValidate;

  final TextInputStyle style;

  const OptionTextInputComponent({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.optionList = const [],
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.backgroundColor,
    this.enableSpacing = false,
    this.enableViewOnly = false,
    this.enableObscurity = false,
    this.enablePrefixIconConstraint = false,
    this.enableSuffixIconConstraint = false,
    this.onSelect,
    this.onValidate,
    this.style = TextInputStyle.outline,
  });

  List<DropdownMenuItem<int>> get optionItemList {
    final itemList = <DropdownMenuItem<int>>[];

    for (int i = 0; i < optionList.length; i++) {
      itemList.add(
        DropdownMenuItem<int>(
          value: i,
          child: Text(optionList[i]),
        ),
      );
    }

    return itemList;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: initialValue,
      items: optionItemList,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        backgroundColor: backgroundColor,
        prefixText: prefixText,
        prefixIcon: prefixIcon,
        suffixText: suffixText,
        suffixIcon: suffixIcon,
        enablePaddingVertical: false,
        enablePrefixIconConstraint: enablePrefixIconConstraint,
        enableSuffixIconConstraint: enableSuffixIconConstraint,
        brightness: Theme.of(context).brightness,
        style: style,
      ),
      onChanged: (indexPosition) {
        if (indexPosition is int) {
          onSelect?.call(indexPosition);
        }
      },
      validator: onValidate,
    );
  }
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
  final double? radius,
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
      inputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(radius ?? 12),
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
      inputBorder = OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(radius ?? 12),
          ),
          borderSide: const BorderSide(color: Color(0xFFCACACA)));
      floatingLabelBehavior = FloatingLabelBehavior.auto;
      backgroundColorComponent = backgroundColor;
      break;
  }

  return InputDecoration(
    filled: backgroundColorComponent is Color,
    fillColor: backgroundColorComponent,
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    border: inputBorder,
    enabledBorder: inputBorder,
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

Widget dateTimeInput({
  final GlobalKey<FormFieldState>? key,
  final Color? backgroundColor,
  final bool enable = true,
  final String? suffixText,
  final String? hint,
  final bool? suffixIconEnabled,
  final String? Function(String?)? onValidate,
  final TextInputStyle style = TextInputStyle.outline,
  final bool enableSpacing = true,
  required TextEditingController dateInputController,
  required BuildContext context,
  final DateTime? initialDate,
  final DateTime? lastDate,
  final DateTime? firstDate,
  Function(String)? onChanged,
  final Color? borderColor,
  final double? radius,
}) {
  final component = TextFormField(
    style: const TextStyle(fontSize: 14),
    key: key,
    controller: dateInputController,
    validator: onValidate,
    readOnly: true,
    decoration: _inputDecoration(
      enablePaddingVertical: false,
      brightness: Brightness.light,
      enablePrefixIconConstraint: false,
      enableSuffixIconConstraint: false,
      label: null,
      hint: hint,
      backgroundColor: backgroundColor,
      radius: radius,
      // borderColor: borderColor,
      style: style,
      prefixIcon: null,
      prefixText: null,
      suffixIcon: suffixIconEnabled ?? false
          ? const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.calendar_today_outlined,
                color: Colors.black,
                size: 24,
              ),
            )
          : null,
      suffixText: suffixText,
    ),
    onTap: enable
        ? () async {
            DateTime now = DateTime.now();
            DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate ?? now,
                firstDate: firstDate ?? now.subtract(const Duration(days: 1096)),
                lastDate: lastDate ?? now.add(const Duration(days: 1096)));

            if (pickedDate != null) {
              String formattedDate = DateTimeUtility.formatDateSlashddMMyyyy(pickedDate);
              dateInputController.text = formattedDate; //set output date to TextField value.

              onChanged?.call(formattedDate);
              key?.currentState?.validate();
            } else {
              if (kDebugMode) {
                print("Date is not selected");
              }
            }
          }
        : null,
  );

  if (enableSpacing) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: component,
    );
  } else {
    return component;
  }
}

Widget dateRangeInput({
  final GlobalKey<FormFieldState>? key,
  final Color? backgroundColor,
  final bool enable = true,
  final String? suffixText,
  final String? hint,
  final bool? suffixIconEnabled,
  final String? Function(String?)? onValidate,
  final TextInputStyle style = TextInputStyle.outline,
  final bool enableSpacing = true,
  required TextEditingController dateInputController,
  required BuildContext context,
  final DateTime? initialStartDate,
  final DateTime? initialEndDate,
  Function(DateTime? startDate, DateTime? endDate)? onFinished,
}) {
  final component = TextFormField(
    style: const TextStyle(fontSize: 14),
    key: key,
    controller: dateInputController,
    validator: onValidate,
    readOnly: true,
    decoration: _inputDecoration(
      enablePaddingVertical: false,
      brightness: Brightness.light,
      enablePrefixIconConstraint: false,
      enableSuffixIconConstraint: false,
      label: null,
      hint: hint,
      backgroundColor: backgroundColor,
      style: style,
      prefixIcon: null,
      prefixText: null,
      suffixIcon: suffixIconEnabled ?? false
          ? const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.calendar_today_outlined,
                color: Colors.black,
                size: 24,
              ),
            )
          : null,
      suffixText: suffixText,
    ),
    onTap: enable
        ? () async {
            List<DateTime?>? pickedDates = await showDialog<List<DateTime?>>(
              context: context,
              builder: (_) {
                return Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  backgroundColor: Theme.of(context).canvasColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: RangeDatePickerDialogLayout(
                    initialEndDate: initialEndDate,
                    initialStartDate: initialStartDate,
                  ),
                );
              },
            );

            if (pickedDates != null) {
              if (pickedDates.isNotEmpty) {
                if (pickedDates.first != null) {
                  if (pickedDates.length == 1) {
                    pickedDates.add(pickedDates.first);
                  }
                  String startDate = DateTimeUtility.formatDateSlashddMMyyyy(pickedDates.first!);
                  String endDate = DateTimeUtility.formatDateSlashddMMyyyy(pickedDates[1]!);
                  dateInputController.text = '$startDate - $endDate'; //set output date to TextField value.

                  onFinished?.call(pickedDates.first, pickedDates[1]);
                  key?.currentState?.validate();
                  return;
                }
              }
            }
            dateInputController.text = ''; //set output date
            onFinished?.call(null, null);
            key?.currentState?.validate();
            if (kDebugMode) {
              print("Date is not selected");
            }
          }
        : null,
  );

  if (enableSpacing) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: component,
    );
  } else {
    return component;
  }
}

class RangeDatePickerDialogLayout extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  const RangeDatePickerDialogLayout({super.key, this.initialStartDate, this.initialEndDate});

  @override
  State<RangeDatePickerDialogLayout> createState() => _RangeDatePickerDialogLayoutState();
}

class _RangeDatePickerDialogLayoutState extends State<RangeDatePickerDialogLayout> {
  late List<DateTime?> dateTimeList;
  @override
  void initState() {
    dateTimeList = [widget.initialStartDate, widget.initialEndDate];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String dateText = 'No Dates Selected';
    if (dateTimeList.isEmpty) {
      dateText = 'No Dates Selected';
    } else {
      if (dateTimeList.first == null) {
        dateText = 'No Dates Selected';
      } else {
        if (dateTimeList.length == 1) {
          dateText = '${DateTimeUtility.formatDateSlashddMMyyyy(dateTimeList.first!)} -';
        } else if (dateTimeList.length == 2) {
          dateText = '${DateTimeUtility.formatDateSlashddMMyyyy(dateTimeList.first!)} - ${DateTimeUtility.formatDateSlashddMMyyyy(dateTimeList[1]!)}';
        }
      }
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      shrinkWrap: true,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Select Date'),
            TextButton(
                onPressed: () {
                  setState(() {
                    dateTimeList = [null, null];
                  });
                },
                child: const Text('Reset'))
          ],
        ),
        Text(
          dateText,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
        CalendarDatePicker2(
          config: CalendarDatePicker2Config(
            rangeBidirectional: true,
            calendarType: CalendarDatePicker2Type.range,
            selectableDayPredicate: (day) {
              if (dateTimeList.length >= 2) return true;

              return (day.isAfter(dateTimeList.first!.subtract(const Duration(days: 30)))) &&
                  (day.isBefore(dateTimeList.first!.add(const Duration(days: 30))));
            },
          ),
          value: dateTimeList,
          onValueChanged: (dates) {
            setState(() {
              dateTimeList = dates;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(
              width: 12,
            ),
            ElevatedButton(
              style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.onPrimary),
                  backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.primary)),
              onPressed: () {
                Navigator.of(context).pop(dateTimeList);
              },
              child: const Text('Ok'),
            ),
          ],
        )
      ],
    );
  }
}
