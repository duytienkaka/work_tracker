class MoneyFormatter {
  MoneyFormatter._();

  static String format(num value) {
    final normalized = value.toString();
    final parts = normalized.split('.');
    final integerPart = parts.first;
    final decimalPart = parts.length > 1 ? parts.last : '';

    final isNegative = integerPart.startsWith('-');
    final absoluteInteger = isNegative ? integerPart.substring(1) : integerPart;
    final groupedInteger = _groupDigits(absoluteInteger);
    final signedInteger = isNegative ? '-$groupedInteger' : groupedInteger;

    if (decimalPart.isEmpty) {
      return '$signedInteger đ';
    }

    final trimmedDecimal = decimalPart.replaceFirst(RegExp(r'0+$'), '');
    if (trimmedDecimal.isEmpty) {
      return '$signedInteger đ';
    }

    return '$signedInteger,$trimmedDecimal đ';
  }

  static String _groupDigits(String input) {
    if (input.length <= 3) {
      return input;
    }

    final buffer = StringBuffer();
    for (var index = 0; index < input.length; index++) {
      final positionFromEnd = input.length - index;
      if (index > 0 && index % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(input[positionFromEnd - 1]);
    }

    return buffer.toString().split('').reversed.join('');
  }
}
