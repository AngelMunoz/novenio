import 'dart:io';

import 'package:logging/logging.dart';
import 'package:novenio/common.dart';
import 'package:novenio/extensions.dart';
import 'package:novenio/network.dart';
import 'package:novenio/novenio.dart';
import 'package:novenio/os.dart';
import 'types.dart';

Future<CommandResult> runInstall(Logger logger, InstallArgs args) async {
  logger.debug("Installing node with args: $args");

  logger.info("Fetching node versions...");

  final (os, arch) = getOsAndArch();
  logger
      .debug("Detected OS: ${os.asString} and Architecture: ${arch.asString}");

  final versions = await getNodeVersions(logger, true);
  logger.debug("Fetched '${versions.length}' versions");

  final index = await saveIndexToDisk(versions);
  logger.info("Saved node index at: ${index.path}");

  late final NodeVerItem? version;

  if (args.custom != null) {
    logger.debug("Custom version specified: ${args.custom}");
    version = getNodeVersion(args.custom!, versions);
  } else {
    if (args.isLts) {
      logger.info("Resolving the latest LTS version");
      version = versions.where((element) => element.lts != null).firstOrNull;
    } else {
      logger.info("Resolving the latest Current version");
      version = versions.where((element) => element.lts == null).firstOrNull;
    }
  }

  if (version == null) {
    logger.error("No version found");
    return CommandFailure("No version found");
  }

  logger.info("Fetching node version from network: ${version.version}");

  final compressed = await fetchNode(version, os, arch);
  if (compressed == null) {
    logger.error("Failed to fetch node version");
    return CommandFailure("Failed to fetch node version");
  }

  logger.debug("Fetched node version at: ${compressed.path}");

  final extracted = await extractFile(compressed.path, version.version);

  logger.debug("Extracted node version at: ${extracted.path}");

  try {
    await removeCompressedFile(compressed);
  } catch (error) {
    logger.warning("Failed to delete '${compressed.path}'", error);
  }

  if (args.setDefault) {
    logger.info("Setting node ${version.version} as default");
    final linkUri = await setCurrentNode(logger, version);
    logger.debug("Set node ${version.version} as default at: ${linkUri.path}");
    if (Platform.environment['NOVENIO_HOME'] == null) {
      logger.info("Setting up Novenio's environment variables");
      await setEnvVars(logger);
    }
  }

  return CommandSuccess();
}
