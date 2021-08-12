import 'package:investing_organizer/integrations/ib/models/report/account_information.dart';
import 'package:investing_organizer/integrations/ib/models/report/open_position.dart';
import 'package:investing_organizer/integrations/ib/models/report/statement.dart';

/// IB report data.
class Report {
  final Statement statement;
  final AccountInformation accountInformation;
  // TODO: Net Asset Value
  // TODO: Change in NAV
  // TODO: Mark-to-Market Performance Summary
  // TODO: Realized & Unrealized Performance Summary
  // TODO: Cash Report
  final List<OpenPosition> openPositions;
  // TODO: Forex Balance
  // TODO: Trades
  // TODO: Withholding Tax
  // TODO; Dividends
  // TODO: Commission Adjustments
  // TODO: Change in Dividend Accruals
  // TODO: Financial Instrument Information
  // TODO: Codes
  // TODO: Notes/Legal Notes

  Report(this.statement, this.accountInformation, this.openPositions);

  @override
  String toString() =>
      'Report(statement: $statement, accountInformation: $accountInformation, openPositions: $openPositions)';
}
