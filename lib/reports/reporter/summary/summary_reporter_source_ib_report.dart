import 'dart:io';

import 'package:in_date_range/in_date_range.dart';
import 'package:investing_organizer/export/data/operations_export_data.dart';
import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:investing_organizer/integrations/ib/ib_report_importer.dart';

import 'package:investing_organizer/integrations/ib/ib.dart' as ib;
import 'package:tinkoff_invest/tinkoff_invest.dart' as tinkoff;

import 'summary_reporter.dart';

class SummaryReporterSourceIBReport implements SummaryReporterSource {
  final IBReportImporter _importer;
  Future<ib.Report>? _report;

  SummaryReporterSourceIBReport(this._importer);

  SummaryReporterSourceIBReport.csv(String csv)
      : _importer = IBReportImporter(csv);

  factory SummaryReporterSourceIBReport.csvFile(File file) =>
      SummaryReporterSourceIBReport.csv(file.readAsStringSync());

  factory SummaryReporterSourceIBReport.csvPath(String path) =>
      SummaryReporterSourceIBReport.csvFile(File(path));

  @override
  Future<PortfolioExportData> getData() async {
    final report = await _getReport();
    final account = _getAccountName(report);
    final itemsByCurrency = <String, List<PortfolioExportDataItem>>{};

    void addItem(String currency, PortfolioExportDataItem item) =>
        (itemsByCurrency[currency] ??= <PortfolioExportDataItem>[]).add(item);

    final openPositions = report.openPositions;
    if (openPositions != null) {
      for (final position in openPositions) {
        final info = report.instrumentsInformation!
            .firstWhere((i) => i.symbol == position.symbol);

        final item = PortfolioExportDataItem(
          ticker: position.symbol,
          name: info.description,
          type: info.type.forData(),
          count: position.quantity,
          price: position.closePrice,
          amount: position.value,
        );

        addItem(position.currency, item);
      }
    }

    final forexBalances = report.forexBalances;
    if (forexBalances != null) {
      for (final balance in forexBalances) {
        if (balance.quantity == 0) continue;

        // TODO: use description is terrible, may be use Cash Report after all?
        final currency = balance.description;

        final item = PortfolioExportDataItem(
          ticker: '',
          name: currency,
          type: tinkoff.InstrumentType.currency,
          count: balance.quantity.toInt(),
          price: 1,
          amount: balance.quantity,
        );

        addItem(currency, item);
      }
    }

    final sets = <PortfolioExportDataSet>[];
    itemsByCurrency.forEach((currency, items) {
      sets.add(PortfolioExportDataSet(
        account: account,
        currency: currency,
        items: items,
      ));
    });

    return PortfolioExportData(sets);
  }

  @override
  Future<OperationsExportData> getOperations(DateRange range) async {
    final report = await _getReport();

    if (!report.statement.period.includes(range)) {
      throw Exception('Report period ${report.statement.period} '
          "doesn't contains range: $range");
    }

    List<OperationsExportDataItem> convert<T extends ib.Operation>(
        Iterable<T> list) {
      return list
          .where((e) => range.contains(e.date))
          .map((e) => e.toExport())
          .toList();
    }

    final dataSet = OperationsExportDataSet(
      account: _getAccountName(report),
      taxes: convert(report.withholdingTaxes),
      comissions: [], // TODO: comissions
      coupons: [], // TODO: coupons
      dividends: convert(report.dividends),
      otherExpenses: [], // TODO: otherExpenses
      otherIncomes: [], // TODO: otherIncomes
      payIns: convert(report.depositsAndWithdrawals.where((e) => e.amount > 0)),
      payOuts:
          convert(report.depositsAndWithdrawals.where((e) => e.amount < 0)),
      trades: [], // TODO: trades
    );

    return OperationsExportData(range: range, sets: [dataSet]);
  }

  Future<ib.Report> _getReport() => _report ??= _importer.parse();

  String _getAccountName(ib.Report report) => report.accountInformation.account;
}

extension IBInstrumentTypeExtension on ib.InstrumentType {
  tinkoff.InstrumentType forData() {
    switch (this) {
      case ib.InstrumentType.common:
      case ib.InstrumentType.adr:
        return tinkoff.InstrumentType.stock;
      case ib.InstrumentType.etf:
        return tinkoff.InstrumentType.etf;
      case ib.InstrumentType.reit:
        return tinkoff.InstrumentType.stock;
    }
  }
}

extension IBIOperationExtension on ib.Operation {
  OperationsExportDataItem toExport() => OperationsExportDataItem(
        date: date,
        ticker: ticker,
        amount: amount,
        currency: currency,
      );
}
