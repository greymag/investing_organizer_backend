import 'dart:io';

import 'package:investing_organizer/cli/commands/warren_command.dart';
import 'package:investing_organizer/reports/reporter/summary/summary_reporter.dart';
import 'package:investing_organizer/reports/reporter/summary/summary_reporter_source_tinkoff.dart';
import 'package:path/path.dart' as p;

/// Command to export summary data from all account.
class ExportSummaryCommand extends WarrenCommand {
  static const _argType = 'type';
  static const _argTinkoffToken = 'tinkoff_token';

  ExportSummaryCommand()
      : super('summary', 'Export summary data from all account.') {
    argParser
      ..addOption(
        _argType,
        abbr: 'w',
        help: 'What to export',
        valueHelp: 'TYPE',
        allowed: _ExportType.values.map((e) => e.name),
        allowedHelp: {
          _ExportType.portfolio.name: 'Export porfolio.',
          // _ExportType.operations.name:
          // 'Export operations in specified dates range.',
        },
        defaultsTo: _ExportType.portfolio.name,
      )
      ..addOption(
        _argTinkoffToken,
        abbr: 't',
        help: 'Open API Token for Tinkoff account. '
            'Can contains multiple tokens, separated by comma.',
        valueHelp: 'TOKEN',
      );
  }

  @override
  Future<int> run() async {
    final type = (argResults?[_argType] as String).toExportType();
    final reporter = SummaryReporter(debug: isVerbose);

    try {
      // TODO: make an arg
      final path = p.join(
        p.current,
        p.setExtension(
            DateTime.now().toIso8601String().replaceAll(':', '_'), '.xlsx'),
      );

      final tinkoffToken = argResults?[_argTinkoffToken] as String?;
      if (tinkoffToken != null && tinkoffToken.isNotEmpty) {
        final tokens = tinkoffToken.split(',');
        reporter.addSource(
            SummaryReporterSourceTinkoff(tokens: tokens, debug: isVerbose));
      }

      File? file;
      switch (type) {
        case _ExportType.portfolio:
          file = await reporter.exportPortfolioToExcel(path);
          break;
      }

      if (file != null) {
        return success(message: 'Exported to ${file.path}');
      } else {
        return success(message: 'Nothing to export');
      }
    } catch (e) {
      return error(2, message: 'Failed by: $e');
    }
  }
}

// TODO: separate
enum _ExportType {
  portfolio,
  // operations,
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
