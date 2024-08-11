import 'package:flutter/material.dart';

class DialogTemplateView extends StatelessWidget {
  final String? title;
  final Color? titleColor;
  final String? message;
  final Color? messageColor;
  final Widget? layout;
  final EdgeInsets? layoutPadding;

  final String? actionPositiveTitle;
  final Color? actionPositiveForegroundColor;
  final Color? actionPositiveBackgroundColor;

  final String? actionNegativeTitle;
  final Color? actionNegativeForegroundColor;
  final Color? actionNegativeBackgroundColor;

  final bool enablePositiveAction;
  final bool enablePositiveDismissal;

  final bool enableNegativeAction;
  final bool enableNegativeDismissal;

  final void Function()? onTapActionPositive;
  final void Function()? onTapActionNegative;

  final Widget? positiveWidget;

  const DialogTemplateView({
    super.key,
    this.title,
    this.titleColor,
    this.message,
    this.messageColor,
    this.layout,
    this.layoutPadding = const EdgeInsets.symmetric(
      horizontal: 24,
    ),
    this.actionPositiveTitle,
    this.positiveWidget,
    this.actionPositiveForegroundColor,
    this.actionPositiveBackgroundColor,
    this.actionNegativeTitle,
    this.actionNegativeForegroundColor,
    this.actionNegativeBackgroundColor,
    this.enablePositiveAction = false,
    this.enableNegativeAction = false,
    this.enablePositiveDismissal = true,
    this.enableNegativeDismissal = true,
    this.onTapActionPositive,
    this.onTapActionNegative,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title ?? 'Alert',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black),
      ),
      content: _contentLayout(),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      actions: _actionLayout(context),
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      scrollable: true,
      clipBehavior: Clip.antiAlias,
    );
  }

  Widget? _contentLayout() {
    final itemList = <Widget>[];

    if (message?.isNotEmpty == true) {
      itemList.add(Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
        ),
        child: Text(
          message ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: messageColor ?? Colors.black,
          ),
        ),
      ));
    }

    if (layout is Widget) {
      itemList.add(Padding(
        padding: layoutPadding ?? const EdgeInsets.all(0),
        child: layout,
      ));
    }

    if (itemList.isEmpty) return null;

    if (itemList.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: itemList,
      );
    } else {
      return itemList.first;
    }
  }

  List<Widget>? _actionLayout(final BuildContext context) {
    final itemList = <Widget>[];

    if (enablePositiveAction) {
      itemList.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.topCenter,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: actionPositiveForegroundColor ?? Theme.of(context).colorScheme.onPrimary,
              backgroundColor: actionPositiveBackgroundColor ?? Theme.of(context).colorScheme.primary,
            ),
            child: positiveWidget ?? Text(actionPositiveTitle ?? 'OK'),
            onPressed: () {
              if (enablePositiveDismissal) {
                Navigator.pop(context, true);
              }

              onTapActionPositive?.call();
            },
          ),
        ),
      ));
    }

    if (enableNegativeAction) {
      itemList.add(Align(
        alignment: Alignment.center,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: actionNegativeForegroundColor,
            backgroundColor: actionNegativeBackgroundColor,
          ),
          child: Text(
            actionNegativeTitle ?? 'Dismiss',
          ),
          onPressed: () {
            if (enableNegativeDismissal) {
              Navigator.pop(context, false);
            }

            onTapActionNegative?.call();
          },
        ),
      ));
    }

    if (itemList.isEmpty) return null;

    return itemList;
  }
}
