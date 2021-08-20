import 'instrument_type.dart';

/// Financial Instrument Information.
class InstrumentInfo {
  // Asset Category
  // - Stocks
  // - Forex
  // - ?
  final String assetCategory;
  final String symbol;
  final String description;
  final int conid;
  final String securityID;
  final String listingExch;
  final double multiplier;
  final InstrumentType type;
  final String code;

  InstrumentInfo(this.assetCategory, this.symbol, this.description, this.conid,
      this.securityID, this.listingExch, this.multiplier, this.type, this.code);

  factory InstrumentInfo.fromMap(Map<String, dynamic> map) {
    return InstrumentInfo(
      map['assetCategory'] as String,
      map['symbol'] as String,
      map['description'] as String,
      (map['conid'] as num).toInt(),
      map['securityID'] as String,
      map['listingExch'] as String,
      (map['multiplier'] as num).toDouble(),
      map.requireInstrumentType('type'),
      map['code'] as String,
    );
  }

  @override
  String toString() {
    return 'InstrumentInfo(assetCategory: $assetCategory, symbol: $symbol, '
        'description: $description, conid: $conid, securityID: $securityID, '
        'listingExch: $listingExch, multiplier: $multiplier, type: $type, '
        'code: $code)';
  }
}
