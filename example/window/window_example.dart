library window_example;

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

  var windows   = StreamExt.window(input, 3);

  log(prefix, value) => output.children.add(new DivElement()..text = "$prefix - $value");

  input.listen((x) => log("input", x), onError : (err) => log("input", err), onDone : () => log("input", "done"));
  windows.listen((x) => log("window", x), onError : (err) => log("window", err), onDone : () => log("window", "done"));

  var idx = 0;
  btn1.onClick.listen((_) => contrl.add(idx++));
  btnErr1.onClick.listen((_) => contrl.addError("new error"));
  btnDone1.onClick.listen((_) => contrl.close());
}