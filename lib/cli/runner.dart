import 'package:args/command_runner.dart';
import 'package:investing_organizer/cli/commands/warren_command.dart';

class WarrenCommandRunner extends CommandRunner<int> {
  WarrenCommandRunner()
      : super('warren',
            'A command line interface for the inversting organizer app.') {
    <WarrenCommand>[].forEach(addCommand);
  }
}
