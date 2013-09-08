library stream_ext_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:stream_ext/stream_ext.dart';

part "extensions/delay_test.dart";
part "extensions/merge_test.dart";
part "extensions/throttle_test.dart";
part "extensions/zip_test.dart";

main() {
  new MergeTests().start();
  new DelayTests().start();
  new ThrottleTests().start();
  new ZipTests().start();
}