import 'package:csv/csv.dart';
import 'package:investing_organizer/integrations/ib/models/report/account_information.dart';
import 'package:investing_organizer/integrations/ib/models/report/open_position.dart';
import 'package:investing_organizer/integrations/ib/models/report/statement.dart';
import 'package:string_ext/string_ext.dart';

import 'models/report/report.dart';

class IBReportImporter {
  final String csv;

  IBReportImporter(this.csv);

  Future<Report> parse() async {
    Statement? statement;
    AccountInformation? accountInformation;
    List<OpenPosition>? openPositions;

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

    return Report(statement, accountInformation, openPositions);
  }

  Statement _statementByData(List<List<dynamic>> data) =>
      Statement.fromMap(_fromKV(data));

  AccountInformation _accountInformationByData(List<List<dynamic>> data) =>
      AccountInformation.fromMap(_fromKV(data));

  List<OpenPosition> _openPositionsByData(List<List<dynamic>> data) {
    const skip = 3;
    final keys = data.first.cast<String>().skip(skip).map(_key);
    return data
        .sublist(1)
        .where((row) => row[1] as String == 'Data')
        .map((row) {
      final data = Map<String, dynamic>.fromIterables(keys, row.skip(skip));
      return OpenPosition.fromMap(data);
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
