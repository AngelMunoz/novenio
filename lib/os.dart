import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:fpdart/fpdart.dart';
import 'package:novenio/constants.dart';
import 'package:system_info2/system_info2.dart';
import 'package:novenio/common.dart';

(OSKind, ArchitectureKind) getOsAndArch() {
  final os = switch (SysInfo.operatingSystemName) {
    'Windows' => Windows(),
    'MacOS' || 'iOS' => MacOs(),
    _ => Linux(),
  };
  final arch = switch (SysInfo.rawKernelArchitecture) {
    'x86_64' => X64(),
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
