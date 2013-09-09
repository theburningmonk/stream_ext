library scan_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

main() {
  InputElement input  = query('#input_text');
  var output = query('#output');

  var controller  = new StreamController.broadcast();
  var inputStream = controller.stream;

  input.onKeyDown.listen((KeyboardEvent evt) {
    if (evt.keyCode == KeyCode.ENTER) {
      controller.add(input.value);
      input.value = null;
    }
  });

  var outputStream = StreamExt.scan(inputStream, null, (acc, elem) {
    if (acc == null) {
      return elem;
    } else {
      return "$acc, $elem";
    }
  });

  outputStream.listen((data) => output.text = data);
}