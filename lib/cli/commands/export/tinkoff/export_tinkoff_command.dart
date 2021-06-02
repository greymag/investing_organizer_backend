import 'dart:io';

import 'package:investing_organizer/cli/commands/warren_command.dart';
import 'package:investing_organizer/integrations/tinkoff/tinkoff.dart';
import 'package:path/path.dart' as p;

/// Command to export data from Tinkoff account.
class ExportTinkoffCommand extends WarrenCommand {
  static const _argToken = 'token';
  static const _argType = 'type';

  ExportTinkoffCommand()
      : super('tinkoff', 'Export data from Tinkoff account.') {
    argParser
      ..addOption(
        _argToken,
        abbr: 't',
        help: 'Open API Token for Tinkoff account',
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

    final tinkoff = Tinkoff(token: token, debug: isVerbose);

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
          file = await tinkoff.exportPortfolio(path);
          break;
        case _ExportType.operations:
          file = await tinkoff.exportOperations(path);
          break;
      }

      return success(message: 'Exported to ${file.path}');
    } catch (e) {
      return error(1, message: 'Failed by: $e');
    }
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
