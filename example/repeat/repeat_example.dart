library repeat_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

void main() {
  ButtonElement start = query('#btn_start');
  InputElement input  = query('#input');
  var output          = query('#output');

  start.onClick.listen((_) {
    start.disabled = true;

    var inputStream = new Stream.periodic(new Duration(seconds : 1), (n) => n)
                            .take(5);
    var repeatCount;
    try {
      repeatCount = int.parse(input.value);
    } catch (_) {
    }

    StreamExt.repeat(inputStream, repeatCount : repeatCount)
      ..listen((n) => output.children.add(new DivElement()..text = "$n (${new DateTime.now()})"),
               onError : (err) => output.children.add(new DivElement()..text = "$err"),
               onDone  : ()    => output.children.add(new DivElement()..text = "done (${new DateTime.now()})"));
  });
}