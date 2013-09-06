library delay_example;

import 'dart:html' as html;
import 'dart:async';
import 'package:stagexl/stagexl.dart';
import 'package:stream_ext/stream_ext.dart';

void main() {
  _trackMouse("Time flies like an arrow");
}

_trackMouse(String message) {
  var canvas = html.query('#stage');
  var stage = new Stage('myStage', canvas);
  var renderLoop = new RenderLoop();
  renderLoop.addStage(stage);

  var mouseMove = canvas.onMouseMove;
  var chars = new List.generate(message.length, (i) => message[i]);

  for (var i = 0; i < chars.length; i++) {
    var textField = new TextField()
      ..text = chars[i]
      ..x = i * 10
      ..addTo(stage);

    StreamExt.delay(mouseMove, new Duration(milliseconds : i * 100))
      ..listen((evt) {
        textField
          ..x = evt.clientX + i * 10
          ..y = evt.clientY;
      });
  }
}