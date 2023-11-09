import 'package:novenio/os.dart';

void main(List<String> arguments) {
  final (os, arch) = getOsAndArch();
  print('Hello $os: $arch!');
}
