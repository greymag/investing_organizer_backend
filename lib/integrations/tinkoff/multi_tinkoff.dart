import 'dart:io';

import 'package:in_date_range/in_date_range.dart';
import 'package:investing_organizer/export/data/portfolio_export_data.dart';
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

  Future<File> exportPortfolioToExcel(String path) async {
    var allData = PortfolioExportData(const []);

    for (final tinkoff in instances) {
      final data = await tinkoff.exportPorfolio();

      allData = allData.merge(data);
    }

    return const ExcelPortfolioExporter().export(path, allData);
  }

  Future<File> exportOperationsToExcel(String path, DateRange range) async {
    assert(instances.length == 1,
        'Export operations for multiple accounts is not impletented yet');

    return instances.first.exportOperations(path, range);
  }
}
