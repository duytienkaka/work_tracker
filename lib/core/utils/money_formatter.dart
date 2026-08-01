import 'package:intl/intl.dart';

class MoneyFormatter {
  MoneyFormatter._();

  static final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  static String format(num value) {
    return "${_formatter.format(value)} đ";
  }
}
