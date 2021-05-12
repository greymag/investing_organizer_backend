import 'package:args/command_runner.dart';
import 'package:investing_organizer/cli/out/out.dart' as out;
import 'package:investing_organizer/cli/runner.dart';

Future<int?> run(List<String> args) async {
  try {
    return await WarrenCommandRunner().run(args);
  } on UsageException catch (e) {
    out.exception(e);
    return 64;
  } catch (e) {
    out.exception(e);
    return -1;
  }
}
