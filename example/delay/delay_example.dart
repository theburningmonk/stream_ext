library delay_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

void main() {
  _trackMouse("Time flies like an arrow");
}

_trackMouse(String message) {
  Element container = query('#container');

  Stream mouseMove = container.onMouseMove;
  var chars = new List.generate(message.length, (i) => message[i]);

  for (var i = 0; i < chars.length; i++) {
    Element label = new SpanElement()
      ..text = chars[i];
    container.children.add(label);
    label.style.left = "${i * 10}px";
    label.style.position = "relative";

    StreamExt.delay(mouseMove, new Duration(milliseconds : i * 100))
      ..listen((MouseEvent evt) {
        label
          ..style.left = "${evt.offset.x + i * 10}px"
          ..style.top  = "${evt.offset.y}px";
      });
  }
}