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

  static Stream merge(Stream stream1, Stream stream2, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var completer1 = new Completer();
    var completer2 = new Completer();
    var onError    = _getOnErrorHandler(controller, closeOnError);

    stream1.listen(controller.add,
                   onError : onError,
                   onDone : () => completer1.complete());
    stream2.listen(controller.add,
                   onError : onError,
                   onDone : () => completer2.complete());

    Future
      .wait([ completer1.future, completer2.future ])
      .then((_) => _tryClose(controller));

    return controller.stream;
  }

  static Stream delay(Stream input, Duration duration, { bool closeOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, closeOnError);

    delayCall(f, [ x ]) => x == null ? new Timer(duration, f) : new Timer(duration, () => f(x));

    input.listen((x) => delayCall(controller.add, x),
                 onError : (err) => delayCall(onError, err),
                 onDone  : () => delayCall(() => _tryClose(controller)));

    return controller.stream;
  }
}