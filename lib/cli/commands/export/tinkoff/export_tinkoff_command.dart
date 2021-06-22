import 'dart:io';

import 'package:in_date_range/in_date_range.dart';
import 'package:in_date_utils/in_date_utils.dart';
import 'package:investing_organizer/cli/commands/warren_command.dart';
import 'package:investing_organizer/integrations/tinkoff/multi_tinkoff.dart';
import 'package:investing_organizer/integrations/tinkoff/tinkoff.dart';
import 'package:path/path.dart' as p;

/// Command to export data from Tinkoff account.
class ExportTinkoffCommand extends WarrenCommand {
  static const _argToken = 'token';
  static const _argType = 'type';
  static const _argRange = 'range';

  ExportTinkoffCommand()
      : super('tinkoff', 'Export data from Tinkoff account.') {
    argParser
      ..addOption(
        _argToken,
        abbr: 't',
        help: 'Open API Token for Tinkoff account. '
            'Can contains multiple tokens, separated by comma.',
        valueHelp: 'TOKEN',
      )
      ..addOption(
        _argType,
        abbr: 'w',
        help: 'What to export',
        valueHelp: 'TYPE',
        allowed: _ExportType.values.map((e) => e.name),
        allowedHelp: {
          _ExportType.portfolio.name: 'Export porfolio.',
          _ExportType.operations.name:
              'Export operations in specified dates range.',
        },
        defaultsTo: _ExportType.portfolio.name,
      )
      ..addOption(
        _argRange,
        abbr: 'r',
        help: 'Date range to export. You can:\n'
            '- specify 2 dates (inclusively), e.g. -r2021/06/13-2021/06/15;\n'
            '- specify numbers of previous days, '
            'e.g. -r-7d exports today and 6 previous days (-r-1 means today);\n',
        valueHelp: 'YYYY/MM/DD-YYYY/MM/DD',
      );
  }

  @override
  Future<int> run() async {
    final token = argResults?[_argToken] as String?;
    final type = (argResults?[_argType] as String).toExportType();

    if (token == null) {
      printUsage();
      return success();
    }

    final tokens = token.split(',');
    final tinkoff = MultiTinkoff(tokens: tokens, debug: isVerbose);

    try {
      // TODO: make an arg
      final path = p.join(
        p.current,
        p.setExtension(
            DateTime.now().toIso8601String().replaceAll(':', '_'), '.xlsx'),
      );

      File file;
      switch (type) {
        case _ExportType.portfolio:
          file = await tinkoff.exportPortfolioToExcel(path);
          break;
        case _ExportType.operations:
          final range = _getArgRange();
          if (range == null) {
            printUsage();
            return error(
              2,
              message:
                  'Define date range for export with argument --$_argRange',
            );
          }
          printVerbose('Dates range: $range');

          file = await tinkoff.exportOperationsToExcel(path, range);
          break;
      }

      return success(message: 'Exported to ${file.path}');
    } catch (e) {
      return error(1, message: 'Failed by: $e');
    }
  }

  DateRange? _getArgRange() {
    final input = argResults?[_argRange] as String?;
    if (input == null) return null;

    DateTime? start;
    DateTime? end;

    if (input.startsWith('-')) {
      // -{days}d
      if (input.endsWith('d')) {
        final days = int.tryParse(input.substring(1, input.length - 1));
        if (days != null && days > 0) {
          end = DateTime.now();
          start = DateTime(end.year, end.month, end.day - days + 1);
        }
      }
    } else {
      final parts = input.split('-');
      if (parts.length != 2) return null;

      start = _parseDate(parts[0]);
      end = _parseDate(parts[1]);

      if (end != null) end = DateUtils.nextDay(end);
    }

    if (start == null || end == null || !start.isBefore(end)) return null;

    return DateRange(start, end);
  }

  DateTime? _parseDate(String raw) {
    final parts = raw.split('/');
    if (parts.length != 3) return null;
    if (parts[0].length != 4) return null;
    final year = int.tryParse(parts[0]);
    if (year == null) return null;
    final month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) return null;
    final day = int.tryParse(parts[2]);
    if (day == null || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }
}

enum _ExportType {
  portfolio,
  operations,
}

extension _ExportTypeExtension on _ExportType {
  String get name => toString().split('.').last;
}

extension _StringExtension on String {
  _ExportType toExportType() => const _ExportTypeConverter().convert(this);
}

class _ExportTypeConverter {
  const _ExportTypeConverter();

  _ExportType convert(String value) =>
      _ExportType.values.firstWhere((e) => e.name == value);
}
