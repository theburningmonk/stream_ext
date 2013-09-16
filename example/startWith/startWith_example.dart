library startWith_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

void main() {
  ButtonElement start   = query('#btn_start');
  var samples = query('#output');

  start.onClick.listen((_) {
    start.disabled = true;

    var input = new Stream.periodic(new Duration(seconds : 1), (n) => n);
    StreamExt.startWith(input, [ -3, -2, -1 ])
      ..listen((n) => samples.children.add(new DivElement()..text = "$n"));
  });
}