import 'dart:async';

import 'package:flutter/material.dart';

import '../component/template/dialog_template_view.dart';
import '../data/variable/color_variable_data.dart';

class DialogUtility {
  static DialogUtility? _instance;

  DialogUtility._internal() {
    _instance = this;
  }

  bool _isAlertShowing = false;
  factory DialogUtility() => _instance ?? DialogUtility._internal();
  Future<bool> showSuccess(final BuildContext context,
      {final String? title,
      final String? message,
      final Widget? layout,
      final EdgeInsets? layoutPadding,
      final String? positiveTitle,
      final Color? color,
      final Color? onColor,
      final bool dismissible = false,
      final Widget? positiveWidget,
      final bool enablePositiveDismissal = true,
      final Function()? onTapActionPositive}) async {
    if (_isAlertShowing == true) {
      return true;
    }
    _isAlertShowing = true;
    bool? res = await _showPopup(
      context,
      dismissible: dismissible,
      widget: DialogTemplateView(
        title: title ?? 'Alert',
        titleColor: color,
        message: message,
        messageColor: color,
        layout: layout,
        layoutPadding: layoutPadding,
        positiveWidget: positiveWidget,
        actionPositiveTitle: positiveTitle ?? 'Ok',
        actionPositiveBackgroundColor: color,
        actionPositiveForegroundColor: onColor,
        enablePositiveDismissal: enablePositiveDismissal,
        onTapActionPositive: onTapActionPositive,
        enablePositiveAction: true,
      ),
    );

    _isAlertShowing = false;
    return res == true;
  }

  bool _isErrorShowing = false;
  Future<bool> showError(final BuildContext context,
      {final String? title,
      final String? message,
      final Widget? layout,
      final EdgeInsets? layoutPadding,
      final String? positiveTitle,
      final Color? color,
      final Color? actionPositiveForegroundColor,
      final Color? actionPositiveBackgroundColor,
      final String? type,
      final bool enableDismissal = true,
      final Function()? onTapActionPositive}) async {
    if (_isErrorShowing == true) {
      return true;
    }

    _isErrorShowing = true;
    final res = await _showPopup(
          context,
          dismissible: false,
          widget: DialogTemplateView(
            title: title ?? 'Error',
            titleColor: color,
            message: message,
            messageColor: color,
            layout: layout,
            layoutPadding: layoutPadding,
            actionPositiveTitle: type == '3' ? 'OK' : positiveTitle ?? 'Dismiss',
            actionPositiveBackgroundColor: actionPositiveBackgroundColor ?? ColorVariableData.light.error,
            actionPositiveForegroundColor: actionPositiveForegroundColor ?? ColorVariableData.light.onError,
            onTapActionPositive: onTapActionPositive,
            enablePositiveDismissal: enableDismissal,
            enablePositiveAction: true,
          ),
        ) ==
        true;

    _isErrorShowing = false;
    return res;
  }

  Future<bool> showConfirm(
    final BuildContext context, {
    final String? title,
    final String? message,
    final Widget? layout,
    final EdgeInsets? layoutPadding,
    final String? positiveTitle,
    final String? negativeTitle,
    final Color? positiveTextColor,
    final Color? titleColor,
    final Color? messageColor,
    final Color? onColor,
    final bool enableDismissalPositive = true,
    final bool enableDismissalNegative = true,
    final bool enableNegativeAction = true,
    final void Function()? onPressedPositive,
    final void Function()? onPressedNegative,
  }) async {
    return await _showPopup(
          context,
          widget: DialogTemplateView(
            title: title ?? 'Confirm',
            titleColor: titleColor,
            message: message,
            messageColor: messageColor,
            layout: layout,
            layoutPadding: layoutPadding,
            actionPositiveTitle: positiveTitle ?? 'Yes, Confirm',
            actionPositiveBackgroundColor: positiveTextColor ?? Theme.of(context).colorScheme.primary,
            actionPositiveForegroundColor: onColor ?? Theme.of(context).colorScheme.onPrimary,
            actionNegativeTitle: negativeTitle ?? 'No, Cancel',
            actionNegativeForegroundColor: Theme.of(context).colorScheme.error,
            enablePositiveAction: true,
            enableNegativeAction: enableNegativeAction,
            enablePositiveDismissal: enableDismissalPositive,
            enableNegativeDismissal: enableDismissalNegative,
            onTapActionPositive: onPressedPositive,
            onTapActionNegative: onPressedNegative,
          ),
        ) ==
        true;
  }

  Future<int?> showOptionSelector(
    final BuildContext context, {
    required final String? title,
    final String? message,
    final int? selectedOptionPosition,
    required final List<String?> optionList,
  }) async {
    final itemList = <Widget>[];

    for (int i = 0; i < optionList.length; i++) {
      itemList.add(RadioListTile(
        value: selectedOptionPosition == i,
        groupValue: true,
        title: Text(optionList[i] ?? ''),
        onChanged: (_) {
          Navigator.pop(context, i);
        },
      ));
    }

    final selectedPosition = await _showPopup(
      context,
      widget: DialogTemplateView(
        title: title ?? '',
        message: message,
        layoutPadding: const EdgeInsets.symmetric(
          vertical: 6,
        ),
        layout: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: itemList,
        ),
      ),
    );

    if (selectedPosition is int) return selectedPosition;

    return null;
  }

  void showMessage(
    final BuildContext context, {
    required final String? message,
    final Duration duration = const Duration(
      milliseconds: 750,
    ),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message ?? ''),
      duration: duration,
    ));
  }

  /// [showDateSelector] Info
  /// [selectedDate] This highlights the selected date
  /// [currentDate] This outlined the preset/default date
  /// [startDate] This determine first available date for user to pick from
  /// [lastDate] This determine last available date for user to pick from
  /// [lastDate] This determine last available date for user to pick from
  Future<DateTime?> showDateSelector(
    final BuildContext context, {
    final String? title,
    final DateTime? selectedDate,
    final DateTime? currentDate,
    final DateTime? firstDate,
    final DateTime? lastDate,
  }) {
    return showDatePicker(
      context: context,
      helpText: title,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? DateTime(2150),
      currentDate: currentDate,
    );
  }

  /// [showTimerSelector] Info
  /// [selectedTime] This highlights the selected time
  Future<TimeOfDay?> showTimerSelector(
    final BuildContext context, {
    final TimeOfDay? selectedTime,
  }) {
    return showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
  }

  Future<dynamic> _showPopup(
    final BuildContext context, {
    required final Widget widget,
    final bool dismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) {
        if (!dismissible) {
          return PopScope(
            canPop: dismissible,
            child: widget,
          );
        } else {
          return widget;
        }
      },
    );
  }
}
