import 'package:flutter_test/flutter_test.dart';

import 'package:work_tracker/core/utils/money_formatter.dart';

void main() {
  test('formats whole numbers without unnecessary decimals', () {
    expect(MoneyFormatter.format(1000), '1.000 đ');
  });

  test('preserves non-zero decimals without rounding', () {
    expect(MoneyFormatter.format(1000.123456), '1.000,123456 đ');
  });
}
