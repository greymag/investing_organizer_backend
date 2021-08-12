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

  @override
  String toString() {
    return 'OpenPosition(assetCategory: $assetCategory, currency: $currency, '
        'symbol: $symbol, quantity: $quantity, mult: $mult, '
        'costPrice: $costPrice, costBasis: $costBasis, closePrice: $closePrice, '
        'value: $value, unrealizedPL: $unrealizedPL, code: $code)';
  }
}
