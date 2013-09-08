# Getting started with stream_ext

Learn about the extension functions for working with `Stream` type with `stream_ext`.

### merge

The `StreamExt.merge` function merges two stream into a single unitifed output stream.

The merged stream will forward any events and errors received from the input streams and will complete if:
* both input streams have completed
* the `closeOnError` flag is set to true and an error is received from either input stream

**Dart code**

    // the input streams
    var stream1   = new StreamController.broadcast().stream;
    var stream2   = new StreamController.broadcast().stream;

    // the merged output stream
    var merged	  = StreamExt.merge(stream1, stream2);


### combineLatest

The `StreamExt.combineLastest` merges two streams into one stream by using the selector function whenever one of the streams produces an event.

The merged stream will complete if:
* both input streams have completed
* [closeOnError] flag is set to true and an error is received

**Dart code**

    // the input streams
    var stream1   = new StreamController.broadcast().stream;
    var stream2   = new StreamController.broadcast().stream;

    // the merged output stream
    var merged	  = StreamExt.combineLatest(stream1, stream2, (a, b) => a + b);


### delay

The `StreamExt.delay` function creates a new stream whose events are directly sourced from the input stream but each delivered after the specified duration.

The delayed stream will complete if:
* the input has completed and the delayed complete message has been delivered
* the `closeOnError` flag is set to true and an error is received from the input stream

**Dart code**

    var input   = new StreamController.broadcast().stream;

    // each event from the input stream is delivered 1 second after it was originally received
    var delayed	= StreamExt.delay(input, new Duration(seconds : 1));


### throttle

The `StreamExt.throttle` function creates a new stream based on events produced by the specified input, upon forwarding an event from the input stream it'll ignore any subsequent events produced by the input stream until the the flow of new events has paused for the specified duration, after which the last event produced by the input stream is then delivered.

The throttled stream will complete if:
* the input stream has completed and the any throttled message has been delivered
* the `closeOnError` flag is set to true and an error is received from the input stream

**Dart code**

    var input   = new StreamController.broadcast().stream;
    var delayed	= StreamExt.throttle(input, new Duration(seconds : 1));


### zip

The `StreamExt.zip` function zips two streams into one by combining their elements in a pairwise fashion.

The zipped stream will complete if:
* either input stream has completed
* [closeOnError] flag is set to true and an error is received

**Dart code**

    var mouseMove = document.onMouseMove;
    var mouseDrags =
      StreamExt
        .zip(mouseMove,
             mouseMove.skip(1),
             (MouseEvent left, MouseEvent right) => new MouseMove(right.screen.x - left.screen.x, right.screen.y - left.screen.y))
        .where((_) => isDragging);


## Examples

Please take a look at the **example** directory for more complete and meaningful usages of each of the extension functions.

## Package Import

Add the `stream_ext` depedency to your pubspec.yaml ...

    name: hello_world
    description: hello world
    dependencies:
      stream_ext: { git: https://github.com/theburningmonk/stream_ext.git }

... then import the library in your Dart code.

    import 'package:stream_ext/stream_ext.dart';
