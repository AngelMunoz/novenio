import 'dart:developer';
import 'dart:io';
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

Future<void> _createJunction(String path, String target) async {
  final process = await Process.run("mklink.exe", ["/J", path, target]);
  if (process.exitCode != 0) {
    throw CreateJunctionException(
        "Failed to create junction: ${process.stderr}");
  }
}

Future<void> makeExecutable(String path) async {
  final process = await Process.run("chmod", ["+x", path]);
  if (process.exitCode != 0) {
    throw Exception("Failed to make executable: ${process.stderr}");
  }
}

createSymlinkOrJunction(String path, String target) async {
  try {
    final link = await Link(path).create(target, recursive: true);

    return link.uri;
  } on FileSystemException catch (ex) {
    if (Platform.isWindows) {
      log("Failed to create symlink, trying to create junction", error: ex);

      await _createJunction(path, target);
      return Uri.directory(path);
    } else {
      rethrow;
    }
  }
}

Future<void> removeSymlink(String target) async {
  final link = Link(target);
  await link.delete(recursive: true);
}

Future<Directory> extractFile(File tmpFile, String target) async {
  if (Platform.isWindows) {
    final input = InputFileStream(tmpFile.path);
    final zip = ZipDecoder().decodeBuffer(input);
    await extractArchiveToDiskAsync(zip, target);
  } else {
    final input = InputStream(tmpFile.path);
    final gzip = GZipDecoder().decodeBuffer(input);
    final archive = TarDecoder().decodeBytes(gzip);

    await extractArchiveToDiskAsync(archive, target);
  }
  return Directory(target);
}

abstract class BashEditor {
  final File profile;

  BashEditor(this.profile);

  Future<bool> findOrExportNovenio();
}

abstract class NovFs {
  Future<Uri> linkNode(String version);

  Future<Uri> updateLink(String version);

  Future<Iterable<Directory>> enumerateLocalNodes();

  Future<Directory> extractFromArchive(File archive, String target);
}

abstract class NovHttp {
  Future<File> downloadList(String writeTo);

  Future<File> downloadNode(String version, OSKind os, ArchitectureKind arch);
}
