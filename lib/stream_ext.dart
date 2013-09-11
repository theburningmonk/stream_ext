library stream_ext;

import 'dart:async';

class StreamExt {
  static _identity(x) => x; // the identity function

  static _getOnErrorHandler(StreamController controller, closeOnError) {
      return closeOnError
              ? (err) {
                if (!controller.isClosed) {
                  controller.addError(err);
                  controller.close();
                }
              }
              : (err) {
                if (!controller.isClosed) {
                  controller.addError(err);
                }
              };
  }

  static _tryClose(StreamController controller) {
    if (!controller.isClosed) controller.close();
  }

  static _tryAdd(StreamController controller, event) {
    if (!controller.isClosed) controller.add(event);
  }

  static _tryRun(void delegate(), void onError(err)) {
    try {
      delegate();
    }
    catch (ex) {
      onError(ex);
    }
  }

  /**
   * Merges two stream into one, the merged stream will forward any elements and errors received from the input streams.
   *
   * The merged stream will complete if:
   *
   * * both input streams have completed
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream merge(Stream stream1, Stream stream2, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var completer1 = new Completer();
    var completer2 = new Completer();
    var onError    = _getOnErrorHandler(controller, closeOnError);

    stream1.listen((x) => _tryAdd(controller, x),
                   onError : onError,
                   onDone  : completer1.complete);
    stream2.listen((x) => _tryAdd(controller, x),
                   onError : onError,
                   onDone  : completer2.complete);

    Future
      .wait([ completer1.future, completer2.future ])
      .then((_) => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Merges two streams into one by using the selector function to generate new elements whenever one of the input streams produces a new element.
   *
   * The merged stream will complete if:
   *
   * * both input streams have completed
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream combineLatest(Stream stream1, Stream stream2, dynamic selector(dynamic item1, dynamic item2), { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var completer1 = new Completer();
    var completer2 = new Completer();
    var onError    = _getOnErrorHandler(controller, closeOnError);

    // current latest items on each stream
    var item1;
    var item2;

    void handleNewEvent() {
      if (item1 != null && item2 != null) {
        _tryRun(() => _tryAdd(controller, selector(item1, item2)), onError);
      }
    }

    stream1.listen((x) {
        item1 = x;
        handleNewEvent();
      },
      onError : onError,
      onDone  : completer1.complete);
    stream2.listen((x) {
        item2 = x;
        handleNewEvent();
      },
      onError : onError,
      onDone  : completer2.complete);

    Future
      .wait([ completer1.future, completer2.future ])
      .then((_) => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Creates a new stream whose elements are sourced from the input stream but each delivered after the specified duration.
   *
   * The delayed stream will complete if:
   *
   * * the input stream has completed and the delayed complete message has been delivered
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream delay(Stream input, Duration duration, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    delayCall(f, [ x ]) => x == null ? new Timer(duration, f) : new Timer(duration, () => f(x));

    input.listen((x) => delayCall(() => _tryAdd(controller, x)),
                 onError : (err) => delayCall(onError, err),
                 onDone  : ()    => delayCall(() => _tryClose(controller)));

    return controller.stream;
  }

  /**
   * Creates a new stream who stops the flow of elements produced by the input stream until no new element has been produced by the input stream after the specified duration.
   *
   * The throttled stream will complete if:
   *
   * * the input stream has completed and the any throttled message has been delivered
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream throttle(Stream input, Duration duration, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    var isThrottling = false;
    var buffer;
    void handleNewEvent(x) {
      // if this is the first item then push it
      if (!isThrottling) {
        _tryAdd(controller, x);
        isThrottling = true;

        new Timer(duration, () => isThrottling = false);
      } else {
        buffer = x;
        isThrottling = true;

        new Timer(duration, () {
          // when the timer callback is invoked after the timeout, check if there has been any
          // new items by comparing the last item against our captured closure 'x'
          // only push the event to the output stream if the captured event has not been
          // superceded by a subsequent event
          if (buffer == x) {
            _tryAdd(controller, x);

            // reset
            isThrottling = false;
            buffer = null;
          }
        });
      }
    }

    input.listen(handleNewEvent,
                 onError : onError,
                 onDone  : () {
                    if (isThrottling && buffer != null) {
                      _tryAdd(controller, buffer);
                    }
                    _tryClose(controller);
                  });

    return controller.stream;
  }

  /**
   * Zips two streams into one by combining their elements in a pairwise fashion.
   *
   * The zipped stream will complete if:
   *
   * * either input stream has completed
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream zip(Stream stream1, Stream stream2, dynamic zipper(dynamic item1, dynamic item2), { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    // lists to track the data that had been buffered for the two streams
    var buffer1 = new List();
    var buffer2 = new List();

    // handler for new event being added to the list on the left
    void handleNewEvent(List left, List right, dynamic newValue) {
      left.add(newValue);

      if (right.isEmpty) {
        return;
      }

      var item1 = buffer1[0];
      var item2 = buffer2[0];

      _tryRun(() {
        _tryAdd(controller, zipper(item1, item2));

        // only remove the items from the buffer after the zipper function succeeds
        buffer1.removeAt(0);
        buffer2.removeAt(0);
      }, onError);
    }

    stream1.listen((x) => handleNewEvent(buffer1, buffer2, x),
                   onError : onError,
                   onDone  : () => _tryClose(controller));
    stream2.listen((x) => handleNewEvent(buffer2, buffer1, x),
                   onError : onError,
                   onDone  : () => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Projects each element from the input stream into consecutive non-overlapping windows.
   *
   * Each element produced by the output stream will contains a list of elements up to the specified count.
   *
   * The output stream will complete if:
   *
   * * the input stream has completed and any buffered elements have been pushed
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream window(Stream input, int count, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    var buffer   = new List();
    void pushBuffer() {
      if (buffer.length == count) {
        _tryAdd(controller, buffer.toList()); // add a clone instead of the buffer list
        buffer.clear();
      }
    }

    void handleNewEvent(x) {
      buffer.add(x);
      pushBuffer();
    }

    input.listen(handleNewEvent,
                 onError : onError,
                 onDone  : () {
                   if (buffer.length > 0) {
                     _tryAdd(controller, buffer.toList()); // add a clone instead of the buffer list
                   }
                   _tryClose(controller);
                 });

    return controller.stream;
  }

  /**
   * Creates a new stream which buffers elements from the input stream produced within the specified duration.
   *
   * Each element produced by the output stream is a list.
   *
   * The output stream will complete if:
   *
   * * the input stream has completed and any buffered elements have been pushed
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream buffer(Stream input, Duration duration, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    var buffer = new List();
    void pushBuffer() {
      if (buffer.length > 0) {
        _tryAdd(controller, buffer.toList()); // add a clone instead of the buffer list
        buffer.clear();
      }
    }

    var timer = new Timer.periodic(duration, (_) => pushBuffer());

    input.listen(buffer.add,
                 onError  : onError,
                 onDone   : () {
                   pushBuffer();
                   _tryClose(controller);
                   if (timer.isActive) {
                     timer.cancel();
                   }
                 });

    return controller.stream;
  }

  /**
   * Creates a new stream by applying an accumulator function over the elements produced by the input stream and
   * returns each intermediate result with the specified seed and accumulator.
   *
   * The output stream will complete if:
   *
   * * the input stream has completed
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream scan(Stream input, dynamic seed, dynamic accumulator(dynamic acc, dynamic element), { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    var acc = seed;

    void handleNewEvent(x) {
      _tryRun(() {
        acc = accumulator(acc, x);
        _tryAdd(controller, acc);
      }, onError);
    }

    input.listen(handleNewEvent,
                 onError : onError,
                 onDone  : () => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Returns the sum of the elements as a [Future], using the supplied [map] function to convert each element from the input stream into a [num].
   *
   * If a [map] function is not specified then the identity function is used.
   *
   * If [closeOnError] flag is set to true, then any error in the [map] function will complete the [Future] with the error. Otherwise, any errors
   * will be swallowed and excluded from the final sum.
   */
  static Future sum(Stream input, { num map (dynamic elem), bool closeOnError : false, bool sync : false }) {
    if (map == null) {
      map = _identity;
    }

    var completer = new Completer();
    var sum = 0;

    var onError   = closeOnError ? (err) => completer.completeError(err) : (_) {};

    void handleNewEvent(x) => _tryRun(() {
      var newVal = map(x);
      sum += newVal;
    }, onError);

    input.listen(handleNewEvent,
                 onError : onError,
                 onDone  : () {
                   if (!completer.isCompleted) completer.complete(sum);
                 });

    return completer.future;
  }

