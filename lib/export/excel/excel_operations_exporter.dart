import 'package:excel/excel.dart';
import 'package:in_date_range/in_date_range.dart';
import 'package:investing_organizer/export/data/operations_export_data.dart';
import 'package:investing_organizer/export/excel/excel_exporter.dart';

class ExcelOperationsExporter extends ExcelExporter<OperationsExportData> {
  static const _columns = [
    'Date',
    'Ticker',
    'Amount',
    'Currency',
  ];

  const ExcelOperationsExporter();

  @override
  Future<void> writeToExcel(Excel excel, OperationsExportData data) async {
    for (final dataSet in data.sets) {
      final sheetName = dataSet.account;
      final sheet = excel[sheetName];

      _addDateRange(sheet, data.range);
      _addDataSubset(
          sheet, 'Pay In/Outs', _combine(dataSet.payIns, dataSet.payOuts));
      _addDataSubset(sheet, 'Coupons', dataSet.coupons);
      _addDataSubset(sheet, 'Dividends', dataSet.dividends);
      _addDataSubset(sheet, 'Taxes', dataSet.taxes);
      _addDataSubset(sheet, 'Comissions', dataSet.comissions);
      _addDataSubset(sheet, 'Trades', dataSet.trades);
      _addDataSubset(sheet, 'Other',
          _combine(dataSet.otherIncomes, dataSet.otherExpenses));
    }
  }

  void _addDateRange(Sheet sheet, DateRange range) {
    final first = range.start;
    final last = range.end.subtract(const Duration(microseconds: 1));
    sheet.appendRow(<String>['From', _date(first), 'To', _date(last)]);
  }

  void _addDataSubset(
      Sheet sheet, String title, List<OperationsExportDataItem> items) {
    if (items.isEmpty) return;

    _addTitle(sheet, title);
    _addHeaders(sheet);
    for (final item in items) {
      _addRow(sheet, item);
    }

    sheet.appendRow(const <String>['']);
  }

  void _addTitle(Sheet sheet, String title) {
    final curRow = sheet.maxRows;
    final start = CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: curRow);
    final end = CellIndex.indexByColumnRow(
        columnIndex: _columns.length - 1, rowIndex: curRow);

    sheet.appendRow(const <String>['']);
    sheet.merge(start, end, customValue: title);
  }

  void _addHeaders(Sheet sheet) {
    sheet.appendRow(_columns);
  }

  void _addRow(Sheet sheet, OperationsExportDataItem item) {
    sheet.appendRow(<String>[
      item.date.toIso8601String(),
      item.ticker ?? '',
      item.amount.toString(),
      item.currency,
    ]);
  }

  List<OperationsExportDataItem> _combine(
      List<OperationsExportDataItem> incomes,
      List<OperationsExportDataItem> expenses) {
    return List<OperationsExportDataItem>.from(incomes)
      ..addAll(expenses)
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  String _date(DateTime date) =>
      '${_num(date.year, 4)}/${_num(date.month, 2)}/${_num(date.day, 2)}';

  String _num(int value, int digits) => value.toString().padLeft(digits, '0');
}
