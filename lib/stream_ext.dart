library stream_ext;

import 'dart:async';

class StreamExt {
  static _getOnErrorHandler(StreamController controller, closeOnError) {
      return closeOnError
              ? (err) {
                controller.addError(err);
                controller.close();
              }
              : controller.addError;
  }

  static _tryClose(StreamController controller) {
    if (!controller.isClosed) controller.close();
  }

  static _tryAdd(StreamController controller, event) {
    if (!controller.isClosed) controller.add(event);
  }

  /// Merges two stream into one, the merged stream will forward any events and errors received from the input
  /// streams. The merged stream will complete if:
  /// * both input streams have completed
  /// * [closeOnError] flag is set to true and an error is received
  static Stream merge(Stream stream1, Stream stream2, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var completer1 = new Completer();
    var completer2 = new Completer();
    var onError    = _getOnErrorHandler(controller, closeOnError);

    stream1.listen((x) => _tryAdd(controller, x),
                   onError : onError,
                   onDone  : () => completer1.complete());
    stream2.listen((x) => _tryAdd(controller, x),
                   onError : onError,
                   onDone  : () => completer2.complete());

    Future
      .wait([ completer1.future, completer2.future ])
      .then((_) => _tryClose(controller));

    return controller.stream;
  }

  /// Creates a new stream whose events are sourced from the input stream but delivered after the specified duration.
  /// The delayed stream will complete if:
  /// * the input stream has completed and the delayed complete message has been delivered
  /// * [closeOnError] flag is set to true and an error is received
  static Stream delay(Stream input, Duration duration, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    delayCall(f, [ x ]) => x == null ? new Timer(duration, f) : new Timer(duration, () => f(x));

    input.listen((x) => delayCall(() => _tryAdd(controller, x)),
                 onError : (err) => delayCall(onError, err),
                 onDone  : ()    => delayCall(() => _tryClose(controller)));

    return controller.stream;
  }

  /// Creates a new stream who stops the flow of events produced by the input stream until no new event has been
  /// produced by the input stream after the specified duration.
  /// The throttled stream will complete if:
  /// * the input stream has completed and the throttled complete message has been delivered
  /// * [closeOnError] flag is set to true and an error is received
  static Stream throttle(Stream input, Duration duration, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    var lastItem;
    Timer timer = new Timer(duration, () {});
    input.listen((x) {
        lastItem = x;

        new Timer(duration, () {
          // when the timer callback is invoked after the timeout, check if there has been any
          // new items by comparing the last item against our captured closure 'x'
          // only push the event to the output stream if the captured event has not been
          // superceded by a subsequent event
          if (lastItem == x) {
            controller.add(x);
          }
        });
      },
     onError : onError,
     onDone  : () => _tryClose(controller));

    return controller.stream;
  }
}