/// Open position data.
class OpenPosition {
  final String assetCategory;
  final String currency;
  final String symbol;
  final int quantity;
  final double mult;
  final double costPrice;
  final double costBasis;
  final double closePrice;
  final double value;
  final double unrealizedPL;
  final String code;

  OpenPosition(
      this.assetCategory,
      this.currency,
      this.symbol,
      this.quantity,
      this.mult,
      this.costPrice,
      this.costBasis,
      this.closePrice,
      this.value,
      this.unrealizedPL,
      this.code);

  factory OpenPosition.fromMap(Map<String, dynamic> map) {
    return OpenPosition(
      map['assetCategory'] as String,
      map['currency'] as String,
      map['symbol'] as String,
      (map['quantity'] as num).toInt(),
      (map['mult'] as num).toDouble(),
      (map['costPrice'] as num).toDouble(),
      (map['costBasis'] as num).toDouble(),
      (map['closePrice'] as num).toDouble(),
      (map['value'] as num).toDouble(),
      (map['unrealizedPL'] as num).toDouble(),
      map['code'] as String,
    );
  }

  @override
  String toString() {
    return 'OpenPosition(assetCategory: $assetCategory, currency: $currency, '
        'symbol: $symbol, quantity: $quantity, mult: $mult, '
        'costPrice: $costPrice, costBasis: $costBasis, closePrice: $closePrice, '
        'value: $value, unrealizedPL: $unrealizedPL, code: $code)';
  }
}
