import 'from_map.dart';
import 'operation.dart';

class DepositOrWithdrawal extends Operation {
  @override
  final String currency;
  final DateTime settleDate;
  @override
  final String description;
  @override
  final double amount;

  DepositOrWithdrawal(
      this.currency, this.settleDate, this.description, this.amount);

  factory DepositOrWithdrawal.fromMap(Map<String, dynamic> map) {
    return DepositOrWithdrawal(
      map['currency'] as String,
      map.requireDateTime('settleDate'),
      map['description'] as String,
      map.requireDouble('amount'),
    );
  }

  @override
  DateTime get date => settleDate;

  @override
  String toString() {
    return 'DepositOrWithdrawal(currency: $currency, settleDate: $settleDate, '
        'description: $description, amount: $amount)';
  }
}
