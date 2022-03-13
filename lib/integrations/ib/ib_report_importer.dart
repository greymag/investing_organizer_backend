import 'package:csv/csv.dart';
import 'package:investing_organizer/integrations/ib/ib.dart';
import 'package:string_ext/string_ext.dart';

class IBReportImporter {
  final String csv;

  IBReportImporter(this.csv);

  Future<Report> parse() async {
    Statement? statement;
    AccountInformation? accountInformation;
    List<OpenPosition>? openPositions;
    List<ForexBalance>? forexBalances;
    List<WithholdingTax>? withholdingTaxes;
    List<DepositOrWithdrawal>? depositsAndWithdrawals;
    List<Dividend>? dividends;
    List<InstrumentInfo>? instrumentsInfo;

    void processSection(String name, List<List<dynamic>> data) {
      switch (name) {
        case 'Statement':
          statement = _statementByData(data);
          break;
        case 'Account Information':
          accountInformation = _accountInformationByData(data);
          break;
        case 'Open Positions':
          openPositions = _openPositionsByData(data);
          break;
        case 'Forex Balances':
          forexBalances = _forexBalancesByData(data);
          break;
        case 'Deposits & Withdrawals':
          depositsAndWithdrawals = _depositsAndWithdrawalsByData(data);
          break;
        case 'Dividends':
          dividends = _dividendsByData(data);
          break;
        case 'Withholding Tax':
          withholdingTaxes = _withholdingTaxesByData(data);
          break;
        case 'Financial Instrument Information':
          instrumentsInfo = _instrumentsInfoByData(data);
          break;
        default:
          // TODO: handle all sections
          print('Unhandled section: $name');
      }
    }

    final rows = const CsvToListConverter(eol: '\n').convert(csv);

    String? curSection;
    final sectionData = <List<dynamic>>[];
    for (final row in rows) {
      final section = row.first as String?;
      if (curSection != null && curSection != section) {
        processSection(curSection, sectionData);
        sectionData.clear();
      }

      curSection = section;
      sectionData.add(row);
    }

    if (curSection != null) {
      processSection(curSection, sectionData);
    }

    return Report(
      statement!,
      accountInformation!,
      openPositions,
      forexBalances,
      depositsAndWithdrawals ?? [],
      dividends ?? [],
      withholdingTaxes ?? [],
      instrumentsInfo,
    );
  }

  Statement _statementByData(List<List<dynamic>> data) =>
      Statement.fromMap(_fromKV(data));

  AccountInformation _accountInformationByData(List<List<dynamic>> data) =>
      AccountInformation.fromMap(_fromKV(data));

  List<OpenPosition> _openPositionsByData(List<List<dynamic>> data) =>
      _listByData(data, (d) => OpenPosition.fromMap(d), skip: 3);

  List<ForexBalance> _forexBalancesByData(List<List<dynamic>> data) =>
      _listByData(data, (d) => ForexBalance.fromMap(d),
          filter: (row) => (row[3] as String).isNotEmpty);

  List<WithholdingTax> _withholdingTaxesByData(List<List<dynamic>> data) =>
      _listByData(data, (d) => WithholdingTax.fromMap(d),
          filter: (row) => (row[3] as String).isNotEmpty);

  List<DepositOrWithdrawal> _depositsAndWithdrawalsByData(
          List<List<dynamic>> data) =>
      _listByData(data, (d) => DepositOrWithdrawal.fromMap(d),
          filter: (row) => (row[3] as String).isNotEmpty);

  List<Dividend> _dividendsByData(List<List<dynamic>> data) =>
      _listByData(data, (d) => Dividend.fromMap(d),
          filter: (row) => (row[3] as String).isNotEmpty);

  List<InstrumentInfo> _instrumentsInfoByData(List<List<dynamic>> data) =>
      _listByData(data, (d) => InstrumentInfo.fromMap(d));

  List<T> _listByData<T>(
      List<List<dynamic>> data, T Function(Map<String, dynamic>) fromMap,
      {int skip = 2, bool Function(List<dynamic>)? filter}) {
    final keys = data.first.cast<String>().skip(skip).map(_key);
    return data
        .sublist(1)
        .where(
            (row) => row[1] as String == 'Data' && (filter?.call(row) ?? true))
        .map((row) {
      final data = Map<String, dynamic>.fromIterables(keys, row.skip(skip));
      return fromMap(data);
    }).toList();
  }

  Map<String, dynamic> _fromKV(List<List<dynamic>> data) {
    // First row is header, then fields
    final map = <String, dynamic>{};
    data.sublist(1).forEach((row) {
      map[_key(row[2] as String)] = row[3];
    });
    return map;
  }

  String _key(String raw) =>
      raw.replaceAll(' ', '').replaceAll('/', '').firstToLower();
}
