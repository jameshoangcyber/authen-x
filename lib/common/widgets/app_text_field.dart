import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final int? maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      enabled: enabled,
      onTap: onTap,
      onChanged: onChanged,
      focusNode: focusNode,
      textInputAction: textInputAction,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        counterText: '', // Hide character counter
      ),
    );
  }
}
