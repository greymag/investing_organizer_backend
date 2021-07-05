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

  final bool accountsOnDifferentSheets;

  const ExcelOperationsExporter({this.accountsOnDifferentSheets = true});

  @override
  Future<void> writeToExcel(Excel excel, OperationsExportData data) async {
    if (accountsOnDifferentSheets) {
      _writeAccountsOnDifferentSheets(excel, data);
    } else {
      _writeAccountsOnSingleSheet(excel, data);
    }
  }

  void _writeAccountsOnSingleSheet(Excel excel, OperationsExportData data) {
    final payIns = <OperationsExportDataItem>[];
    final payOuts = <OperationsExportDataItem>[];
    final coupons = <OperationsExportDataItem>[];
    final dividends = <OperationsExportDataItem>[];
    final taxes = <OperationsExportDataItem>[];
    final comissions = <OperationsExportDataItem>[];
    final trades = <OperationsExportDataItem>[];
    final otherIncomes = <OperationsExportDataItem>[];
    final otherExpenses = <OperationsExportDataItem>[];

    // TODO: add column with account

    for (final dataSet in data.sets) {
      payIns.addAll(dataSet.payIns);
      payOuts.addAll(dataSet.payOuts);
      coupons.addAll(dataSet.coupons);
      dividends.addAll(dataSet.dividends);
      taxes.addAll(dataSet.taxes);
      comissions.addAll(dataSet.comissions);
      trades.addAll(dataSet.trades);
      otherIncomes.addAll(dataSet.otherIncomes);
      otherExpenses.addAll(dataSet.otherExpenses);
    }

    final sheet = excel['Operations'];
    _fillSheet(
      sheet,
      data.range,
      payIns: _sort(payIns),
      payOuts: _sort(payOuts),
      coupons: _sort(coupons),
      dividends: _sort(dividends),
      taxes: _sort(taxes),
      comissions: _sort(comissions),
      trades: _sort(trades),
      otherIncomes: _sort(otherIncomes),
      otherExpenses: _sort(otherExpenses),
    );
  }

  void _writeAccountsOnDifferentSheets(Excel excel, OperationsExportData data) {
    for (final dataSet in data.sets) {
      final sheetName = dataSet.account;
      final sheet = excel[sheetName];

      _fillSheet(
        sheet,
        data.range,
        payIns: dataSet.payIns,
        payOuts: dataSet.payOuts,
        coupons: dataSet.coupons,
        dividends: dataSet.dividends,
        taxes: dataSet.taxes,
        comissions: dataSet.comissions,
        trades: dataSet.trades,
        otherIncomes: dataSet.otherIncomes,
        otherExpenses: dataSet.otherExpenses,
      );
    }
  }

  void _fillSheet(
    Sheet sheet,
    DateRange range, {
    required List<OperationsExportDataItem> payIns,
    required List<OperationsExportDataItem> payOuts,
    required List<OperationsExportDataItem> coupons,
    required List<OperationsExportDataItem> dividends,
    required List<OperationsExportDataItem> taxes,
    required List<OperationsExportDataItem> comissions,
    required List<OperationsExportDataItem> trades,
    required List<OperationsExportDataItem> otherExpenses,
    required List<OperationsExportDataItem> otherIncomes,
  }) {
    _addDateRange(sheet, range);
    _addDataSubset(sheet, 'Pay In/Outs', _combine(payIns, payOuts));
    _addDataSubset(sheet, 'Coupons', coupons);
    _addDataSubset(sheet, 'Dividends', dividends);
    _addDataSubset(sheet, 'Taxes', taxes);
    _addDataSubset(sheet, 'Comissions', comissions);
    _addDataSubset(sheet, 'Trades', trades);
    _addDataSubset(sheet, 'Other', _combine(otherIncomes, otherExpenses));
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
    // TODO: change date format
    // TODO: change amount format?
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
    return _sort(
        List<OperationsExportDataItem>.from(incomes)..addAll(expenses));
  }

  List<OperationsExportDataItem> _sort(List<OperationsExportDataItem> list) {
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  String _date(DateTime date) =>
      '${_num(date.year, 4)}/${_num(date.month, 2)}/${_num(date.day, 2)}';

  String _num(int value, int digits) => value.toString().padLeft(digits, '0');
}
