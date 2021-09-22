import 'dart:io';

import 'package:investing_organizer/cli/args/parsers/date_range_arg_parser.dart';
import 'package:investing_organizer/cli/commands/warren_command.dart';
import 'package:investing_organizer/reports/reporter/summary/summary_reporter.dart';
import 'package:investing_organizer/reports/reporter/summary/summary_reporter_source_ib_report.dart';
import 'package:investing_organizer/reports/reporter/summary/summary_reporter_source_tinkoff.dart';
import 'package:path/path.dart' as p;

/// Command to export summary data from all account.
class ExportSummaryCommand extends WarrenCommand {
  static const _argType = 'type';
  static const _argTinkoffToken = 'tinkoff_token';
  static const _argIBReportToken = 'ib_report';
  static const _argDates = 'dates';

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
      )
      ..addOption(
        _argIBReportToken,
        abbr: 'r',
        help: 'Path to Interactive Brokers report csv file.',
        valueHelp: 'PATH',
      )
      ..addOption(
        _argDates,
        abbr: 'd',
        help: 'Date range to export operations. '
            '${DateRangeArgParser.helpExamples}',
        valueHelp: 'YYYY/MM/DD-YYYY/MM/DD',
      );
  }

  @override
  Future<int> run() async {
    final type = (argResults?[_argType] as String).toExportType();
    final reporter = SummaryReporter(debug: isVerbose);

    try {
      // TODO: make an arg
      final now = DateTime.now();
      final todayDate = now.toIso8601String().split('T').first;
      final path = _getNotExistPath('${todayDate}_${type.name}', '.xlsx');

      printVerbose('Start export summary');

      final tinkoffToken = argResults?[_argTinkoffToken] as String?;
      if (tinkoffToken != null && tinkoffToken.isNotEmpty) {
        printVerbose('Add Tinkoff source');
        final tokens = tinkoffToken.split(',');
        reporter.addSource(
            SummaryReporterSourceTinkoff(tokens: tokens, debug: isVerbose));
      }

      final ibReportPath = argResults?[_argIBReportToken] as String?;
      if (ibReportPath != null) {
        printVerbose('Add IB Report source');
        reporter.addSource(SummaryReporterSourceIBReport.csvPath(ibReportPath));
      }

      File? file;
      switch (type) {
        case _ExportType.portfolio:
          printVerbose('Export portfolio');
          file = await reporter.exportPortfolioToExcel(path);
          break;
        case _ExportType.operations:
          final range = argResults.dateRange(_argDates);
          if (range == null) {
            printUsage();
            return error(
              2,
              message: 'Define date range for export with and argument '
                  '--$_argDates',
            );
          }

          printVerbose('Export operations for range: $range');
          file = await reporter.exportOperationsToExcel(path, range);
          break;
      }

      if (file != null) {
        return success(message: 'Exported to ${file.path}');
      } else {
        return success(message: 'Nothing to export');
      }
    } catch (e, st) {
      printVerbose('Exception: $e\n$st');
      return error(2, message: 'Failed by: $e');
    }
  }

  String _getNotExistPath(String baseName, String extension) {
    final basePath = p.join(p.current, baseName);

    var i = 0;
    while (i < 1e+10) {
      var tmpBasePath = basePath;
      if (i > 0) tmpBasePath += '_$i';

      final path = p.setExtension(tmpBasePath, extension);
      if (!File(path).existsSync()) {
        return path;
      } else {
        i++;
      }
    }

    throw Exception("Can't generate unique path");
  }
}

// TODO: separate
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
