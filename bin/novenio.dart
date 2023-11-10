import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:ioc_container/ioc_container.dart';
import 'package:novenio/extensions.dart';

import 'commands.dart';
import 'types.dart';

void configureRootLogger([String? level]) {
  Logger.root.level = levelOfString(level ?? 'info');
  Logger.root.onRecord.listen((record) {
    final frecord = record.object != null ? " ${record.object}" : "";
    final stackTrace = record.stackTrace != null ? " ${record.stackTrace}" : "";

    print(
        '[${record.time.toIso8601String()} ${record.level.asString}] ${record.loggerName}: ${record.message}$frecord$stackTrace');
  });
}

IocContainer getContainer() {
  final IocContainerBuilder builder = IocContainerBuilder()
    ..add((container) => Logger("Novenio"))
    ..addSingleton<void Function(Level level)>(
        (container) => (Level level) => Logger.root.level = level);
  return builder.toContainer();
}

Future<void> main(List<String> arguments) async {
  final String? logLevel = Platform.environment['NOVENIO_LOG_LEVEL'];
  configureRootLogger(logLevel);
  final container = getContainer();
  final runner = CommandRunner<CommandResult>(
      "novenio", "A simple node version manager written in dart")
    ..argParser.addOption('log-level', abbr: 'x', allowed: [
      'off',
      'all',
      'fatal',
      'error',
      'warning',
      'trace',
      'verbose',
      'debug',
      'info',
    ])
    ..addCommand(InstallCommand(container))
    ..addCommand(RemoveNodeCommand(container))
    ..addCommand(UseCommand(container))
    ..addCommand(ListCommand(container))
    ..addCommand(ImportFromVersionCommand(container));

  late final result;
  try {
    result = await runner.run(arguments);
  } on UsageException {
    runner.printUsage();
    exit(1);
  } on ArgumentError {
    runner.printUsage();
    exit(1);
  }

  switch (result) {
    case CommandSuccess():
      break;
    case CommandFailure(message: final message):
      Logger.root.error(message);
      exit(1);
    default:
      Logger.root.error("Unknown error");
      exit(1);
  }
  exit(0);
}
