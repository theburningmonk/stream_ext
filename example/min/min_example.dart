library min_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

InputElement input;
ButtonElement done;
SpanElement shortestWord;
SpanElement shortestSentence;

main() {
  input             = query('#input_text');
  done              = query('#done');
  shortestWord      = query('#shortest_word');
  shortestSentence  = query('#shortest_sentence');

  _setup();
}

_setup() {
  var controller  = new StreamController.broadcast();
  Stream inputStream = controller.stream;

  var inputSub = input.onKeyDown.listen((KeyboardEvent evt) {
    if (evt.keyCode == KeyCode.ENTER) {
      controller.add(input.value);
      input.value = null;
    }
  });

  compare(String l, String r) => l.length.compareTo(r.length);
  var sentence    = StreamExt.min(inputStream, compare);
  var wordStream  = inputStream.expand((x) => x.split(" ").where((str) => str.length > 0));
  var word        = StreamExt.min(wordStream, compare);

  var doneSub = done.onClick.listen((_) {
    if (!controller.isClosed) controller.close();
  });

  Future
    .wait([ sentence.then((x) => shortestSentence.text = "$x"),
            word.then((x) => shortestWord.text = "$x") ])
    .then((_) {
      inputSub.cancel();
      doneSub.cancel();
      _setup();
    });
}