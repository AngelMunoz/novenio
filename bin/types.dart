sealed class CommandResult {}

class InstallVersion extends CommandResult {}

class UninstallVersion extends CommandResult {}

class Version extends CommandResult {}

class ListVersions extends CommandResult {}

class ImportVersion extends CommandResult {}

class InstallArgs {
  final String? custom;
  final bool isLts;
  final bool setDefault;

  InstallArgs(this.isLts, this.setDefault, [this.custom]);

  @override
  String toString() {
    return 'InstallArgs{custom: $custom, isLts: $isLts, setDefault: $setDefault}';
  }
}
