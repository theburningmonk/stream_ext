library stream_ext;

import 'dart:async';

part "timeout_error.dart";
part "tuple.dart";

class StreamExt {
  static _defaultArg (x, defaultVal) => x == null ? defaultVal : x;

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

  static _tryAddError(StreamController controller, error) {
    if (!controller.isClosed) controller.addError(error);
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
   * Propagates values from the stream that reacts first with a value.
   *
   * This method will ignore any errors received from either stream until the first value is received. The stream which reacts first with
   * a value will have its values and errors propagated through the output stream.
   *
   * The output stream will complete if:
   *
   * * neither stream produced a value before completing
   * * the propagated stream has completed
   * * [closeOnError] flag is set to true and an error is received in the propagated stream
   */
  static Stream amb(Stream stream1, Stream stream2, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    StreamSubscription subscription1, subscription2;
    Completer completer1 = new Completer(), completer2 = new Completer();
    var started = false;

    void tryStart (StreamSubscription subscription, Completer completer,
                   StreamSubscription otherSubscription, Completer otherCompleter,
                   value) {
      if (!started) {
        started = true;
        controller.add(value);

        // update the handlers to propagate values and errors on the stream
        subscription.onData((x) => _tryAdd(controller, x));
        subscription.onError(onError);
        subscription.onDone(() {
          if (!completer.isCompleted) completer.complete();
          _tryClose(controller);
        });

        // cancel the subscription to the other unused stream and complete its completer
        otherSubscription.cancel();
        if (!otherCompleter.isCompleted) otherCompleter.complete();
      }
    }

    subscription1 = stream1.listen((x) => tryStart(subscription1, completer1, subscription2, completer2, x),
                                   onError : (_) { }, // surpress errors before value
                                   onDone  : () => completer1.complete());
    subscription2 = stream2.listen((x) => tryStart(subscription2, completer2, subscription1, completer1, x),
                                   onError : (_) { }, // surpress errors before value
                                   onDone  : () => completer2.complete());

    // catch-all in case neither stream produced a value before completing
    Future.wait([ completer1.future, completer2.future ])
      .then((_) => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Returns the average of the values as a [Future] which completes when the input stream is done.
   *
   * This method uses the supplied [map] function to convert each input value into a [num].
   * If a [map] function is not specified then the identity function is used.
   *
   * If [closeOnError] flag is set to true, then any error in the [map] function or from the input stream will complete the [Future] with the error.
   * Otherwise, any errors will be swallowed and excluded from the final average.
   */
  static Future average(Stream input, { num map (dynamic elem), bool closeOnError : false, bool sync : false }) {
    if (map == null) {
      map = _identity;
    }

    var sum   = 0;
    var count = 0;
    var completer = new Completer();
    var onError   = closeOnError ? (err) => completer.completeError(err) : (_) {};

    void handleNewValue(x) => _tryRun(() {
      var newVal = map(x);
      sum += newVal;
      count++;
    }, onError);

    input.listen(handleNewValue,
                 onError : onError,
                 onDone  : () {
                   if (!completer.isCompleted) completer.complete(sum / count);
                 });

    return completer.future;
  }

  /**
   * Creates a new stream which buffers values from the input stream produced within the specified [duration] and
   * return the buffered values as a list.
   *
   * The buffered stream will complete if:
   *
   * * the input stream has completed and any buffered values have been pushed
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
   * Merges two streams into one by using the [selector] function to generate new a new value whenever one of the input streams produces a new value.
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

    void handleNewValue() {
      if (item1 != null && item2 != null) {
        _tryRun(() => _tryAdd(controller, selector(item1, item2)), onError);
      }
    }

    stream1.listen((x) {
        item1 = x;
        handleNewValue();
      },
      onError : onError,
      onDone  : completer1.complete);
    stream2.listen((x) {
        item2 = x;
        handleNewValue();
      },
      onError : onError,
      onDone  : completer2.complete);

    Future
      .wait([ completer1.future, completer2.future ])
      .then((_) => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Concatenates the two input streams together, when the first stream completes the second stream is subscribed to. Until the first stream is done any
   * values and errors from the second stream is ignored.
   *
   * The concatenated stream will complete if:
   *
   * * both input streams have completed (if stream 2 completes before stream 1 then the concatenated stream is completed when stream 1 completes)
   * * [closeOnError] flag is set to true and an error is received in the active input stream (stream 1 until it completes, then stream 2)
   */
  static Stream concat(Stream stream1, Stream stream2, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);
    var completer1 = new Completer();
    var completer2 = new Completer();

    // note : this looks somewhat convoluted and unnecessary, but the reason to subscribe to both input streams and use
    // another bool flag to indicate if we're handling value from stream 1 is to help us more gracefully handle the case
    // when the second stream completes before the first so that when the first stream completes it should actually
    // complete theoutput stream rather than attempt to subscribed to the second stream at that point
    void handleNewValue (x, isStream1) {
      if (isStream1 == !completer1.isCompleted) {
        _tryAdd(controller, x);
      }
    }

    stream1.listen((x) => handleNewValue(x, true),
                   onError : onError,
                   onDone  : () {
                     completer1.complete();

                     // close the output stream eagerly if stream 2 had already completed by now
                     if (completer2.isCompleted) _tryClose(controller);
                   });
    stream2.listen((x) => handleNewValue(x, false),
                   onError : (err) {
                     if (completer1.isCompleted) onError(err);
                   },
                   onDone  : () {
                     completer2.complete();

                     // close the output stream eagerly if stream 1 had already completed by now
                     if (completer1.isCompleted) _tryClose(controller);
                   });

    Future
      .wait([ completer1.future, completer2.future ])
      .then((_) => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Creates a new stream whose values are sourced from the input stream but each delivered after the specified duration.
   *
   * The delayed stream will complete if:
   *
   * * the input stream has completed and the delayed complete message has been pushed
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream delay(Stream input, Duration duration, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    delayCall(f, [ x ]) => x == null ? new Timer(duration, f) : new Timer(duration, () => f(x));

    input.listen((x) => delayCall(() => _tryAdd(controller, x)),
                 onError : onError,
                 onDone  : () => delayCall(() => _tryClose(controller)));

    return controller.stream;
  }

  /**
   * Helper method to provide an easy way to log when new values and errors are received and when the stream is done.
   */
  static void log(Stream input, [ String prefix, void log(Object msg) ]) {
    prefix = _defaultArg(prefix, "");
    log    = _defaultArg(log, print);

    input.listen((x) => log("($prefix) Value at ${new DateTime.now()} - $x"),
                 onError : (err) => log("($prefix) Error at ${new DateTime.now()} - $err"),
                 onDone  : () => log("($prefix) Done at ${new DateTime.now()}"));
  }

  /**
   * Returns the maximum value as a [Future] when the input stream is done, as determined by the supplied [compare] function which compares the
   * current maximum value against any new value produced by the input stream.
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

    void handleNewValue(x) => _tryRun(() {
      if (maximum == null || compare(maximum, x) < 0) {
        maximum = x;
      }
    }, onError);

    input.listen(handleNewValue,
                 onError : onError,
                 onDone  : () {
                   if (!completer.isCompleted) completer.complete(maximum);
                 });

    return completer.future;
  }

  /**
   * Merges two stream into one, the merged stream will forward any values and errors received from the input streams.
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
   * Returns the minimum value as a [Future], as determined by the supplied [compare] function which compares the current minimum value against
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

    void handleNewValue(x) => _tryRun(() {
      if (minimum == null || compare(minimum, x) > 0) {
        minimum = x;
      }
    }, onError);

    input.listen(handleNewValue,
                 onError : onError,
                 onDone  : () {
                   if (!completer.isCompleted) completer.complete(minimum);
                 });

    return completer.future;
  }

  /**
   * Allows the continuation of a stream with another regardless of whether the first stream completes gracefully or due to an error.
   *
   * The output stream will complete if:
   *
   * * both input streams have completed (if stream 2 completes before stream 1 then the output stream is completed when stream 1 completes)
   * * [closeOnError] flag is set to true and an error is received in the continuation stream
   */
  static Stream onErrorResumeNext(Stream stream1, Stream stream2, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);
    var completer1 = new Completer();
    var completer2 = new Completer();

    // note : this looks somewhat convoluted and unnecessary, but the reason to subscribe to both input streams and use
    // another bool flag to indicate if we're handling value from stream 1 is to help us more gracefully handle the case
    // when the second stream completes before the first so that when the first stream completes it should actually
    // complete theoutput stream rather than attempt to subscribed to the second stream at that point
    void handleNewValue (x, isStream1) {
      if (isStream1 == !completer1.isCompleted) {
        _tryAdd(controller, x);
      }
    }

    void resume () {
      if (!completer1.isCompleted) completer1.complete();

      // close the output stream eagerly if stream 2 had already completed by now
      if (completer2.isCompleted) _tryClose(controller);
    }

    stream1.listen((x) => handleNewValue(x, true),
                   onError : (_) => resume(),
                   onDone  : resume);
    stream2.listen((x) => handleNewValue(x, false),
                   onError : (err) {
                     if (completer1.isCompleted) onError(err);
                   },
                   onDone  : () {
                     completer2.complete();

                     // close the output stream eagerly if stream 1 had already completed by now
                     if (completer1.isCompleted) _tryClose(controller);
                   });

    Future
      .wait([ completer1.future, completer2.future ])
      .then((_) => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Allows you to repeat the input stream for the specified number of times. If [repeatCount] is not set, then the input
   * stream will be repeated **indefinitely**.
   *
   * The `done` value is not delivered when the input stream completes, but only after the input stream has been repeated
   * the required number of times.
   *
   * The output stream will complete if:
   *
   * * the input stream has been repeated the required number of times
   * * the [closeOnError] flag is set to true and an error has been received
   */
  static Stream repeat(Stream input, { int repeatCount, bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    var events    = new List();
    var lastValue = new DateTime.now();
    var end;

    // record a received value for later use
    void record(x) {
      // record the time stamp that the value is received at before pushing the value to the output stream
      var now = new DateTime.now();
      var timestamp = now.difference(lastValue);

      _tryAdd(controller, x);
      events.add(new _Tuple(x, timestamp));
      lastValue = now;
    }

    // replys the stream inputs once
    Future replayOnce() {
      // no event was received, so create a future that completes after the duration of the original stream
      if (events.length == 0 && end != null) {
        return new Future.delayed(end.difference(lastValue));
      }

      return events.fold(
               new Future.sync((){}),
               (Future prev, next) =>
                  prev.then((_) =>
                    new Future.delayed(next.item2, () => _tryAdd(controller, next.item1))));
    }

    // recursively replay the stream until we've reached the required count
    void replayRec([ int count = 0 ]) {
      if (repeatCount != null && count >= repeatCount) {
        _tryClose(controller);
      } else {
        replayOnce()
          ..then((_) => replayRec(count + 1));
      }
    }

    input.listen(record,
                 onError : onError,
                 onDone  : () {
                   end = new DateTime.now();
                   replayRec();
                 });

    return controller.stream;
  }

  /**
   * Creates a new stream by taking the last value from the input stream for every specified [duration].
   *
   * The sampled stream will complete if:
   *
   * * the input stream has completed and any sampled message has been delivered
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream sample(Stream input, Duration duration, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    var buffer;
    var timer = new Timer.periodic(duration, (_) {
      if (buffer != null) {
        _tryAdd(controller, buffer);
        buffer = null;
      }
    });

    input.listen((x) => buffer = x,
                 onError : onError,
                 onDone  : () {
                   timer.cancel();
                   if (buffer != null) {
                     _tryAdd(controller, buffer);
                   }
                   _tryClose(controller);
                 });

    return controller.stream;
  }

  /**
   * Creates a new stream by applying an [accumulator] function over the values produced by the input stream and
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

    void handleNewValue(x) {
      _tryRun(() {
        acc = accumulator(acc, x);
        _tryAdd(controller, acc);
      }, onError);
    }

    input.listen(handleNewValue,
                 onError : onError,
                 onDone  : () => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Allows you to prefix values to a stream. The supplied values are delivered as soon as the listener is subscribed before
   * the listener receives values from the input stream.
   *
   * The output stream will complete if:
   *
   * * the input stream has completed
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream startWith(Stream input, Iterable values, { bool closeOnError : false, bool sync : false }) {
    // placeholder for a function that'll be reponsible for adding the data to the StreamController once it's been constructed
    var addValues;

    // note : add the specified values when the stream is subscribed otherwise the data will never be received as they're added
    // before any listeners had started to listen to the stream
    // note : since we can't reference the 'controller' variable in the 'onListen' constructor param and there's no way to set
    // it outside of the constructor, hence the use of the delegate 'addValues' which is invoked only when the output stream
    // is listened to
    var controller = new StreamController.broadcast(onListen : () => addValues(), sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    // now that we can refer to the 'controller' variable, initialize the 'addValues' delegate to add all the supplied values
    // to the stream controller as soon as its output stream is subscribed
    addValues = () {
      try {
        values.forEach((x) => _tryAdd(controller, x));
      } catch (e) {
        onError(e);
      }
    };

    input.listen((x) => _tryAdd(controller, x),
                 onError : onError,
                 onDone  : () => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Returns the sum of the values as a [Future], using the supplied [map] function to convert each input value into a [num].
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

    var sum = 0;
    var completer = new Completer();
    var onError   = closeOnError ? (err) => completer.completeError(err) : (_) {};

    void handleNewValue(x) => _tryRun(() {
      var newVal = map(x);
      sum += newVal;
    }, onError);

    input.listen(handleNewValue,
                 onError : onError,
                 onDone  : () {
                   if (!completer.isCompleted) completer.complete(sum);
                 });

    return completer.future;
  }

  /**
   * Transforms a stream of streams into a stream producing values only from the most recent stream.
   *
   * The output stream will complete if:
   *
   * * the input stream has completed and the last stream has completed
   * * [closeOnError] flag is set to true and an error is received in the active stream
   */
  static Stream switchFrom(Stream<Stream> inputs, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    StreamSubscription current;
    var inputFinished = false;

    void handleNewInput(Stream stream) {
      if (current != null) current.cancel();

      current = stream.listen((x) => _tryAdd(controller, x),
                              onError : onError,
                              onDone  : () {
                                current.cancel();
                                current = null;

                                if (inputFinished) _tryClose(controller);
                              });
    }

    inputs.listen(handleNewInput,
                  onDone : () {
                    inputFinished = true;
                    if (current == null) _tryClose(controller);
                  });

    return controller.stream;
  }

  /**
   * Creates a new stream who stops the flow of values produced by the input stream until no new value has been produced by the input stream after the specified duration.
   *
   * The throttled stream will complete if:
   *
   * * the input stream has completed and any throttled message has been delivered
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream throttle(Stream input, Duration duration, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    var isThrottling = false;
    var buffer;
    void handleNewValue(x) {
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

    input.listen(handleNewValue,
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
   * Allows you to terminate a stream with a [TimeoutError] if the specified [duration] between values elapsed.
   *
   * The output stream will complete if:
   *
   * * the input stream has completed
   * * the specified [duration] between input values has elpased
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream timeOut(Stream input, Duration duration, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    DateTime lastValueTimestamp;
    void startTimer() {
      new Timer(duration, () {
        if (lastValueTimestamp == null ||
          new DateTime.now().difference(lastValueTimestamp) >= duration) {
          _tryAddError(controller, new TimeoutError(duration));
          _tryClose(controller);
        }
      });
    }

    void handleNewValue(x) {
      _tryAdd(controller, x);
      lastValueTimestamp = new DateTime.now();

      startTimer();
    }

    startTimer();

    input.listen(handleNewValue,
                 onError : onError,
                 onDone  : () => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Allows you to terminate a stream with a [TimeoutError] at the specified [dueTime].
   *
   * The output stream will complete if:
   *
   * * the input stream has completed
   * * the specified [dueTime] has elapsed
   * * [closeOnError] flag is set to true and an error is received
   */
  static Stream timeOutAt(Stream input, DateTime dueTime, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);
    var duration   = dueTime.difference(new DateTime.now());

    new Timer(duration, () {
      _tryAddError(controller, new TimeoutError(duration));
      _tryClose(controller);
    });

    input.listen((x) => _tryAdd(controller, x),
                 onError : onError,
                 onDone  : () => _tryClose(controller));

    return controller.stream;
  }

  /**
   * Projects each value from the input stream into consecutive non-overlapping windows.
   *
   * Each value produced by the output stream will contains a list of value up to the specified count.
   *
   * The output stream will complete if:
   *
   * * the input stream has completed and any buffered values have been pushed
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

    void handleNewValue(x) {
      buffer.add(x);
      pushBuffer();
    }

    input.listen(handleNewValue,
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
   * Zips two streams into one by combining their values in a pairwise fashion.
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
    void handleNewValue(List left, List right, dynamic newValue) {
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

    stream1.listen((x) => handleNewValue(buffer1, buffer2, x),
                   onError : onError,
                   onDone  : () => _tryClose(controller));
    stream2.listen((x) => handleNewValue(buffer2, buffer1, x),
                   onError : onError,
                   onDone  : () => _tryClose(controller));

    return controller.stream;
  }
}