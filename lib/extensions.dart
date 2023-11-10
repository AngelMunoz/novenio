import 'package:logging/logging.dart';
import 'package:novenio/common.dart';

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

extension LoggerLevelExtensions on Level {
  String get asString => switch (this) {
        Level.FINEST || Level.ALL => "TRA",
        Level.FINER => "VER",
        Level.FINE => "DEB",
        Level.CONFIG || Level.INFO => "INF",
        Level.WARNING => "WAR",
        Level.SEVERE => "ERR",
        Level.SHOUT => "FAT",
        _ => "OFF",
      };
}

extension LoggerExtensions on Logger {
  void error(Object? message, [Object? error, StackTrace? stackTrace]) {
    log(Level.SEVERE, message, error, stackTrace);
  }

  void warn(Object? message, [Object? error, StackTrace? stackTrace]) {
    log(Level.WARNING, message, error, stackTrace);
  }

  void fatal(Object? message, [Object? error, StackTrace? stackTrace]) {
    log(Level.SHOUT, message, error, stackTrace);
  }

  void debug(Object? message, [Object? error, StackTrace? stackTrace]) {
    log(Level.FINE, message, error, stackTrace);
  }

  void trace(Object? message, [Object? error, StackTrace? stackTrace]) {
    log(Level.FINEST, message, error, stackTrace);
  }

  void verbose(Object? message, [Object? error, StackTrace? stackTrace]) {
    log(Level.FINER, message, error, stackTrace);
  }
}

extension InstallTypeExtensions on InstallType {
  String get asString => switch (this) {
        Lts() => "lts",
        Current() => "current",
        SpecificM(major: final major) => major,
        SpecificMM(major: final major, minor: final minor) => "$major.$minor",
        SpecificMMP(
          major: final major,
          minor: final minor,
          patch: final patch
        ) =>
          "$major.$minor.$patch"
      };
}

extension CurrentOsExtensions on OSKind {
  String get asString => switch (this) {
        Linux() => "linux",
        MacOs() => "darwin",
        Windows() => "win",
      };
}

extension CurrentArchExtensions on ArchitectureKind {
  String get asString => switch (this) {
        Arm() => "armv7l",
        Arm64() => "arm64",
        X86() => "x86",
        X64() => "x64",
      };
}

extension ExtractVersionItem on List<NodeVerItem> {
  NodeVerItem? parseVersionOrSemver(InstallType install) {
    tryExtractLts(List<NodeVerItem> list) {
      try {
        return list.firstWhere((element) => element.lts != null);
      } catch (_) {
        return null;
      }
    }

    tryExtractVersion(List<NodeVerItem> list, String major,
        [String? minor, String? patch]) {
      if (!major.startsWith('v')) {
        major = 'v$major';
      }

      // if minor is null, patch must be null
      if (patch != null && minor == null) {
        patch = null;
      }

      try {
        final fminor = minor != null ? ".$minor" : '';
        final fpatch = patch != null ? ".$patch" : '';

        return list.firstWhere(
            (element) => element.version.contains("$major$fminor$fpatch"));
      } catch (_) {
        return null;
      }
    }

    return switch (install) {
      Lts() => tryExtractLts(this),
      Current() => firstOrNull,
      SpecificM(major: final major) => tryExtractVersion(this, major),
      SpecificMM(major: final major, minor: final minor) =>
        tryExtractVersion(this, major, minor),
      SpecificMMP(major: final major, minor: final minor, patch: final patch) =>
        tryExtractVersion(this, major, minor, patch),
    };
  }
}

String getVersionDirName(OSKind os, ArchitectureKind arch, String version) {
  final fOs = os.asString;
  final fArch = arch.asString;
  return "node-$version-$fOs-$fArch";
}
