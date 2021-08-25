import 'dart:io';
import 'package:in_date_range/in_date_range.dart';
import 'package:investing_organizer/export/excel/excel_operations_exporter.dart';

import 'package:investing_organizer/export/data/operations_export_data.dart';
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
    // TODO: check dates for data from different sources?
    return const ExcelPortfolioExporter(accountsOnDifferentSheets: false)
        .export(path, await _loadPortfolio());
  }

  Future<File?> exportOperationsToExcel(String path, DateRange range) async {
    if (_sources.isEmpty) return null;
    return const ExcelOperationsExporter(accountsOnDifferentSheets: false)
        .export(path, await _loadOperations(range));
  }

  Future<PortfolioExportData> _loadPortfolio() =>
      PortfolioExportData.byAsync(_sources.map((source) => source.getData()));

  Future<OperationsExportData> _loadOperations(DateRange range) =>
      _mergeOperationsAsync(
          range, _sources.map((source) => source.getOperations(range)));

  Future<OperationsExportData> _mergeOperationsAsync(
          DateRange range, Iterable<Future<OperationsExportData>> list) async =>
      OperationsExportData(
        range: range,
        sets: (await Future.wait(list)).expand((d) => d.sets).toList(),
      );
}

abstract class SummaryReporterSource {
  Future<PortfolioExportData> getData();
  Future<OperationsExportData> getOperations(DateRange range);
}
