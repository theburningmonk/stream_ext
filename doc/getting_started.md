# Getting started with stream_ext

Learn about the extension functions for working with `Stream` type with `stream_ext`.

### average

The `StreamExt.average` method returns the average of the values as a `Future` which completes when the input stream is done.

This method uses the supplied **map** function to convert each input value into a `num`. If a **map** function is not specified then the identity function is used instead.

If **closeOnError** flag is set to true, then any error in the **map** function or from the input stream will complete the `Future` with the error.
Otherwise, any errors will be swallowed and excluded from the final average.

Example:

    var input = new Stream.periodic(new Duration(seconds : 1), (n) => n).take(10);
    StreamExt.average(input).then(print);


### buffer

The `StreamExt.buffer` method creates a new stream which buffers values from the input stream produced within the sepcified **duration** and return the buffered values as a list.

The buffered stream will complete if:
* the input stream has completed and any buffered values have been pushed
* **closeOnError** flag is set to true and an error is received

Example

    var input 	 = new Stream.periodic(new Duration(milliseconds : 10), (n) => n);
    var buffered = StreamExt.buffer(input, new Duration(seconds : 1));


### combineLatest

The `StreamExt.combineLastest` function merges two streams into one by using the **selector** function to generate a new value whenever one of the streams produces a value.

The merged stream will complete if:
* both input streams have completed
* **closeOnError** flag is set to true and an error is received

Example

    var stream1 = new Stream.periodic(new Duration(milliseconds : 10), (n) => n);
    var stream2 = new Stream.periodic(new Duration(milliseconds : 100), (n) => n);

    var merged	= StreamExt.combineLatest(stream1, stream2, (a, b) => a + b);


### concat

The `StreamExt.concat` method concatenates two streams together, when the first stream completes the second stream is subscribed to.
Until the first stream is done any values and errors from the second stream is ignored.

The concatenated stream will complete if:
* both input streams have completed (if stream 2 completes before stream 1 then the concatenated stream is completed when stream 1 completes)
* **closeOnError** flag is set to true and an error is received in the active input stream (stream 1 until it completes, then stream 2)

Example

    var stream1 = new Stream.periodic(new Duration(milliseconds : 10), (n) => n).take(10);
    var stream2 = new Stream.periodic(new Duration(milliseconds : 100), (n) => n).take(10);

    var concat	= StreamExt.concat(stream1, stream2);


### delay

The `StreamExt.delay` method creates a new stream whose values are sourced from the input stream but each delivered after the specified **duration**.

The delayed stream will complete if:
* the input has completed and the delayed complete message has been pushed
* the **closeOnError** flag is set to true and an error is received from the input stream

Example

    var input   = new StreamController.broadcast().stream;

    // each event from the input stream is delivered 1 second after it was originally received
    var delayed	= StreamExt.delay(input, new Duration(seconds : 1));


### max

The `StreamExt.max` method returns the maximum value as a `Future` when the input stream is done, as determined by the supplied **compare** function which compares the current maximum value against any new value produced by the input stream.

The **compare** function must act as a `Comparator`.

If **closeOnError** flag is set to true, then any error in the **compare** function will complete the `Future` with the error.
Otherwise, any errors will be swallowed and excluded from the final maximum.

Example

    var input = new Stream.periodic(new Duration(seconds : 1), (n) => n).take(10);
    StreamExt.max(input, (a, b) => a.compareTo(b)).then(print);


### merge

The `StreamExt.merge` method merges two streams into a single unitifed output stream.

The merged stream will forward any values and errors received from the input streams and will complete if:
* both input streams have completed
* the **closeOnError** flag is set to true and an error is received from either input stream

Example:

    var stream1 = new StreamController.broadcast().stream;
    var stream2 = new StreamController.broadcast().stream;

    var merged	= StreamExt.merge(stream1, stream2);


### min

The `StreamExt.min` method returns the minimum value as a `Future` when the input stream is done, as determined by the supplied **compare** function which compares the current minimum value against any new value produced by the input stream.

