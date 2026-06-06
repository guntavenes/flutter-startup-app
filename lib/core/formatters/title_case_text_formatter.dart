import 'package:flutter/services.dart';

class TitleCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formattedText = _toTitleCase(newValue.text);

    return TextEditingValue(text: formattedText, selection: newValue.selection);
  }

  String _toTitleCase(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return word;
          }

          final firstLetter = word[0].toUpperCase();
          final remainingLetters = word.length == 1
              ? ''
              : word.substring(1).toLowerCase();

          return '$firstLetter$remainingLetters';
        })
        .join(' ');
  }
}
