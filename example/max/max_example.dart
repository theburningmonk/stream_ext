library max_example;

import 'dart:html';
import 'dart:async';
import 'package:stream_ext/stream_ext.dart';

InputElement input;
ButtonElement done;
SpanElement longestWord;
SpanElement longestSentence;

main() {
  input           = query('#input_text');
  done            = query('#done');
  longestWord     = query('#longest_word');
  longestSentence = query('#longest_sentence');

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
  var sentence    = StreamExt.max(inputStream, compare);
  var wordStream  = inputStream.expand((x) => x.split(" ").where((str) => str.length > 0));
  var word        = StreamExt.max(wordStream, compare);

  var doneSub = done.onClick.listen((_) {
    if (!controller.isClosed) controller.close();
  });

  Future
    .wait([ sentence.then((x) => longestSentence.text = "$x"),
            word.then((x) => longestWord.text = "$x") ])
    .then((_) {
      inputSub.cancel();
      doneSub.cancel();
      _setup();
    });
}