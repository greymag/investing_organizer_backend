import 'account_information.dart';
import 'deposit_or_withdrawal.dart';
import 'dividend.dart';
import 'forex_balance.dart';
import 'instrument_info.dart';
import 'open_position.dart';
import 'statement.dart';
import 'withholding_tax.dart';

/// IB report data.
class Report {
  final Statement statement;
  final AccountInformation accountInformation;
  // TODO: Net Asset Value
  // TODO: Change in NAV
  // TODO: Mark-to-Market Performance Summary
  // TODO: Realized & Unrealized Performance Summary
  // TODO: Cash Report
  final List<OpenPosition>? openPositions;
  final List<ForexBalance>? forexBalances;

  // TODO: Trades
  final List<DepositOrWithdrawal> depositsAndWithdrawals;
  final List<Dividend> dividends;
  final List<WithholdingTax> withholdingTaxes;
  // TODO: Commission Adjustments
  // TODO: Change in Dividend Accruals
  final List<InstrumentInfo>? instrumentsInformation;
  // TODO: Codes
  // TODO: Notes/Legal Notes

  Report(
    this.statement,
    this.accountInformation,
    this.openPositions,
    this.forexBalances,
    this.depositsAndWithdrawals,
    this.dividends,
    this.withholdingTaxes,
    this.instrumentsInformation,
  );

  @override
  String toString() =>
      'Report(statement: $statement, accountInformation: $accountInformation, '
      'openPositions: $openPositions, '
      'forexBalances: $forexBalances, '
      'depositsAndWithdrawals: $depositsAndWithdrawals, '
      'dividends: $dividends, '
      'withholdingTaxes: $withholdingTaxes, '
      'instrumentsInformation: $instrumentsInformation)';
}
