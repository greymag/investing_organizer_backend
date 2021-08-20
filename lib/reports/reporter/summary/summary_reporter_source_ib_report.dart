import 'dart:io';

import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:investing_organizer/integrations/ib/ib_report_importer.dart';

import 'package:investing_organizer/integrations/ib/ib.dart' as ib;
import 'package:tinkoff_invest/tinkoff_invest.dart' as tinkoff;

import 'summary_reporter.dart';

class SummaryReporterSourceIBReport implements SummaryReporterSource {
  final IBReportImporter _importer;

  SummaryReporterSourceIBReport(this._importer);

  SummaryReporterSourceIBReport.csv(String csv)
      : _importer = IBReportImporter(csv);

  factory SummaryReporterSourceIBReport.csvFile(File file) =>
      SummaryReporterSourceIBReport.csv(file.readAsStringSync());

  factory SummaryReporterSourceIBReport.csvPath(String path) =>
      SummaryReporterSourceIBReport.csvFile(File(path));

  @override
  Future<PortfolioExportData> getData() async {
    final report = await _importer.parse();

    final account = report.accountInformation?.account ?? 'n/a';
    final itemsByCurrency = <String, List<PortfolioExportDataItem>>{};

    final openPositions = report.openPositions;
    if (openPositions != null) {
      for (final position in openPositions) {
        final currency = position.currency;

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

        (itemsByCurrency[currency] ??= <PortfolioExportDataItem>[]).add(item);
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

    // TODO: add cash

    return PortfolioExportData(sets);
  }
}

extension IBInstumentTypeExtension on ib.InstrumentType {
  tinkoff.InstrumentType forData() {
    switch (this) {
      case ib.InstrumentType.common:
        return tinkoff.InstrumentType.stock;
      case ib.InstrumentType.etf:
        return tinkoff.InstrumentType.etf;
      case ib.InstrumentType.reit:
        return tinkoff.InstrumentType.stock;
    }
  }
}
