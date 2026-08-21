import 'package:flutter/services.dart';

class EmailFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.trim().toLowerCase();
    return newValue.copyWith(text: text);
  }
}

class PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Extract digits only
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 10 digits
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    String formatted = "";

    if (digits.length >= 1) {
      formatted = "(${digits.substring(0, digits.length.clamp(0, 3))}";
    }

    if (digits.length >= 4) {
      formatted =
      "(${digits.substring(0, 3)}) ${digits.substring(3, digits.length.clamp(3, 6))}";
    }

    if (digits.length >= 7) {
      formatted =
      "(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}";
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
