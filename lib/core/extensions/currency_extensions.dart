import 'package:intl/intl.dart';

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 2,
);

extension CurrencyExtension on num {
  String toCurrency() {
    return _currencyFormatter.format(this);
  }
}
