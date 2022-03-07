import 'dart:io';

import 'package:async/async.dart';
import 'package:in_date_range/in_date_range.dart';
import 'package:in_date_utils/in_date_utils.dart';
import 'package:investing_organizer/export/data/operations_export_data.dart';
import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:investing_organizer/export/excel/excel_operations_exporter.dart';
import 'package:investing_organizer/export/excel/excel_portfolio_exporter.dart';
import 'package:tinkoff_invest/tinkoff_invest.dart';

class Tinkoff {
  late final TinkoffInvestApi _api;

  final _instrumentsCache = <String, SearchMarketInstrument>{};

  Tinkoff({
    required String token,
    bool debug = false,
  }) {
    _api = TinkoffInvestApi(
      token,
      debug: debug,
      config:
          const TinkoffInvestApiConfig(connectTimeout: Duration(seconds: 10)),
    );
  }

  Future<PortfolioExportData> exportPorfolio() async {
    final userApi = _api.user;
    final accounts = (await userApi.accounts().require()).payload;

    final data4Export = <PortfolioExportDataSet>[];
    for (final account in accounts.accounts) {
      final accountTitle = _getAccoountTitle(account);
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
        account: _getAccoountTitle(account),
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

        final instrument =
            item.figi != null ? await _searchInstrument(item.figi!) : null;

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
    var candlesRange = _getWorkingDayNotEarlierThan(now);

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

      Future<double> loadPrice(DateRange range, {int attempt = 0}) async {
        try {
          // TODO: cache
          final candles = (await marketApi
                  .candles(position.figi, range.start, range.end,
                      CandleResolution.day)
                  .require())
              .payload;

          if (candles.candles.isEmpty) {
            if (attempt < 5) {
              return loadPrice(
                DateRange(DateUtils.previousDay(range.start), range.end),
                attempt: attempt + 1,
              );
            }

            throw Exception(
                "Can't load price for ${position.ticker} [${position.figi}]: "
                'no candles data in range $candlesRange');
          }

          candlesRange = range;
          return candles.candles.last.c;
        } catch (e) {
          throw Exception(
              "Can't load price for ${position.ticker} [${position.figi}]: $e");
        }
      }

      final currency = position.averagePositionPrice!.currency;
      final price = await loadPrice(candlesRange);
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

  Future<SearchMarketInstrument> _searchInstrument(String figi) async {
    if (_instrumentsCache.containsKey(figi)) return _instrumentsCache[figi]!;

    final res = (await _api.market.searchByFigi(figi).require()).payload;
    _instrumentsCache[figi] = res;
    return res;
  }

  String _getAccoountTitle(UserAccount account) =>
      '${account.brokerAccountId}-${account.brokerAccountType.name}';

  DateRange _getWorkingDayNotEarlierThan(DateTime date) {
    var res = date;

    while (res.weekday == DateTime.saturday || res.weekday == DateTime.sunday) {
      res = DateUtils.previousDay(res);
    }

    return DateRange.day(res);
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
        throw Exception('Unknown error: $err');
      }
    }

    return res.asValue!.value;
  }
}
