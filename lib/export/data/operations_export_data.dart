import 'package:in_date_range/in_date_range.dart';

class OperationsExportData {
  final DateRange range;
  final List<OperationsExportDataSet> sets;

  OperationsExportData({required this.range, required this.sets});
}

class OperationsExportDataSet {
  final String account;
  final List<OperationsExportDataItem> payIns;
  final List<OperationsExportDataItem> payOuts;
  final List<OperationsExportDataItem> taxes;
  final List<OperationsExportDataItem> coupons;
  final List<OperationsExportDataItem> dividends;
  final List<OperationsExportDataItem> comissions;
  final List<OperationsExportDataItem> trades;
  final List<OperationsExportDataItem> otherExpenses;
  final List<OperationsExportDataItem> otherIncomes;

  OperationsExportDataSet({
    required this.account,
    required this.taxes,
    required this.payIns,
    required this.payOuts,
    required this.coupons,
    required this.dividends,
    required this.comissions,
    required this.trades,
    required this.otherExpenses,
    required this.otherIncomes,
  });
}

class OperationsExportDataItem {
  final DateTime date;
  final String? ticker;
  final double amount;
  final String currency;

  OperationsExportDataItem({
    required this.date,
    required this.ticker,
    required this.amount,
    required this.currency,
  });
}
