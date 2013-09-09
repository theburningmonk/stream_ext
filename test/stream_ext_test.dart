library stream_ext_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:stream_ext/stream_ext.dart';

part "extensions/buffer_test.dart";
part "extensions/combineLatest_test.dart";
part "extensions/delay_test.dart";
part "extensions/merge_test.dart";
part "extensions/throttle_test.dart";
part "extensions/window_test.dart";
part "extensions/zip_test.dart";

main() {
  new BufferTests().start();
  new CombineLatestTests().start();
  new DelayTests().start();
  new MergeTests().start();
  new ThrottleTests().start();
  new WindowTests().start();
  new ZipTests().start();
}