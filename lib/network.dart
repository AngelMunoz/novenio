import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:novenio/common.dart';
import 'package:novenio/constants.dart' as constants;
import 'package:novenio/extensions.dart';

Future<List<NodeVerItem>?> fetchNodeIndex() async {
  final url = Uri.https(constants.nodeSourceUrl, '/dist/index.json');
  final response = await http.get(url);
  if (response.statusCode case (>= 400)) {
    return null;
  }
  final List<dynamic> items = jsonDecode(utf8.decode(response.bodyBytes));
  final decoded = items
      .map(nodeVersionFromDynamic)
      .sortWith((t) => t.date, Order.orderDate.reverse);
  return decoded.toList();
}

Future<File?> fetchNode(
    NodeVerItem node, OSKind os, ArchitectureKind arch) async {
  final String extension = Platform.isWindows ? 'zip' : 'tar.gz';
  final String nodeItem = getVersionDirName(os, arch, node.version);

  final url = Uri.https(
      constants.nodeSourceUrl, '/dist/${node.version}/$nodeItem.$extension');
  final response = await http.get(url);
  if (response.statusCode case (>= 400)) {
    return null;
  }
  final File file = File(Platform.environment['TMPDIR'] ?? '/tmp');
  return await file.writeAsBytes(response.bodyBytes);
}
