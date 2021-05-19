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

    final portfolio = (await _require(_api.portfolio.load(accountId))).payload;
    final currencies =
        (await _require(_api.portfolio.currencies(accountId))).payload;

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
      ..write('Lots')
      ..write(rowSep);

    for (final position in portfolio.positions) {
      if (position.instrumentType == InstrumentType.currency) continue;

      sb
        ..write(position.ticker)
        ..write(colSep)
        ..write(position.name)
        ..write(colSep)
        ..write(position.instrumentType.name)
        ..write(colSep)
        ..write(position.lots)
        ..write(rowSep);
    }

    for (final currency in currencies.currencies) {
      sb
        ..write('')
        ..write(colSep)
        ..write(currency.currency)
        ..write(colSep)
        ..write(InstrumentType.currency.name)
        ..write(colSep)
        ..write(currency.balance)
        ..write(rowSep);
    }

    final file = File(path);
    await file.writeAsString(sb.toString());
    return file;
  }

  Future<T> _require<T>(Future<Result<T>> future) async {
    final res = await future;
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
