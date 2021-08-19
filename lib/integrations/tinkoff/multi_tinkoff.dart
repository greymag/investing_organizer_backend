import 'dart:io';

import 'package:in_date_range/in_date_range.dart';
import 'package:investing_organizer/export/data/operations_export_data.dart';
import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:investing_organizer/export/excel/excel_operations_exporter.dart';
import 'package:investing_organizer/export/excel/excel_portfolio_exporter.dart';
import 'package:investing_organizer/integrations/tinkoff/tinkoff.dart';

/// Wrapper to works with multiple Tinkoff accounts tokens.
class MultiTinkoff {
  final List<Tinkoff> instances;

  MultiTinkoff({
    required List<String> tokens,
    bool debug = false,
  })  : assert(tokens.isNotEmpty),
        instances =
            tokens.map((token) => Tinkoff(token: token, debug: debug)).toList();

  Future<PortfolioExportData> loadPortfolio() async {
    return PortfolioExportData.byAsync(
        instances.map((tinkoff) => tinkoff.exportPorfolio()));
  }

  Future<OperationsExportData> loadOperations(DateRange range) async {
    final allDataSets = <OperationsExportDataSet>[];

    for (final tinkoff in instances) {
      final data = await tinkoff.exportOperations(range);
      allDataSets.addAll(data.sets);
    }

    return OperationsExportData(range: range, sets: allDataSets);
  }

  Future<File> exportPortfolioToExcel(String path) async {
    return const ExcelPortfolioExporter(accountsOnDifferentSheets: false)
        .export(path, await loadPortfolio());
  }

  Future<File> exportOperationsToExcel(String path, DateRange range) async {
    return const ExcelOperationsExporter(accountsOnDifferentSheets: false)
        .export(path, await loadOperations(range));
  }
}
