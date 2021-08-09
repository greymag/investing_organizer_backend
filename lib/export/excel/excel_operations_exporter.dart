import 'package:excel/excel.dart';
import 'package:in_date_range/in_date_range.dart';
import 'package:investing_organizer/export/data/operations_export_data.dart';
import 'package:investing_organizer/export/excel/excel_exporter.dart';

typedef _HeaderProcessor = List<String> Function(List<String> values);
typedef _RowProcessor = List<String> Function(
    OperationsExportDataItem item, List<String> values);

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

    final accountsByItem = <OperationsExportDataItem, String>{};

    for (final dataSet in data.sets) {
      final account = dataSet.account;
      void addTo(List<OperationsExportDataItem> to,
          List<OperationsExportDataItem> items) {
        items.forEach((item) => accountsByItem[item] = account);
        to.addAll(items);
      }

      addTo(payIns, dataSet.payIns);
      addTo(payOuts, dataSet.payOuts);
      addTo(coupons, dataSet.coupons);
      addTo(dividends, dataSet.dividends);
      addTo(taxes, dataSet.taxes);
      addTo(comissions, dataSet.comissions);
      addTo(trades, dataSet.trades);
      addTo(otherIncomes, dataSet.otherIncomes);
      addTo(otherExpenses, dataSet.otherExpenses);
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
      headerProcessor: (headers) => headers.toList()..insert(1, 'Account'),
      entryProcessor: (item, row) => row..insert(1, accountsByItem[item]!),
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
    _HeaderProcessor? headerProcessor,
    _RowProcessor? entryProcessor,
  }) {
    void subset(String title, List<OperationsExportDataItem> items) =>
        _addDataSubset(sheet, title, items, headerProcessor, entryProcessor);

    _addDateRange(sheet, range);
    subset('Pay In/Outs', _combine(payIns, payOuts));
    subset('Coupons', coupons);
    subset('Dividends', dividends);
    subset('Taxes', taxes);
    subset('Comissions', comissions);
    subset('Trades', trades);
    subset('Other', _combine(otherIncomes, otherExpenses));
  }

  void _addDateRange(Sheet sheet, DateRange range) {
    final first = range.start;
    final last = range.end.subtract(const Duration(microseconds: 1));
    sheet.appendRow(<String>['From', _date(first), 'To', _date(last)]);
  }

  void _addDataSubset(
      Sheet sheet,
      String title,
      List<OperationsExportDataItem> items,
      _HeaderProcessor? headerProcessor,
      _RowProcessor? entryProcessor) {
    if (items.isEmpty) return;

    _addTitle(sheet, title);
    _addHeaders(sheet, headerProcessor);
    for (final item in items) {
      _addRow(sheet, item, entryProcessor);
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

  void _addHeaders(Sheet sheet, _HeaderProcessor? processor) {
    sheet.appendRow(processor?.call(_columns) ?? _columns);
  }

  void _addRow(
      Sheet sheet, OperationsExportDataItem item, _RowProcessor? processor) {
    // TODO: change date format
    // TODO: change amount format?
    var row = <dynamic>[
      formatDate(item.date),
      item.ticker ?? '',
      item.amount.toString(),
      item.currency,
    ];
    if (processor != null) {
      row = processor(item, row);
    }
    sheet.appendRow(row);
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
