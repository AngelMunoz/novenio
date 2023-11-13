import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';

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

sealed class OSKind {}

class Linux extends OSKind {}

class MacOs extends OSKind {}

class Windows extends OSKind {}

sealed class ArchitectureKind {}

class Arm extends ArchitectureKind {}

class Arm64 extends ArchitectureKind {}

class X86 extends ArchitectureKind {}

class X64 extends ArchitectureKind {}

String _dateToString(DateTime date) {
  final year = date.year;
  String month = '${date.month}'.padLeft(2, '0');

  String day = '${date.day}'.padLeft(2, '0');

  return "$year-$month-$day";
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

Map<String, dynamic> nodeVersionToMap(NodeVerItem item) {
  return {
    'version': item.version,
    'date': _dateToString(item.date),
    'files': item.files,
    'npm': item.npm,
    'v8': item.v8,
    'uv': item.uv,
    'zlib': item.zlib,
    'openssl': item.openssl,
    'modules': item.modules,
    'lts': item.lts,
    'security': item.security,
  };
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

Level levelOfString(String level) {
  switch (level) {
    case 'info':
      return Level.INFO;
    case 'debug':
      return Level.FINE;
    case 'verbose':
      return Level.FINER;
    case 'trace':
      return Level.FINEST;
    case 'warning':
      return Level.WARNING;
    case 'error':
      return Level.SEVERE;
    case 'fatal':
      return Level.SHOUT;
    case 'all':
      return Level.ALL;
    case 'off':
      return Level.OFF;
    default:
      return Level.INFO;
  }
}
