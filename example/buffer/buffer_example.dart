library buffer_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

void main() {
  var btn1      = query("#btn_1");
  var btnErr1   = query("#btn_err_1");
  var btnDone1  = query("#btn_done_1");

  var output    = query("#output");

  var contrl    = new StreamController.broadcast();
  var input     = contrl.stream;

  var buffers   = StreamExt.buffer(input, new Duration(seconds : 3));

  log(msg) => output.children.add(new DivElement()..text = msg);

  StreamExt.log(input, "input", log);
  StreamExt.log(buffers, "window", log);

  var idx = 0;
  btn1.onClick.listen((_) => contrl.add(idx++));
  btnErr1.onClick.listen((_) => contrl.addError("new error"));
  btnDone1.onClick.listen((_) => contrl.close());
}