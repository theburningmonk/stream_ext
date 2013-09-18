library stream_ext_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:stream_ext/stream_ext.dart';

part "extensions/average_test.dart";
part "extensions/buffer_test.dart";
part "extensions/combineLatest_test.dart";
part "extensions/concat_test.dart";
part "extensions/delay_test.dart";
part "extensions/max_test.dart";
part "extensions/merge_test.dart";
part "extensions/min_test.dart";
part "extensions/repeat_test.dart";
part "extensions/sample_test.dart";
part "extensions/scan_test.dart";
part "extensions/startWith_test.dart";
part "extensions/sum_test.dart";
part "extensions/throttle_test.dart";
part "extensions/window_test.dart";
part "extensions/zip_test.dart";

main() {
  new AverageTests().start();
  new BufferTests().start();
  new CombineLatestTests().start();
  new ConcatTests().start();
  new DelayTests().start();
  new MaxTests().start();
  new MergeTests().start();
  new MinTests().start();
  new RepeatTests().start();
  new SampleTests().start();
  new ScanTests().start();
  new StartWithTests().start();
  new SumTests().start();
  new ThrottleTests().start();
  new WindowTests().start();
  new ZipTests().start();
}