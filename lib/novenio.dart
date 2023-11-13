import 'dart:io';

import 'package:novenio/extensions.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

import 'package:novenio/common.dart';
import 'package:novenio/network.dart';
import 'package:novenio/os.dart';

Future<List<NodeVerItem>> getNodeVersions(Logger logger,
    [bool online = false]) async {
  List<NodeVerItem>? index = await fetchNodeIndexFromDisk();

  if (online || index == null) {
    index = await fetchNodeIndex();
  }

  return index ?? [];
}

Future<Uri> setCurrentNode(Logger logger, NodeVerItem version) async {
  final dir = getNovenioDir();
  final symlinkPath = path.join(dir, 'current');
  final versionPath = Platform.isWindows
      ? path.join(dir, version.version)
      : path.join(dir, version.version, "bin");

  logger.info("Setting node version from: $versionPath to: $symlinkPath");
  try {
    await removeSymlink(symlinkPath);
  } on PathNotFoundException {
    // ignore
    logger.debug("No symlink found at: $symlinkPath, not failing.");
  }

  final currentSymlink =
      await createSymlinkOrJunction(logger, versionPath, symlinkPath);

  if (Platform.isMacOS || Platform.isLinux) {
    final versionpath = path.join(dir, version.version);
    logger.info("Running 'chmod +x' on: $versionpath");
    await makeExecutable(versionpath);
  }

  return currentSymlink;
}
