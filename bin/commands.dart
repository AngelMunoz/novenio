import 'package:args/command_runner.dart';
import 'package:ioc_container/ioc_container.dart';
import 'package:logging/logging.dart';

import 'package:novenio/common.dart';
import 'package:novenio/extensions.dart';

import 'handlers.dart' as handlers;
import 'types.dart';

abstract class NovenioCommand<T> extends Command<T> {
  late final Logger logger;
  late final void Function(Level level) _setLogLevel;
  NovenioCommand(IocContainer container) {
    logger = container.get();
    _setLogLevel = container.get();
  }

  @override
  run() {
    final String? logLevel = globalResults?['log-level'];

    if (logLevel != null && logLevel.isNotEmpty) {
      _setLogLevel(levelOfString(logLevel));
    }
    return null;
  }
}

class InstallCommand extends NovenioCommand<CommandResult> {
  @override
  String get description => "Installs the specified node version";

  @override
  String get name => "install";

  InstallCommand(super.container) {
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
          defaultsTo: false);
  }

  @override
  Future<CommandResult> run() async {
    super.run();

    final InstallArgs cmdArgs = InstallArgs(
        argResults!['lts'], argResults!['default'], argResults?['version']);

    try {
      return handlers.runInstall(logger, cmdArgs);
    } catch (ex) {
      logger.error("Failed to install node version", ex);
      return CommandFailure("Failed to install node version");
    }
  }
}

class RemoveNodeCommand extends NovenioCommand<CommandResult> {
  @override
  String get description => "Remvoes the specified node version";

  @override
  // TODO: implement name
  String get name => "remove";

  RemoveNodeCommand(super.container) {
    argParser.addOption("version",
        abbr: 'v', help: "Remove the specified node version", mandatory: true);
  }

  @override
  Future<CommandResult> run() async {
    super.run();

    final args = RemoveNodeArgs(argResults!['version']);

    logger.debug("Removing node with args: $args");

    return CommandSuccess();
  }
}

class UseCommand extends NovenioCommand<CommandResult> {
  @override
  String get description => "Sets the specified node version as default";

  @override
  String get name => "use";

  UseCommand(super.container) {
    argParser
      ..addOption("version",
          abbr: 'v', help: "Use the specified node version", mandatory: true)
      ..addOption("import-from",
          help: "Import packages from the specified node version");
  }

  @override
  Future<CommandResult> run() async {
    super.run();

    final UseArgs args =
        UseArgs(argResults!['version'], argResults!['import-from']);

    logger.debug("Using node with args: $args");

    return CommandSuccess();
  }
}

class ListCommand extends NovenioCommand<CommandResult> {
  @override
  String get description => "Lists all installed node versions";

  @override
  String get name => "list";

  ListCommand(super.container) {
    argParser
      ..addFlag("remote",
          abbr: 'r',
          help: "List all available node versions",
          negatable: false,
          defaultsTo: false)
      ..addFlag("update",
          abbr: 'u',
          help: "Update the list of available node versions",
          negatable: false,
          defaultsTo: false);
  }

  @override
  Future<CommandResult> run() async {
    super.run();

    final ListArgs args =
        ListArgs(argResults!['remote'], argResults!['update']);

    logger.debug("Listing node with args: $args");

    return CommandSuccess();
  }
}

class ImportFromVersionCommand extends NovenioCommand<CommandResult> {
  @override
  String get description => "Imports node packages from the specified version";

  @override
  String get name => "import";

  ImportFromVersionCommand(super.container) {
    argParser
      ..addOption("from",
          abbr: 'f',
          help: "Import packages from the specified node version",
          mandatory: true)
      ..addOption("to",
          abbr: 't',
          help: "Import packages to the specified node version",
          mandatory: true);
  }

  @override
  Future<CommandResult> run() async {
    super.run();

    final ImportArgs args = ImportArgs(argResults!['from'], argResults!['to']);

    logger.debug("Importing node with args: $args");

    return CommandSuccess();
  }
}
