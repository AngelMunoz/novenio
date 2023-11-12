import 'package:fpdart/fpdart.dart';

class NodeVerItem {
  final String version;
  final DateTime date;
  final List<String> files;
  final String? npm;
  final String? v8;
  final String? uv;
  final String? zlib;
  final String? openssl;
  final String? modules;
  final String? lts;
  final bool? security;

  NodeVerItem({
    required this.version,
    required this.date,
    required this.files,
    this.npm,
    this.v8,
    this.uv,
    this.zlib,
    this.openssl,
    this.modules,
    this.lts,
    this.security,
  });

  @override
  String toString() {
    return """NodeVerItem{
  version: $version,
  date: $date,
  files: $files,
  npm: $npm,
  v8: $v8,
  uv: $uv,
  zlib: $zlib,
  openssl: $openssl,
  moadules: $modules,
  lts: $lts,
  security: $security
}""";
  }
}

sealed class InstallType {}

class Lts extends InstallType {}

class Current extends InstallType {}

class SpecificM extends InstallType {
  final String major;
  SpecificM(this.major);
}

class SpecificMM extends InstallType {
  final String major;
  final String minor;
  SpecificMM(this.major, this.minor);
}

class SpecificMMP extends InstallType {
  final String major;
  final String minor;
  final String patch;
  SpecificMMP(this.major, this.minor, this.patch);
}

sealed class OSKind {}

class Linux extends OSKind {}

class MacOs extends OSKind {}

class Windows extends OSKind {}

sealed class ArchitectureKind {}

class Arm extends ArchitectureKind {}

class Arm64 extends ArchitectureKind {}

class X86 extends ArchitectureKind {}

class X64 extends ArchitectureKind {}

String getVersionCodename(String version) => "${version.split('.')[0]}.x";

String getLtsCodename(String version) => version.toLowerCase();

String getCodename(NodeVerItem version) {
  final defVersion = getVersionCodename(version.version);
  final defLts = getLtsCodename(version.version);
  return version.lts == null ? defLts : defVersion;
}

NodeVerItem nodeVersionFromDynamic(dynamic decoded) {
  var lts = decoded['lts'];
  var date = decoded['date'];
  if (lts is bool) {
    lts = null;
  }

  if (date is String) {
    date = DateTime.parse(date);
  }

  return NodeVerItem(
    version: decoded['version'],
    date: date,
    files: List<String>.from(decoded['files']),
    npm: decoded['npm'],
    v8: decoded['v8'],
    uv: decoded['uv'],
    zlib: decoded['zlib'],
    openssl: decoded['openssl'],
    modules: decoded['modules'],
    lts: lts,
    security: decoded['security'],
  );
}

final RegExp _versionRegex = RegExp(
    r'^v?(?<major>\d{1,2})(\.(?<minor>[x\d]{1,2}))?(\.(?<patch>[x\d]{1,2}))?$');

NodeVerItem? getNodeVersion(
    String versionOrCodename, List<NodeVerItem> versions) {
  final match = _versionRegex.firstMatch(versionOrCodename);
  // no match means the user tried a codename e.g. carbon/argon
  if (match == null) {
    return versions
        .filter((t) => t.lts?.toLowerCase() == versionOrCodename.toLowerCase())
        .firstOrNull;
  }
  final major = int.tryParse(match.namedGroup("major") ?? "");
  final minor = int.tryParse(match.namedGroup("minor") ?? "");
  final patch = int.tryParse(match.namedGroup("patch") ?? "");
  final version = switch ((major, minor, patch)) {
    // latest major
    (int major, null, null) => "v$major.",
    // minor with latest patch
    (int major, int minor, null) => "v$major.$minor.",
    // specific version
    (int major, int minor, int patch) => "v$major.$minor.$patch",
    _ => null,
  };

  if (version == null) {
    return null;
  }

  return versions.filter((t) => t.version.startsWith(version)).firstOrNull;
}
