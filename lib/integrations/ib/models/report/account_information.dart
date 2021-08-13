class AccountInformation {
  final String name;
  final String account;
  final String accountType;
  final String customerType;
  final String accountCapabilities;
  final String baseCurrency;

  AccountInformation(this.name, this.account, this.accountType,
      this.customerType, this.accountCapabilities, this.baseCurrency);

  @override
  String toString() {
    return 'AccountInformation(name: $name, account: $account, '
        'accountType: $accountType, customerType: $customerType, '
        'accountCapabilities: $accountCapabilities, '
        'baseCurrency: $baseCurrency)';
  }

  factory AccountInformation.fromMap(Map<String, dynamic> map) {
    return AccountInformation(
      map['name'] as String,
      map['account'] as String,
      map['accountType'] as String,
      map['customerType'] as String,
      map['accountCapabilities'] as String,
      map['baseCurrency'] as String,
    );
  }
}
