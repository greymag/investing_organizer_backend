import 'package:tinkoff_invest/tinkoff_invest.dart';

class PortfolioExportData {
  final List<PortfolioExportDataSet> sets;

  PortfolioExportData(this.sets);
}

class PortfolioExportDataSet {
  final String account;
  final String currency;
  final List<PortfolioExportDataItem> items;

  PortfolioExportDataSet(
      {required this.account, required this.currency, required this.items});
}

class PortfolioExportDataItem {
  final String ticker;
  final String name;
  final InstrumentType type;
  final int count;
  final double price;
  final double amount;

  PortfolioExportDataItem({
    required this.ticker,
    required this.name,
    required this.type,
    required this.count,
    required this.price,
    required this.amount,
  });

  int compareTo(PortfolioExportDataItem other) {
    if (other == this) return 0;

    final byType = type.compareTo(other.type);
    if (byType != 0) return byType;

    final byTicker = ticker.compareTo(other.ticker);
    if (byTicker != 0) return byTicker;

    final byName = name.compareTo(other.name);
    if (byName != 0) return byName;

    return 0;
  }

  @override
  String toString() {
    return '_ExportDateItem(ticker: $ticker, name: $name, type: $type, '
        'count: $count, price: $price, amount: $amount)';
  }
}

extension _InstrumentTypeExtension on InstrumentType {
  int compareTo(InstrumentType other) {
    if (this == other) return 0;
    const order = [
      InstrumentType.stock,
      InstrumentType.bond,
      InstrumentType.etf,
      InstrumentType.currency
    ];
    return order.indexOf(this).compareTo(order.indexOf(other));
  }
}
