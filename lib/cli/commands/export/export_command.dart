import 'package:investing_organizer/cli/commands/export/tinkoff/export_tinkoff_command.dart';
import 'package:investing_organizer/cli/commands/warren_command.dart';

/// Command to export data.
class ExportCommand extends WarrenCommand {
  ExportCommand()
      : super('export', 'Export data', subcommands: [
          ExportTinkoffCommand(),
        ]);

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}
