library stream_ext_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:streamext/stream_ext.dart';

part "extensions/delay.dart";
part "extensions/merge.dart";

main() {
  new MergeTests().start();
  new DelayTests().start();
}