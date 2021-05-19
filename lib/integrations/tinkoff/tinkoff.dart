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

    // TODO: accept date as an arg
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(now.year, now.month, now.day + 1);

    for (final position in portfolio.positions) {
      if (position.instrumentType == InstrumentType.currency) continue;

      final candles = (await marketApi
              .candles(position.figi, startDay, endDay, CandleResolution.day)
              .require())
          .payload;

      final price = candles.candles.first.c;
      final amount = price * position.balance;

      // TODO: currency

      sb
        ..write(position.ticker)
        ..write(colSep)
        ..write(position.name)
        ..write(colSep)
        ..write(position.instrumentType.name)
        ..write(colSep)
        ..write(position.balance.toInt())
        ..write(colSep)
        ..write(price)
        ..write(colSep)
        ..write(amount)
        ..write(rowSep);
    }

    for (final currency in currencies.currencies) {
      sb
        ..write('')
        ..write(colSep)
        ..write(currency.currency.name)
        ..write(colSep)
        ..write(InstrumentType.currency.name)
        ..write(colSep)
        ..write(currency.balance)
        ..write(colSep)
        ..write(1)
        ..write(colSep)
        ..write(currency.balance)
        ..write(rowSep);
    }

    final file = File(path);
    await file.writeAsString(sb.toString());
    return file;
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