  /**
   * Returns the minimum element as a [Future], as determined by the supplied [compare] function which compares the current minimum value against
   * any new value produced by the input [Stream].
   *
   * The [compare] function must act as a [Comparator].
   *
   * If [closeOnError] flag is set to true, then any error in the [compare] function will complete the [Future] with the error. Otherwise, any errors
   * will be swallowed and excluded from the final minimum.
   */
  static Future min(Stream input, int compare(dynamic a, dynamic b), { bool closeOnError : false, bool sync : false }) {
    var completer = new Completer();
    var onError   = closeOnError ? (err) => completer.completeError(err) : (_) {};

    var minimum;

    void handleNewEvent(x) => _tryRun(() {
      if (minimum == null) {
        minimum = x;
      } else if (compare(minimum, x) > 0) {
        minimum = x;
      }
    }, onError);

    input.listen(handleNewEvent,
                 onError : onError,
                 onDone  : () {
                   if (!completer.isCompleted) completer.complete(minimum);
                 });

    return completer.future;
  }

  /**
   * Returns the maximum element as a [Future], as determined by the supplied [compare] function which compares the current maximum value against
   * any new value produced by the input [Stream].
   *
   * The [compare] function must act as a [Comparator].
   *
   * If [closeOnError] flag is set to true, then any error in the [compare] function will complete the [Future] with the error. Otherwise, any errors
   * will be swallowed and excluded from the final maximum.
   */
  static Future max(Stream input, int compare(dynamic a, dynamic b), { bool closeOnError : false, bool sync : false }) {
    var completer = new Completer();
    var onError   = closeOnError ? (err) => completer.completeError(err) : (_) {};

    var maximum;

    void handleNewEvent(x) => _tryRun(() {
      if (maximum == null || compare(maximum, x) < 0) {
        maximum = x;
      }
    }, onError);

    input.listen(handleNewEvent,
                 onError : onError,
                 onDone  : () {
                   if (!completer.isCompleted) completer.complete(maximum);
                 });

    return completer.future;
  }
}