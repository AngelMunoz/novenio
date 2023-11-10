sealed class CommandResult {}

class CommandSuccess extends CommandResult {}

class CommandFailure extends CommandResult {
  final String message;

  CommandFailure(this.message);
}

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

class RemoveNodeArgs {
  final String version;

  RemoveNodeArgs(this.version);

  @override
  String toString() {
    return 'UninstallArgs{version: $version}';
  }
}

class UseArgs {
  final String version;
  final String? importPackagesFrom;

  UseArgs(this.version, this.importPackagesFrom);

  @override
  String toString() {
    return 'UseArgs{version: $version, importPackagesFrom: $importPackagesFrom}';
  }
}

class ListArgs {
  final bool remote;
  final bool update;

  ListArgs(this.remote, this.update);

  @override
  String toString() {
    return 'ListArgs{remote: $remote, update: $update}';
  }
}

class ImportArgs {
  final String from;
  final String to;

  ImportArgs(this.from, this.to);

  @override
  String toString() {
    return 'ImportArgs{from: $from, to: $to}';
  }
}
