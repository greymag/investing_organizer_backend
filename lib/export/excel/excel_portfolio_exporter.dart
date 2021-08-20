import 'package:excel/excel.dart';
import 'package:investing_organizer/export/data/portfolio_export_data.dart';
import 'package:tinkoff_invest/tinkoff_invest.dart';
import 'package:list_ext/list_ext.dart';

import 'excel_exporter.dart';

class ExcelPortfolioExporter extends ExcelExporter<PortfolioExportData> {
  final bool accountsOnDifferentSheets;

  const ExcelPortfolioExporter({this.accountsOnDifferentSheets = true});

  @override
  Future<void> writeToExcel(Excel excel, PortfolioExportData data) async {
    if (accountsOnDifferentSheets) {
      _writeAccountsOnDifferentSheets(excel, data);
    } else {
      _writeAccountsOnSingleSheet(excel, data);
    }
  }

  void _writeAccountsOnDifferentSheets(Excel excel, PortfolioExportData data) {
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

  void _writeAccountsOnSingleSheet(Excel excel, PortfolioExportData data) {
    final accounts = data.sets.map((s) => s.account).toSet().toList();
    final accountsCount = accounts.length;

    final map = <String, Map<String, List<PortfolioExportDataItem?>>>{};

    for (final dataSet in data.sets) {
      final accountIndex = accounts.indexOf(dataSet.account);
      final key = dataSet.currency;
      final Map<String, List<PortfolioExportDataItem?>> itemsByTicker;

      if (map.containsKey(key)) {
        itemsByTicker = map[key]!;
      } else {
        itemsByTicker = {};
        map[key] = itemsByTicker;
      }

      for (final item in dataSet.items) {
        final ticker = item.ticker;
        final List<PortfolioExportDataItem?> items;
        if (itemsByTicker.containsKey(ticker)) {
          items = itemsByTicker[ticker]!;
        } else {
          items = List.filled(accountsCount, null);
          itemsByTicker[ticker] = items;
        }

        items[accountIndex] = item;
      }
    }

    for (final currency in map.keys) {
      final itemsByTicker = map[currency]!;
      final sheetName = currency;
      final sheet = excel[sheetName];

      final rows = itemsByTicker.values.toList();
      rows.sort((a, b) => a.anyItem.compareTo(b.anyItem));

      sheet.appendRow(<String>[
        'Ticker',
        'Name',
        'Type',
        ...accounts,
        'Count',
        'Price',
        'Amount',
      ]);

      for (final list in rows) {
        final item = list.anyItem;

        sheet.appendRow(<Object>[
          item.ticker,
          item.name,
          item.type.name,
          for (var i = 0; i < accountsCount; i++) list.getItemCount(i),
          list.sumOf((i) => i?.count ?? 0),
          item.price,
          list.sumOfDouble((i) => i?.amount ?? 0),
        ]);
      }
    }
  }
}

extension _ItemsListExtension on List<PortfolioExportDataItem?> {
  PortfolioExportDataItem get anyItem => firstWhere((e) => e != null)!;

  int getItemCount(int index) => this[index]?.count ?? 0;
}
