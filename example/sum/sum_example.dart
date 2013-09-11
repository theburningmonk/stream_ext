library sum_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

InputElement input;
ButtonElement done;
SpanElement totalLetters;
SpanElement totalWords;

main() {
  input         = query('#input_text');
  done          = query('#done');
  totalLetters  = query('#letter_count');
  totalWords    = query('#word_count');

  _setup();
}

_setup() {
  var controller  = new StreamController.broadcast();
  var inputStream = controller.stream;

  var inputSub = input.onKeyDown.listen((KeyboardEvent evt) {
    if (evt.keyCode == KeyCode.ENTER) {
      controller.add(input.value);
      input.value = null;
    }
  });

  var letters = StreamExt.sum(inputStream, map : (String str) => str.length);
  var words   = StreamExt.sum(inputStream, map : (String str) => str.split(" ").where((str) => str.length > 0).length);

  var doneSub = done.onClick.listen((_) {
    if (!controller.isClosed) controller.close();
  });

  Future
    .wait([ letters.then((sum) => totalLetters.text = "$sum"),
            words.then((sum) => totalWords.text = "$sum") ])
    .then((_) {
      inputSub.cancel();
      doneSub.cancel();
      _setup();
    });
}