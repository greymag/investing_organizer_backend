/// Financial Instrument Information.
class InstrumentInfo {
  final String assetCategory;
  final String symbol;
  final String description;
  final int conid;
  final String securityID;
  final String listingExch;
  final double multiplier;
  final String type;
  final String code;

  InstrumentInfo(this.assetCategory, this.symbol, this.description, this.conid,
      this.securityID, this.listingExch, this.multiplier, this.type, this.code);
}
