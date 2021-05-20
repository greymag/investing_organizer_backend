import 'dart:io';
import 'package:async/async.dart';
import 'package:tinkoff_invest/tinkoff_invest.dart';

class Tinkoff {
  late final TinkoffInvestApi _api;

  Tinkoff({
    required String token,
    bool debug = false,
  }) {
    _api = TinkoffInvestApi(token, debug: debug);
  }

  Future<File> export(String path) async {
    String? accountId;

    final portfolioApi = _api.portfolio;
    final marketApi = _api.market;

    final portfolio = (await portfolioApi.load(accountId).require()).payload;
    final currencies =
        (await portfolioApi.currencies(accountId).require()).payload;


    // TODO: accept date as an arg
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(now.year, now.month, now.day + 1);

    final itemsByCurrency = <Currency, List<_ExportDateItem>>{};

    void addItem(Currency currency, _ExportDateItem item) {
      final list = itemsByCurrency[currency];
      if (list != null) {
        list.add(item);
      } else {
        itemsByCurrency[currency] = [item];
      }
    }

    for (final position in portfolio.positions) {
      if (position.instrumentType == InstrumentType.currency) continue;

      final candles = (await marketApi
              .candles(position.figi, startDay, endDay, CandleResolution.day)
              .require())
          .payload;

      final currency = position.averagePositionPrice!.currency;
      final price = candles.candles.first.c;
      final amount = price * position.balance;

      final item = _ExportDateItem(
        ticker: position.ticker ?? '',
        name: position.name,
        type: position.instrumentType,
        count: position.balance.toInt(),
        price: price,
        amount: amount,
      );

      addItem(currency, item);
    }

    for (final currency in currencies.currencies) {
      final item = _ExportDateItem(
        ticker: '',
        name: currency.currency.name,
        type: InstrumentType.currency,
        count: currency.balance.toInt(),
        price: 1,
        amount: currency.balance,
      );

      addItem(currency.currency, item);
    }

    final data4Export = <_ExportDataSet>[];
    itemsByCurrency.forEach((key, value) {
      final items = value.toList()..sort((a, b) => a.compareTo(b));
      data4Export.add(_ExportDataSet(currency: key, items: items));
    });

    return _export2Txt(path, data4Export);
  }

  Future<File> _export2Txt(String path, List<_ExportDataSet> data) async {
    const colSep = '\t';
    const rowSep = '\n';
    final sb = StringBuffer();
    sb
      ..write('Ticker')
      ..write(colSep)
      ..write('Name')
      ..write(colSep)
      ..write('Type')
      ..write(colSep)
      ..write('Count')
      ..write(colSep)
      ..write('Price')
      ..write(colSep)
      ..write('Amount')
      ..write(rowSep);

    for (final dataSet in data) {
      sb..write(rowSep)..write(dataSet.currency.name)..write(rowSep);

      for (final item in dataSet.items) {
        sb
          ..write(item.ticker)
          ..write(colSep)
          ..write(item.name)
          ..write(colSep)
          ..write(item.type.name)
          ..write(colSep)
          ..write(item.count)
          ..write(colSep)
          ..write(item.price)
          ..write(colSep)
          ..write(item.amount)
          ..write(rowSep);
      }
    }

    final file = File(path);
    await file.writeAsString(sb.toString());
    return file;
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

extension _ResultExtension<T> on Future<Result<T>> {
  Future<T> require() async {
    final res = await this;
    if (res.isError) {
      final err = res.asError!.error;
      if (err is ErrorResponse) {
        throw Exception('Error #${err.payload.code}: ${err.payload.message}');
      } else {
        throw Exception('Unknown error');
      }
    }

    return res.asValue!.value;
  }
}

class _ExportDataSet {
  final Currency currency;
  final List<_ExportDateItem> items;

  _ExportDataSet({required this.currency, required this.items});
}

class _ExportDateItem {
  final String ticker;
  final String name;
  final InstrumentType type;
  final int count;
  final double price;
  final double amount;

  _ExportDateItem({
    required this.ticker,
    required this.name,
    required this.type,
    required this.count,
    required this.price,
    required this.amount,
  });

  int compareTo(_ExportDateItem other) {
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
