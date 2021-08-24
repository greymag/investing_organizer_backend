import 'dart:io';

import 'package:in_date_range/in_date_range.dart';
import 'package:investing_organizer/cli/args/parsers/date_range_arg_parser.dart';
import 'package:investing_organizer/cli/commands/warren_command.dart';
import 'package:investing_organizer/integrations/tinkoff/multi_tinkoff.dart';
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
        help: 'Date range to export. ${DateRangeArgParser.helpExamples}',
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

  DateRange? _getArgRange() => argResults.dateRange(_argRange);
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
