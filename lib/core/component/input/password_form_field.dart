import 'package:flutter/material.dart';

class PasswordFormField extends StatefulWidget {
  final TextEditingController passwordController;
  final String? labelText;
  const PasswordFormField({super.key, required this.passwordController, this.labelText});

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _isPasswordHidden = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
        controller: widget.passwordController,
        onTapOutside: (event) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        style: const TextStyle(color: Colors.black),
        obscureText: _isPasswordHidden,
        decoration: PasswordDecoration(
          isPasswordHidden: _isPasswordHidden,
          passwordlabelText: widget.labelText,
          onToggleEye: () {
            _isPasswordHidden = !_isPasswordHidden;
            setState(() {});
          },
        ));
  }
}

class PasswordDecoration extends InputDecoration {
  final bool isPasswordHidden;
  final String? passwordlabelText;
  final Function() onToggleEye;

  const PasswordDecoration({required this.isPasswordHidden, required this.onToggleEye, this.passwordlabelText})
      : super(labelText: passwordlabelText ?? 'Password');

  @override
  Widget? get suffixIcon => IconButton(
        icon: Icon(
          isPasswordHidden ? Icons.visibility_off : Icons.visibility,
          color: const Color(0XFFADADAD),
        ),
        onPressed: () {
          onToggleEye.call();
        },
      );
}
