class ForexBalance {
  final String assetCategory;

  /// This is the base (account) currency.
  ///
  /// See [description] for an entry's currency code.
  final String currency;
  final String description;
  final double quantity;
  final double costPrice;
//  TODO: field Cost Basis in {BASE_CURRENCY}
  final double closePrice;
//  TODO: field Value in {BASE_CURRENCY}
//  TODO: field Value in {BASE_CURRENCY}
//  TODO: field Unrealized P/L in {BASE_CURRENCY}
  final String code;

  ForexBalance(this.assetCategory, this.currency, this.description,
      this.quantity, this.costPrice, this.closePrice, this.code);

  factory ForexBalance.fromMap(Map<String, dynamic> map) {
    return ForexBalance(
      map['assetCategory'] as String,
      map['currency'] as String,
      map['description'] as String,
      (map['quantity'] as num).toDouble(),
      (map['costPrice'] as num).toDouble(),
      (map['closePrice'] as num).toDouble(),
      map['code'] as String,
    );
  }

  @override
  String toString() {
    return 'ForexBalance(assetCategory: $assetCategory, currency: $currency, '
        'description: $description, quantity: $quantity, costPrice: $costPrice, '
        'closePrice: $closePrice, code: $code)';
  }
}
