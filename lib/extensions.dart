import 'package:logging/logging.dart';
import 'package:novenio/common.dart';

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

String getVersionDirName(OSKind os, ArchitectureKind arch, String version) {
  final fOs = os.asString;
  final fArch = arch.asString;
  final fVersion = version.startsWith('v') ? version : 'v$version';
  return "node-$fVersion-$fOs-$fArch";
}
