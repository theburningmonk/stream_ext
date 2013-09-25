library switchFrom_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

void main() {
  var start     = query("#btn_newStream");
  var output    = query("#output");

  var contrl    = new StreamController.broadcast();

  log(msg) => output.children.add(new DivElement()..text = msg);

  var stream   = contrl.stream;
  var switched = StreamExt.switchFrom(stream);

  StreamExt.log(stream, "stream", log);
  StreamExt.log(switched, "switchFrom", log);

  var index = 0;
  start.onClick.listen((_) {
    index++;
    contrl.add(new Stream.periodic(new Duration(seconds : 1), (n) => n)
                    .map((n) => "stream ${index} - $n"));
  });
}