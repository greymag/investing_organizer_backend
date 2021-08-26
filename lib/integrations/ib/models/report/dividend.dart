import 'from_map.dart';
import 'operation.dart';

class Dividend extends Operation {
  @override
  final String currency;
  @override
  final DateTime date;
  @override
  final String description;
  @override
  final double amount;

  Dividend(this.currency, this.date, this.description, this.amount);

  factory Dividend.fromMap(Map<String, dynamic> map) {
    return Dividend(
      map['currency'] as String,
      map.requireDateTime('date'),
      map['description'] as String,
      map.requireDouble('amount'),
    );
  }

  @override
  String toString() {
    return 'Dividend(currency: $currency, date: $date, '
        'description: $description, amount: $amount)';
  }
}
