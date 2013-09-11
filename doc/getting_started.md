# Getting started with stream_ext

Learn about the extension functions for working with `Stream` type with `stream_ext`.

### merge

The `StreamExt.merge` function merges two stream into a single unitifed output stream.

The merged stream will forward any events and errors received from the input streams and will complete if:
* both input streams have completed
* the `closeOnError` flag is set to true and an error is received from either input stream

Example:

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

Example

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

Example

    var input   = new StreamController.broadcast().stream;

    // each event from the input stream is delivered 1 second after it was originally received
    var delayed	= StreamExt.delay(input, new Duration(seconds : 1));


### throttle

The `StreamExt.throttle` function creates a new stream based on events produced by the specified input, upon forwarding an event from the input stream it'll ignore any subsequent events produced by the input stream until the the flow of new events has paused for the specified duration, after which the last event produced by the input stream is then delivered.

The throttled stream will complete if:
* the input stream has completed and the any throttled message has been delivered
* the `closeOnError` flag is set to true and an error is received from the input stream

Example

    var input   = new StreamController.broadcast().stream;
    var delayed	= StreamExt.throttle(input, new Duration(seconds : 1));


### zip

The `StreamExt.zip` function zips two streams into one by combining their elements in a pairwise fashion.

The zipped stream will complete if:
* either input stream has completed
* [closeOnError] flag is set to true and an error is received

Example

    var mouseMove = document.onMouseMove;
    var mouseDrags =
      StreamExt
        .zip(mouseMove,
             mouseMove.skip(1),
             (MouseEvent left, MouseEvent right) => new MouseMove(right.screen.x - left.screen.x, right.screen.y - left.screen.y))
        .where((_) => isDragging);


### window

The `StreamExt.window` function projects each element from the input stream into consecutive non-overlapping windows.
Each element proudced by the output stream contains a list of elements up to the specified count.

The output stream will complete if:
* the input stream has completed and any buffered elements have been upshed
* [closeOnError] flag is set to true and an error is received

Example

    var input 	 = new StreamController.broadcast().stream;
    var windowed = StreamExt.window(input, 3);


### buffer

The `StreamExt.buffer` function creates a new stream which buffers elements from the input stream produced within the sepcified duration.
Each element produced by the output stream is a list.

The output stream will complete if:
* the input stream has completed and any buffered elements have been upshed
* [closeOnError] flag is set to true and an error is received

Example

    var input 	 = new StreamController.broadcast().stream;
    var buffered = StreamExt.buffer(input, new Duration(seconds : 1));


### scan

The `StreamExt.scan` function creates a new stream by applying an accumulator function over the elements produced by the input stream and
returns each intermediate result with the specified seed and accumulator.

The output stream will complete if:
* the input stream has completed
* [closeOnError] flag is set to true and an error is received

Example

    var input 	= new StreamController.broadcast().stream;
    
    // create running totals
    var sums 	= StreamExt.scan(input, 0, (acc, elem) => acc + elem);


### sum/min/max

The `StreamExt.sum`, `StreamExt.min` and `StreamExt.max` functions returns an aggregated value (be it the sum, min or max) from the input `Stream` and return the aggregate as a `Future` which is completed when the input `Stream` is finshed.

Not that with these functions, if the function passed in for the aggregation (e.g. the `compare` function for min and max) throws an exception, then depending on the `closeOnError` flag the methods will behave differently:

* if `closeOnError` flag is ture, then the returned `Future` completes with the thrown exception, so you will want to call `.catchError` on the result to handle this in your code
* otherwise, any exceptions will be swallowed and the input value that causes the exception will also be excluded from the aggregated value

Example

    // assuming inputs are of numeric value
    var input 	= new StreamController.broadcast().stream;
    
    Future sum 	= StreamExt.sum(input);
    Future min  = StreamExt.min(input, (a, b) => a.compareTo(b));
    Future max  = StreamExt.max(input, (a, b) => a.compareTo(b));
    

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
