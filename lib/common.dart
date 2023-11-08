import 'dart:convert';

class NodeVerItem {
  final String version;
  final String date;
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

  static decode(String str) {
    final decoded = json.decode(str);
    var lts = decoded['lts'];
    if (lts is bool) {
      lts = null;
    }

    return NodeVerItem(
      version: decoded['version'],
      date: decoded['date'],
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

sealed class CurrentOS {}

class Linux extends CurrentOS {}

class MacOs extends CurrentOS {}

class Windows extends CurrentOS {}

String getVersionCodename(String version) => "${version.split('.')[0]}.x";
String getLtsCodename(String version) => version.toLowerCase();
String getCodename(NodeVerItem version) {
  final defVersion = getVersionCodename(version.version);
  final defLts = getLtsCodename(version.version);
  return version.lts == null ? defLts : defVersion;
}
