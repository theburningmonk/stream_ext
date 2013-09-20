library timeOutAt_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

main() {
  var newValue  = query("#btn_event");
  var start     = query("#btn_start");
  var input     = query("#input");
  var output    = query("#output");

  log(prefix, value) => output.children.add(new DivElement()..text = "${new DateTime.now()} : $prefix - $value");

  var controller  = new StreamController.broadcast();
  var stream      = controller.stream;

  var i = 0;
  newValue.onClick.listen((_) => controller.add(i++));
  stream.listen((x) => log("input stream", x));

  start.onClick.listen((_) {
    try {
      var dueTime = DateTime.parse(input.value);
      StreamExt.timeOutAt(stream, dueTime)
        .listen((x) => log("output stream", x),
        onError : (err) => log("output stream", err),
        onDone  : () => log("output stream", "done"));

      log("output stream", "subscribed");
      start.disabled = true;
    } catch (ex) {
      log("incorrect date format", "expect date in yyyy-MM-dd HH:mm:ss");
    }

  });
}