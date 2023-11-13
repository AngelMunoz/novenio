import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:novenio/extensions.dart';
import 'package:path/path.dart' as path;
import 'package:fpdart/fpdart.dart';
import 'package:system_info2/system_info2.dart';
import 'package:archive/archive_io.dart';
import 'package:novenio/constants.dart';
import 'package:novenio/common.dart';

class CreateJunctionException extends IOException {
  final String message;

  CreateJunctionException(this.message);
}

(OSKind, ArchitectureKind) getOsAndArch() {
  late final OSKind os;
  if (Platform.isWindows) {
    os = Windows();
  } else if (Platform.isMacOS) {
    os = MacOs();
  } else if (Platform.isLinux) {
    os = Linux();
  } else {
    throw Exception('Unknown OS: ${Platform.operatingSystem}');
  }

  final arch = switch (SysInfo.rawKernelArchitecture.toLowerCase()) {
    'x86_64' || 'amd64' => X64(),
    'x86' => X86(),
    'arm64' => Arm64(),
    'arm' => Arm(),
    _ =>
      throw Exception('Unknown architecture: ${SysInfo.rawKernelArchitecture}'),
  };
  return (os, arch);
}

String getNovenioDir() {
  return Platform.environment.extract<String>(novenioHome).match(() {
    final String novenioParentDir =
        Platform.environment['APPDATA'] ?? SysInfo.userDirectory;
    final String novenioName = Platform.isWindows ? 'novenio' : '.novenio';

    return path.join(novenioParentDir, novenioName);
  }, (t) => t);
}

Future<List<NodeVerItem>?> fetchNodeIndexFromDisk() async {
  try {
    final indexFile = File(path.join(getNovenioDir(), 'index.json'));
    final index = await indexFile.readAsBytes();
    final List<dynamic> items = jsonDecode(utf8.decode(index));
    final decoded = items
        .map(nodeVersionFromDynamic)
        .sortWith((t) => t.date, Order.orderDate.reverse);

    return decoded.toList();
  } on FileSystemException {
    return null;
  }
}

Future<void> _createJunction(String path, String target) async {
  final process = await Process.run("mklink.exe", ["/J", path, target]);
  if (process.exitCode != 0) {
    throw CreateJunctionException(
        "Failed to create junction: ${process.stderr}");
  }
}

Future<void> makeExecutable(String path) async {
  final process = await Process.run("chmod", ["--recursive", "+x", path]);
  if (process.exitCode != 0) {
    throw Exception("Failed to make executable: ${process.stderr}");
  }
}

Future<Uri> createSymlinkOrJunction(
    Logger logger, String path, String target) async {
  try {
    final link = await Link(target).create(path, recursive: true);

    return link.uri;
  } on FileSystemException catch (ex) {
    logger.debug("Failed to create symlink: $ex");
    if (Platform.isWindows) {
      logger.debug("We're on windows, we'll try to create a junction.");

      await _createJunction(path, target);
      return Uri.directory(target);
    } else {
      logger.trace('Unable to create the junction, rethrowing...');
      rethrow;
    }
  }
}

Future<void> removeSymlink(String target) async {
  final link = Link(target);
  await link.delete(recursive: true);
}

Future<void> removeCompressedFile(File compressed) async {
  if (Platform.isWindows) {
    await Process.run(
        "powershell.exe", ["-Command", "Remove-Item", compressed.path]);
  } else {
    await compressed.delete();
  }
}

Future<void> _moveDirectory(source, target) async {
  if (Platform.isWindows) {
    await Process.run("powershell.exe",
        ["-Command", "Move-Item", "-Path", source, "-Destination", target]);
  } else {
    await Directory(source).rename(target);
  }
}

Future<Directory> extractFile(String archivePath, String version) async {
  final novenioDir = getNovenioDir();
  // Name of the extracted zip/tar.gz directory e.g. node-v14.17.0-linux-x64/node-v14.17.0-win-x64
  final afterExtractionName = path
      .basename(archivePath.replaceAll('.tar.gz', '').replaceAll('.zip', ''));

  try {
    await Directory(path.join(novenioDir, version)).delete(recursive: true);
  } on PathNotFoundException {
    // ignore
  }

  if (Platform.isWindows) {
    final input = InputFileStream(archivePath);
    final zip = ZipDecoder().decodeBuffer(input);
    await extractArchiveToDiskAsync(zip, novenioDir);
  } else {
    final input = InputFileStream(archivePath);
    final gzip = GZipDecoder().decodeBuffer(input);
    final archive = TarDecoder().decodeBytes(gzip);

    await extractArchiveToDiskAsync(archive, novenioDir);
  }

  // After the archive has been extracted this is where it will reside.
  final afterExtractionPath = path.join(novenioDir, afterExtractionName);

  // Name of the versioned directory e.g. v14.17.0
  final versionedPath = path.join(novenioDir, version);

  // After the archive has been extracted we'll want to move it to match the node version it contains.
  await _moveDirectory(afterExtractionPath, versionedPath);

  return Directory(versionedPath);
}

Future<File> saveIndexToDisk(List<NodeVerItem> index) async {
  final dir = getNovenioDir();
  final content = index.map(nodeVersionToMap).toList();

  await Directory(dir).create(recursive: true);

  final indexFile = File(path.join(dir, 'index.json'));
  return await indexFile.writeAsString(jsonEncode(content));
}

Future<void> _setEnvVarWin(String name, String value) async {
  final process = await Process.run("powershell.exe", [
    "-Command",
    "[Environment]::SetEnvironmentVariable('$name', '$value', 'USER')"
  ]);

  if (process.exitCode != 0) {
    throw Exception("Failed to set env var: ${process.stderr}");
  }
}

Future<void> _setEnvVarUnixLike(String name, String value) async {
  final profileName = Platform.isMacOS ? '.zprofile' : '.profile';
  final profileFile = path.join(SysInfo.userDirectory, profileName);
  final contents = "\nexport $name=$value\n";
  await File(profileFile).writeAsString(contents, mode: FileMode.append);
}

Future<void> setEnvVars(Logger logger) async {
  final novenioDir = getNovenioDir();

  if (Platform.isWindows) {
    await _setEnvVarWin(novenioHome, novenioDir);
    logger.debug("Set $novenioHome to $novenioDir");
    final novenioNodeDir = path.join(novenioDir, 'current');
    await _setEnvVarWin(novenioNode, novenioNodeDir);

    logger.debug("Set $novenioDir to $novenioNodeDir");

    logger.info(
        "Set $novenioHome and $novenioNode environment variables to the current user.");
    logger.info(
        "Please note that you have to manually add NOVENIO_NODE to your PATH environment");
    logger.info("You can do so by opening 'SystemPropertiesAdvanced.exe'");
    logger.info(
        "Click on the 'Environment Variables...' button and add '%$novenioNode%' to you user's PATH");
  } else {
    await _setEnvVarUnixLike(novenioHome, novenioDir);
    logger.debug("Set $novenioHome to $novenioDir");
    final novenioNodeDir = path.join(novenioDir, 'current');
    await _setEnvVarUnixLike(novenioNode, path.join(novenioDir, 'current'));
    logger.debug("Set $novenioDir to $novenioNodeDir");
    logger.info("Set $novenioHome and $novenioNode environment variables");
    logger.info(
        "Please note that you have to manually add '\$$novenioNode' to your \$PATH environment");
    logger.info(
        "You can do so by opening your shell's profile file and adding the following line:");
    logger.info("export PATH=\$PATH:\$$novenioNode");
  }

  logger.info(
      "Close your current terminal or log out/log in for it to make effect.");
}
