import 'package:investing_organizer/cli/commands/warren_command.dart';
import 'package:investing_organizer/integrations/tinkoff/tinkoff.dart';
import 'package:path/path.dart' as p;

/// Command to export data from Tinkoff account.
class ExportTinkoffCommand extends WarrenCommand {
  static const _argToken = 'token';

  ExportTinkoffCommand()
      : super('tinkoff', 'Export data from Tinkoff account.') {
    argParser
      ..addOption(
        _argToken,
        abbr: 't',
        help: 'Open API Token for Tinkoff account',
        valueHelp: 'TOKEN',
      );
  }

  @override
  Future<int> run() async {
    final token = argResults?[_argToken] as String?;

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
      final file = await tinkoff.export(path);
      return success(message: 'Exported to ${file.path}');
    } catch (e) {
      return error(1, message: 'Failed by: $e');
    }
  }
}
