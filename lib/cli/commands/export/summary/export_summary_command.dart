import 'dart:io';

import 'package:investing_organizer/cli/args/parsers/date_range_arg_parser.dart';
import 'package:investing_organizer/cli/commands/warren_command.dart';
import 'package:investing_organizer/cli/exceptions/run_exception.dart';
import 'package:investing_organizer/reports/reporter/summary/summary_reporter.dart';
import 'package:investing_organizer/reports/reporter/summary/summary_reporter_source_ib_report.dart';
import 'package:investing_organizer/reports/reporter/summary/summary_reporter_source_tinkoff.dart';
import 'package:path/path.dart' as p;
import 'package:list_ext/list_ext.dart';

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

      final exported = <File>[];
      switch (type) {
        case _ExportType.portfolio:
          final file = await _exportPortfolio(reporter);
          exported.addIfNotNull(file);
          break;
        case _ExportType.operations:
          final file = await _exportOperations(reporter);
          exported.addIfNotNull(file);
          break;
        case _ExportType.all:
          printVerbose('Export all');
          exported
            ..addIfNotNull(await _exportPortfolio(reporter))
            ..addIfNotNull(await _exportOperations(reporter));
          break;
      }

      final String message;

      if (exported.isEmpty) {
        message = 'Nothing to export';
      } else if (exported.length == 1) {
        message = 'Exported to ${exported.first.path}';
      } else {
        final paths = exported.map((e) => e.path).join('\n');
        message = 'Exported:\n$paths';
      }

      if (exported.length == 1) {
        return success(message: 'Exported to ${exported.first.path}');
      } else {}
      return success(message: message);
    } on RunException catch (e) {
      return exception(e);
    } catch (e, st) {
      printVerbose('Exception: $e\n$st');
      return error(2, message: 'Failed by: $e');
    }
  }

  Future<File?> _exportPortfolio(SummaryReporter reporter) async {
    printVerbose('Export portfolio');
    final path = _getTargetFilePath(_ExportType.portfolio);
    return reporter.exportPortfolioToExcel(path);
  }

  Future<File?> _exportOperations(SummaryReporter reporter) async {
    final path = _getTargetFilePath(_ExportType.operations);
    final range = argResults.dateRange(_argDates);
    if (range == null) {
      printUsage();
      throw RunException.err(
          'Define date range for export with and argument --$_argDates');
    }

    printVerbose('Export operations for range: $range');
    return reporter.exportOperationsToExcel(path, range);
  }

  String _getTargetFilePath(_ExportType type) {
    final now = DateTime.now();
    final todayDate = now.toIso8601String().split('T').first;
    return _getNotExistPath('${todayDate}_${type.name}', '.xlsx');
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
enum _ExportType { portfolio, operations, all }

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
