import 'dart:io';

import 'package:excel/excel.dart';
import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:investing_organizer/export/data_exporter.dart';
import 'package:tinkoff_invest/tinkoff_invest.dart';

class ExcelProfileExporter extends DataExporter<PortfolioExportData> {
  const ExcelProfileExporter();

  @override
  Future<File> export(String targetPath, PortfolioExportData data) async {
    final excel = Excel.createExcel();

    for (final dataSet in data.sets) {
      final sheetName = '${dataSet.account}_${dataSet.currency}';
      final sheet = excel[sheetName];

      sheet.appendRow(<String>[
        'Ticker',
        'Name',
        'Type',
        'Count',
        'Price',
        'Amount',
      ]);

      for (final item in dataSet.items) {
        sheet.appendRow(<Object>[
          item.ticker,
          item.name,
          item.type.name,
          item.count,
          item.price,
          item.amount,
        ]);
      }
    }

    excel.delete(excel.getDefaultSheet()!);
    excel.setDefaultSheet(excel.sheets.keys.first);

    final bytes = excel.save()!;

    final file = File(targetPath);
    await file.writeAsBytes(bytes);
    return file;
  }
}
