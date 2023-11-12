import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';
import 'package:novenio/common.dart';

Future<List<NodeVerItem>> getNodeVersions() => File('./test/versions.json')
    .readAsString()
    .then((String contents) => jsonDecode(contents) as List<dynamic>)
    .then((List<dynamic> items) => items
        .map(nodeVersionFromDynamic)
        .sortWith((t) => t.date, Order.orderDate.reverse)
        .toList());

void main() {
  group('Get Node Version function works', () {
    late List<NodeVerItem> nodeItems;
    setUpAll(() async {
      nodeItems = await getNodeVersions();
    });

    test("Returns null if no version is found", () {
      expect(getNodeVersion('v0.0.0', nodeItems), equals(isNull));
      expect(getNodeVersion('0.0.0', nodeItems), equals(isNull));
      expect(getNodeVersion('0.0.0.1', nodeItems), equals(isNull));
      expect(getNodeVersion('v20.0.10.22', nodeItems), equals(isNull));
      expect(getNodeVersion('invalid', nodeItems), equals(isNull));
    });

    test("Returns the correct version for codename", () {
      expect(getNodeVersion('carbon', nodeItems), equals(nodeItems[228]));
      expect(getNodeVersion('erbium', nodeItems), equals(nodeItems[78]));
    });

    test("Returns the correct version when major is specified", () {
      expect(getNodeVersion('14', nodeItems), equals(nodeItems[35]));

      expect(getNodeVersion('14.x', nodeItems), equals(nodeItems[35]));
    });

    test("Returns the correct version when major, and minor are specified", () {
      expect(getNodeVersion('12.22', nodeItems), equals(nodeItems[78]));

      expect(getNodeVersion('12.22.x', nodeItems), equals(nodeItems[78]));
    });

    test(
        "Returns the correct version when major, minor, and patch are specified",
        () {
      expect(getNodeVersion('v14.17.6', nodeItems), equals(nodeItems[115]));
    });
  });
}
