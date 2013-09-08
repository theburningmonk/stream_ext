library zip_example;

import 'dart:html';
import 'dart:async';
import 'dart:math';
import 'package:stream_ext/stream_ext.dart';

void main() {
  var container = query('#container');
  var box       = query('#box');

  Stream mouseDown = box.onMouseDown;
  Stream mouseUp   = document.onMouseUp;
  Stream mouseMove = document.onMouseMove;

  bool isDragging = false;
  mouseDown.listen((_) => isDragging = true);
  mouseUp.listen((_) => isDragging = false);

  var mouseDrags =
      StreamExt
        .zip(mouseMove,
             mouseMove.skip(1),
             (MouseEvent left, MouseEvent right) => new MouseMove(right.screen.x - left.screen.x, right.screen.y - left.screen.y))
        .where((_) => isDragging);

  var minOffsetLeft = box.offsetLeft;
  var maxOffsetLeft = box.offsetLeft + container.clientWidth - box.clientWidth;
  var minOffsetTop  = box.offsetTop;
  var maxOffsetTop  = box.offsetTop + container.clientHeight - box.clientHeight;

  mouseDrags.listen((MouseMove move) {
    var offsetLeft = min(max(minOffsetLeft, box.offsetLeft + move.xChange), maxOffsetLeft);
    var offsetTop  = min(max(minOffsetTop, box.offsetTop + move.yChange), maxOffsetTop);

    box.style.left = "${offsetLeft}px";
    box.style.top  = "${offsetTop}px";
  });
}

class MouseMove {
  int xChange;
  int yChange;

  MouseMove(this.xChange, this.yChange);
}