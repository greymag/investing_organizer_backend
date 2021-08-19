import 'dart:io';

import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:investing_organizer/export/excel/excel_portfolio_exporter.dart';

class SummaryReporter {
  final bool debug;

  final List<SummaryReporterSource> _sources = <SummaryReporterSource>[];

  SummaryReporter({this.debug = false});

  void addSource(SummaryReporterSource value) {
    _sources.add(value);
  }

  Future<File?> exportPortfolioToExcel(String path) async {
    if (_sources.isEmpty) return null;
    return const ExcelPortfolioExporter(accountsOnDifferentSheets: false)
        .export(path, await _loadPortfolio());
  }

  Future<PortfolioExportData> _loadPortfolio() =>
      PortfolioExportData.byAsync(_sources.map((source) => source.getData()));
}

abstract class SummaryReporterSource {
  Future<PortfolioExportData> getData();
}
