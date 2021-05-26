import 'dart:io';

import 'package:async/async.dart';
import 'package:excel/excel.dart';
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
    final userApi = _api.user;

    final accounts = (await userApi.accounts().require()).payload;

    final data4Export = <_ExportDataSet>[];
    for (final account in accounts.accounts) {
      await _loadData(
          data4Export, account.brokerAccountId, account.brokerAccountType.name);
    }

    return _export2Excel(path, data4Export);
  }

  Future<void> _loadData(List<_ExportDataSet> result, String accountId,
      String accountTitle) async {
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

      // TODO: cache
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
      if (currency.balance == 0) continue;

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

    itemsByCurrency.forEach((key, value) {
      final items = value.toList()..sort((a, b) => a.compareTo(b));
      result.add(_ExportDataSet(
        account: accountTitle,
        currency: key,
        items: items,
      ));
    });
  }

  Future<File> _export2Excel(String path, List<_ExportDataSet> data) async {
    final excel = Excel.createExcel();

    for (final dataSet in data) {
      final sheetName = '${dataSet.account}_${dataSet.currency.name}';
      final sheet = excel[sheetName];

      sheet.appendRow(<String>[
        'Ticker',
        'Name',
        'Type',
        'Count',
        'Price',
        'Amount',
      ]);

      for (final item in dataSet.items) {
        sheet.appendRow(<Object>[
          item.ticker,
          item.name,
          item.type.name,
          item.count,
          item.price,
          item.amount,
        ]);
      }
    }

    excel.delete(excel.getDefaultSheet()!);
    excel.setDefaultSheet(excel.sheets.keys.first);

    final bytes = excel.save()!;

    final file = File(path);
    await file.writeAsBytes(bytes);
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
  final String account;
  final Currency currency;
  final List<_ExportDateItem> items;

  _ExportDataSet(
      {required this.account, required this.currency, required this.items});
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
