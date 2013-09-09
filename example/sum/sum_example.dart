library sum_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

main() {
  InputElement input  = query('#input_text');
  var letterCount     = query('#letter_count');
  var wordCount       = query('#word_count');

  var controller  = new StreamController.broadcast();
  var inputStream = controller.stream;

  input.onKeyDown.listen((KeyboardEvent evt) {
    if (evt.keyCode == KeyCode.ENTER) {
      controller.add(input.value);
      input.value = null;
    }
  });

  var letterStream = StreamExt.sum(inputStream, map : (String str) => str.length);
  var wordStream = StreamExt.sum(inputStream, map : (String str) => str.split(" ").where((str) => str.length > 0).length);

  letterStream.listen((sum) => letterCount.text = "$sum");
  wordStream.listen((sum) => wordCount.text = "$sum");
}