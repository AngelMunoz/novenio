import 'dart:convert';
import 'dart:developer';
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
    final String? appDataDir = Platform.environment['APPDATA'];
    return path.join(appDataDir ?? SysInfo.userDirectory, '.novenio');
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

Future<Directory> extractFile(String compressedFilePath, String version) async {
  final uncompressedTarget = getNovenioDir();
  final nestedUncompressedFilePath = path.basename(
      compressedFilePath.replaceAll('.tar.gz', '').replaceAll('.zip', ''));

  try {
    await Directory(path.join(uncompressedTarget, version))
        .delete(recursive: true);
  } on PathNotFoundException {
    // ignore
  }

  if (Platform.isWindows) {
    final input = InputFileStream(compressedFilePath);
    final zip = ZipDecoder().decodeBuffer(input);
    await extractArchiveToDiskAsync(zip, uncompressedTarget);
  } else {
    final input = InputFileStream(compressedFilePath);
    final gzip = GZipDecoder().decodeBuffer(input);
    final archive = TarDecoder().decodeBytes(gzip);

    await extractArchiveToDiskAsync(archive, uncompressedTarget);
  }

  final uncompressedDir =
      path.join(uncompressedTarget, nestedUncompressedFilePath);
  final normalizedUncompressedDir = path.join(uncompressedTarget, version);

  await Directory(uncompressedDir).rename(normalizedUncompressedDir);
  return Directory(uncompressedTarget);
}

Future<File> saveIndexToDisk(List<NodeVerItem> index) async {
  final dir = getNovenioDir();
  final content = index.map(nodeVersionToMap).toList();

  await Directory(dir).create(recursive: true);

  final indexFile = File(path.join(dir, 'index.json'));
  return await indexFile.writeAsString(jsonEncode(content));
}
