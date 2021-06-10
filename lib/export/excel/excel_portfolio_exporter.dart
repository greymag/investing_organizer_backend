import 'package:excel/excel.dart';
import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:tinkoff_invest/tinkoff_invest.dart';

import 'excel_exporter.dart';

class ExcelPortfolioExporter extends ExcelExporter<PortfolioExportData> {
  const ExcelPortfolioExporter();

  @override
  Future<void> writeToExcel(Excel excel, PortfolioExportData data) async {
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
  }
}
