import 'package:flutter/material.dart';

class PasswordFormField extends StatefulWidget {
  final TextEditingController passwordController;
  final String? labelText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? extraValidator;
  const PasswordFormField({super.key, required this.passwordController, this.labelText, this.textInputAction, this.extraValidator});

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
        textInputAction: widget.textInputAction,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return '${widget.labelText ?? 'Password'} is required';
          }
          return widget.extraValidator?.call(value);
        },
        decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
              color: const Color(0XFFADADAD),
            ),
            onPressed: () {
              _isPasswordHidden = !_isPasswordHidden;
              setState(() {});
            },
          ),
          labelText: widget.labelText ?? 'Password',
        ));
  }
}
