import 'from_map.dart';
import 'operation.dart';

class WithholdingTax extends Operation {
  @override
  final String currency;
  @override
  final DateTime date;
  @override
  final String description;
  @override
  final double amount;
  final String code;

  WithholdingTax(
      this.currency, this.date, this.description, this.amount, this.code);

  factory WithholdingTax.fromMap(Map<String, dynamic> map) {
    return WithholdingTax(
      map['currency'] as String,
      map.requireDateTime('date'),
      map['description'] as String,
      map.requireDouble('amount'),
      map['code'] as String,
    );
  }

  @override
  String toString() {
    return 'WithholdingTax(currency: $currency, date: $date, '
        'description: $description, amount: $amount, code: $code)';
  }
}
