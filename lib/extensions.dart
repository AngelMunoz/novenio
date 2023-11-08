import 'package:novenio/common.dart';

extension InstallTypeExtensions on InstallType {
  asString() {
    return switch (this) {
      Lts() => "lts",
      Current() => "current",
      SpecificM(major: final major) => major,
      SpecificMM(major: final major, minor: final minor) => "$major.$minor",
      SpecificMMP(major: final major, minor: final minor, patch: final patch) =>
        "$major.$minor.$patch"
    };
  }
}

extension CurrentOsExtensions on CurrentOS {
  asString() {
    return switch (this) {
      Linux() => "linux",
      MacOs() => "darwin",
      Windows() => "win",
    };
  }
}

extension StringParseExtensions on String {
  InstallType parseVersionOrSemver() {
    throw UnimplementedError();
  }
}
