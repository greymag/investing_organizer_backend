import 'dart:io';

import 'package:async/async.dart';
import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:investing_organizer/export/excel/excel_portfolio_exporter.dart';
import 'package:tinkoff_invest/tinkoff_invest.dart';

class Tinkoff {
  late final TinkoffInvestApi _api;

  Tinkoff({
    required String token,
    bool debug = false,
  }) {
    _api = TinkoffInvestApi(token, debug: debug);
  }

  Future<File> exportPortfolio(String path) async {
    final userApi = _api.user;
    final accounts = (await userApi.accounts().require()).payload;

    final data4Export = <PortfolioExportDataSet>[];
    for (final account in accounts.accounts) {
      await _loadData(
          data4Export, account.brokerAccountId, account.brokerAccountType.name);
    }

    return const ExcelPortfolioExporter()
        .export(path, PortfolioExportData(data4Export));
  }

  Future<File> exportOperations(String path) async {
    final file = File(path);
    return file;
  }

  Future<void> _loadData(List<PortfolioExportDataSet> result, String accountId,
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

    final itemsByCurrency = <Currency, List<PortfolioExportDataItem>>{};

    void addItem(Currency currency, PortfolioExportDataItem item) {
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

      final item = PortfolioExportDataItem(
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

      final item = PortfolioExportDataItem(
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
      result.add(PortfolioExportDataSet(
        account: accountTitle,
        currency: key.name,
        items: items,
      ));
    });
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
