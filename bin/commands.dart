import 'package:args/command_runner.dart';
import 'package:ioc_container/ioc_container.dart';
import 'package:logging/logging.dart';
import 'package:novenio/extensions.dart';
import 'types.dart';

class InstallCommand extends Command<CommandResult> {
  @override
  String get description => "Installs the specified node version";

  @override
  String get name => "install";

  late final Logger _logger;
  late final void Function(Level level) setLogLevel;

  InstallCommand(IocContainer container) {
    _logger = container.get();
    setLogLevel = container.get();

    argParser
      ..addOption("version",
          abbr: 'v',
          help: "Install the specified node version",
          defaultsTo: null)
      ..addFlag("lts",
          help: "Install the latest LTS version or the latest Current release.",
          negatable: true,
          defaultsTo: true)
      ..addFlag("default",
          abbr: 'd',
          help: "Install the specified node version as default",
          negatable: false,
          defaultsTo: true);
  }

  @override
  Future<InstallVersion> run() async {
    final String? logLevel = globalResults?['log-level'];

    if (logLevel != null && logLevel.isNotEmpty) {
      setLogLevel(levelOfString(logLevel));
    }

    final InstallArgs cmdArgs = InstallArgs(
        argResults!['lts'], argResults!['default'], argResults?['version']);
    _logger.debug("Installing node with args: ${cmdArgs}");

    return InstallVersion();
  }
}

class UninstallCommand extends Command<CommandResult> {
  @override
  String get description => "Uninstalls the specified node version";

  @override
  // TODO: implement name
  String get name => "uninstall";
}

class UseCommand extends Command<CommandResult> {
  @override
  String get description => "Sets the specified node version as default";

  @override
  String get name => "use";
}

class ListCommand extends Command<CommandResult> {
  @override
  String get description => "Lists all installed node versions";

  @override
  String get name => "list";
}

class ImportFromVersionCommand extends Command<CommandResult> {
  @override
  String get description => "Imports node packages from the specified version";

  @override
  String get name => "import";
}
