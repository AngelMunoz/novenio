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
