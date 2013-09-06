library merge_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

void main() {
  var btn1      = query("#btn_1");
  var btn2      = query("#btn_2");
  var btn3      = query("#btn_3");

  var btnErr1   = query("#btn_err_1");
  var btnErr2   = query("#btn_err_2");
  var btnErr3   = query("#btn_err_3");

  var btnDone1  = query("#btn_done_1");
  var btnDone2  = query("#btn_done_2");
  var btnDone3  = query("#btn_done_3");

  var output    = query("#output");

  var contr1    = new StreamController.broadcast();
  var contr2    = new StreamController.broadcast();
  var contr3    = new StreamController.broadcast();

  var stream1   = contr1.stream;
  var stream2   = contr2.stream;
  var stream3   = contr3.stream;
  var merged    = StreamExt.merge(StreamExt.merge(stream1, stream2), stream3);

  log(prefix, value) => output.children.add(new DivElement()..text = "$prefix - $value");

  stream1.listen((x) => log("stream1", x), onError : (err) => log("stream1", err), onDone : () => log("stream1", "done"));
  stream2.listen((x) => log("stream2", x), onError : (err) => log("stream2", err), onDone : () => log("stream2", "done"));
  stream3.listen((x) => log("stream3", x), onError : (err) => log("stream3", err), onDone : () => log("stream3", "done"));

  merged.listen((x) => log("merged", x), onError : (err) => log("merged", err), onDone : () => log("merged", "done"));

  btn1.onClick.listen((_) => contr1.add("new event"));
  btn2.onClick.listen((_) => contr2.add("new event"));
  btn3.onClick.listen((_) => contr3.add("new event"));

  btnErr1.onClick.listen((_) => contr1.addError("new error"));
  btnErr2.onClick.listen((_) => contr2.addError("new error"));
  btnErr3.onClick.listen((_) => contr3.addError("new error"));

  btnDone1.onClick.listen((_) => contr1.close());
  btnDone2.onClick.listen((_) => contr2.close());
  btnDone3.onClick.listen((_) => contr3.close());
}