The **compare** function must act as a `Comparator`.

If **closeOnError** flag is set to true, then any error in the **compare** function will complete the `Future` with the error.
Otherwise, any errors will be swallowed and excluded from the final minimum.

Example

    var input = new Stream.periodic(new Duration(seconds : 1), (n) => n).take(10);
    StreamExt.min(input, (a, b) => a.compareTo(b)).then(print);


### repeat

The `StreamExt.repeat` method allows you to repeat the input stream for the specified number of times.
If **repeatCount** is not set, then the input stream will be repeated **indefinitely**.

The `done` value is not delivered when the input stream completes, but only after the input stream has been repeated the required number of times.

The output stream will complete if:
* the input stream has been repeated the required number of times
* the **closeOnError** flag is set to true and an error has been received

Example

    var input    = new Stream.periodic(new Duration(seconds : 1), (n) => n).take(10);
    var repeated = StreamExt.repeat(input, repeatCount : 3);


### sample

The `StreamExt.sample` method creates a new stream by taking the last value from the input stream for every specified **duration**.

The sampled stream will complete if:
* the input stream has completed and any sampled message has been delivered
* the **closeOnError** flag is set to true and an error has been received

Example

    var input   = new Stream.periodic(new Duration(milliseconds : 150), (n) => n).take(100);
    var sampled = StreamExt.sample(input, new Duration(seconds : 1));


### scan

The `StreamExt.scan` method creates a new stream by applying an **accumulator** function over the values produced by the input stream and returns each intermediate result with the specified seed and accumulator.

The output stream will complete if:
* the input stream has completed
* **closeOnError** flag is set to true and an error is received

Example

    var input        = new Stream.periodic(new Duration(milliseconds : 150), (n) => n);
    var runningTotal = StreamExt.scan(input, 0, (acc, elem) => acc + elem);


### startWith

The `StreamExt.startWith` method allows you to prefix values to a stream.
The supplied values are delivered as soon as the listener is subscribed before the listener receives values from the input stream.

The output stream will complete if:
* the input stream has completed
* **closeOnError** flag is set to true and an error is received

Example

    var input  = new Stream.periodic(new Duration(milliseconds : 150), (n) => n);
    var output = StreamExt.startWith(input, [ -3, -2, -1 ]);


### sum

The `StreamExt.sum` method returns the sum of all the input values as a `Future` when the input stream is done, as determined by the supplied **compare** function which compares the current minimum value against any new value produced by the input stream.

If a **map** function is not specified then the identity function is used.

If **closeOnError** flag is set to true, then any error in the **map** function will complete the `Future` with the error.
Otherwise, any errors will be swallowed and excluded from the final sum.

Example

    var input = new Stream.periodic(new Duration(seconds : 1), (n) => n).take(10);
    StreamExt.sum(input).then(print);


### throttle

The `StreamExt.throttle` method creates a new stream based on values produced by the specified input, upon forwarding a value from the input stream it'll ignore any subsequent values produced by the input stream until the the flow of new values has paused for the specified duration, after which the last value produced by the input stream is then delivered.

The throttled stream will complete if:
* the input stream has completed and the any throttled message has been delivered
* the **closeOnError** flag is set to true and an error is received from the input stream

Example

    var input     = new StreamController.broadcast().stream;
    var throttled = StreamExt.throttle(input, new Duration(seconds : 1));


### window

The `StreamExt.window` method projects each value from the input stream into consecutive non-overlapping windows.
Each value proudced by the output stream contains a list of values up to the specified count.

The output stream will complete if:
* the input stream has completed and any buffered elements have been upshed
* **closeOnError** flag is set to true and an error is received

Example

    var input 	 = new StreamController.broadcast().stream;
    var windowed = StreamExt.window(input, 3);


### zip

The `StreamExt.zip` method zips two streams into one by combining their values in a pairwise fashion.

The zipped stream will complete if:
* either input stream has completed
* **closeOnError** flag is set to true and an error is received

Example

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
