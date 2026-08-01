import 'package:flutter/foundation.dart';

@immutable
class CurrencyOption {
  final String code;
  final String label;

  const CurrencyOption._(this.code, this.label);

  static const vnd = CurrencyOption._('vnd', 'VNĐ');
  static const usd = CurrencyOption._('usd', 'USD');
  static const eur = CurrencyOption._('eur', 'EUR');

  static const List<CurrencyOption> values = [vnd, usd, eur];
}
