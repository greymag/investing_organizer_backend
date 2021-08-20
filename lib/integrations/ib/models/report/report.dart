import 'account_information.dart';
import 'forex_balance.dart';
import 'instrument_info.dart';
import 'open_position.dart';
import 'statement.dart';

/// IB report data.
class Report {
  final Statement? statement;
  final AccountInformation? accountInformation;
  // TODO: Net Asset Value
  // TODO: Change in NAV
  // TODO: Mark-to-Market Performance Summary
  // TODO: Realized & Unrealized Performance Summary
  // TODO: Cash Report
  final List<OpenPosition>? openPositions;
  final List<ForexBalance>? forexBalances;

  // TODO: Trades
  // TODO: Withholding Tax
  // TODO; Dividends
  // TODO: Commission Adjustments
  // TODO: Change in Dividend Accruals
  final List<InstrumentInfo>? instrumentsInformation;
  // TODO: Codes
  // TODO: Notes/Legal Notes

  Report(this.statement, this.accountInformation, this.openPositions,
      this.forexBalances, this.instrumentsInformation);

  @override
  String toString() =>
      'Report(statement: $statement, accountInformation: $accountInformation, '
      'openPositions: $openPositions, '
      'forexBalances: $forexBalances, '
      'instrumentsInformation: $instrumentsInformation)';
}
