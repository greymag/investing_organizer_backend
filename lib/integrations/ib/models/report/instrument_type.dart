enum InstrumentType { common, etf, reit }

// TODO: add other

extension InstrumentTypeExtension on InstrumentType {
  String get name => toString().split('.').last;
}

const _defaultInstrumentTypeKey = 'type';

class InstrumentTypeConverter {
  static const _data = <String, InstrumentType>{
    'COMMON': InstrumentType.common,
    'ETF': InstrumentType.etf,
    'REIT': InstrumentType.reit,
  };

  const InstrumentTypeConverter();

  InstrumentType convert(String value) => _data[value]!;

  InstrumentType fromJson(Map<String, dynamic> data,
          [String key = _defaultInstrumentTypeKey]) =>
      convert(data[key] as String);
}

extension InstrumentTypeFromJsonExtension on Map<String, dynamic> {
  InstrumentType requireInstrumentType(
          [String key = _defaultInstrumentTypeKey]) =>
      const InstrumentTypeConverter().fromJson(this, key);

  InstrumentType? optionalInstrumentType(
          [String key = _defaultInstrumentTypeKey]) =>
      this[key] != null
          ? const InstrumentTypeConverter().fromJson(this, key)
          : null;
}
