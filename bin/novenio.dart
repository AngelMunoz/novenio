import 'package:novenio/extensions.dart';
import 'package:novenio/os.dart';

void main(List<String> arguments) {
  final (os, arch) = getOsAndArch();
  print('Hello ${os.asString}: ${arch.asString}!');

  final String novenioDir = getNovenioDir();
  print("Novenio's locating at: '$novenioDir'");
}
