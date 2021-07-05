import 'dart:io';

import 'package:async/async.dart';
import 'package:in_date_range/in_date_range.dart';
import 'package:investing_organizer/export/data/operations_export_data.dart';
import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:investing_organizer/export/excel/excel_operations_exporter.dart';
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

  Future<PortfolioExportData> exportPorfolio() async {
    final userApi = _api.user;
    final accounts = (await userApi.accounts().require()).payload;

    final data4Export = <PortfolioExportDataSet>[];
    for (final account in accounts.accounts) {
      final accountTitle =
          '${account.brokerAccountId}-${account.brokerAccountType.name}';
      await _loadData(data4Export, account.brokerAccountId, accountTitle);
    }

    return PortfolioExportData(data4Export);
  }

  Future<File> exportPortfolioToExcel(String path) async {
    return const ExcelPortfolioExporter().export(path, await exportPorfolio());
  }

  Future<OperationsExportData> exportOperations(DateRange range) async {
    final userApi = _api.user;
    final accounts = (await userApi.accounts().require()).payload;

    final to = range.end;
    final from = range.start;

    final data4Export = <OperationsExportDataSet>[];
    for (final account in accounts.accounts) {
      final dataSet = OperationsExportDataSet(
        account: account.brokerAccountType.name,
        taxes: [],
        comissions: [],
        coupons: [],
        dividends: [],
        otherExpenses: [],
        otherIncomes: [],
        payIns: [],
        payOuts: [],
        trades: [],
      );

      final operationsApi = _api.operations;
      final operations = (await operationsApi
              .load(from, to, brokerAccountId: account.brokerAccountId)
              .require())
          .payload;
      final marketApi = _api.market;

      final items = operations.operations.toList();
      items.sort((a, b) => a.date.compareTo(b.date));

      for (final item in items) {
        final type = item.operationType;
        if (type == null) {
          assert(false, 'Null operation type');
          continue;
        }

        if (item.status != OperationStatus.done) continue;

        final List<OperationsExportDataItem> list;

        switch (type) {
          case OperationTypeWithCommission.buy:
          case OperationTypeWithCommission.buyCard: // TODO: double check
          case OperationTypeWithCommission.sell:
            list = dataSet.trades;
            break;
          case OperationTypeWithCommission.brokerCommission:
          case OperationTypeWithCommission.exchangeCommission:
          case OperationTypeWithCommission.serviceCommission:
          case OperationTypeWithCommission.marginCommission:
          case OperationTypeWithCommission.otherCommission:
            list = dataSet.comissions;
            break;
          case OperationTypeWithCommission.payIn:
            list = dataSet.payIns;
            break;
          case OperationTypeWithCommission.payOut:
            list = dataSet.payOuts;
            break;
          case OperationTypeWithCommission.tax:
          case OperationTypeWithCommission.taxLucre: // TODO: double check
          case OperationTypeWithCommission.taxDividend:
          case OperationTypeWithCommission.taxCoupon:
            list = dataSet.taxes;
            break;
          case OperationTypeWithCommission.coupon:
            list = dataSet.coupons;
            break;
          case OperationTypeWithCommission.dividend:
            list = dataSet.dividends;
            break;
          case OperationTypeWithCommission.taxBack: // TODO: move to separate?
          case OperationTypeWithCommission.securityIn: // TODO: check
          case OperationTypeWithCommission.repayment: // TODO: check
          case OperationTypeWithCommission.partRepayment: // TODO: check
            list = dataSet.otherIncomes;
            break;
          case OperationTypeWithCommission.securityOut:
            list = dataSet.otherExpenses;
            break;
        }

        // TODO: cache
        final instrument = item.figi != null
            ? (await marketApi.searchByFigi(item.figi!).require()).payload
            : null;

        list.add(OperationsExportDataItem(
          date: item.date,
          ticker: instrument?.ticker,
          amount: item.payment,
          currency: item.currency.name,
        ));

        // TODO: process item.comission?
      }

      data4Export.add(dataSet);
    }

    return OperationsExportData(
      range: DateRange(from, to),
      sets: data4Export,
    );
  }

  Future<File> exportOperationsToExcel(String path, DateRange range) async {
    return const ExcelOperationsExporter()
        .export(path, await exportOperations(range));
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
