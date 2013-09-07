library throttle_example;

import 'dart:html';
import 'dart:async';
import 'dart:json';
import 'package:js/js.dart' as js;
import 'package:stream_ext/stream_ext.dart';

UListElement results;
ParagraphElement error;

void main() {
  results = query('#results');
  error   = query('#error');

  var searcher = query('#searcher');
  Stream keyUp = searcher.onKeyUp;

  StreamExt.throttle(keyUp, new Duration(milliseconds : 250))
    .listen((_) {
      queryWikipedia(searcher.value);
    });
}

void queryWikipedia(String term) {
  js.scoped(() {
    // create a top-level JavaScript function called myJsonpCallback
    js.context.jsonpCallback = new js.Callback.once((jsonData) {
      results.children.clear();

      // the response from Wikipedia should be of an array of two elements - the search term and the array of results
      for (var i = 0; i < jsonData[1].length; i++) {
        results.children.add(new DivElement()..text = jsonData[1][i]);
      }
    });

    // add a script tag for the api required
    ScriptElement script = new Element.tag("script");

    // add the callback function name to the URL
    script.src = "http://en.wikipedia.org/w/api.php?action=opensearch&search=$term&format=json&callback=jsonpCallback";
    document.body.children.add(script); // add the script to the DOM
  });
}