library stream_ext;

import 'dart:async';

class StreamExt {
  static _getOnErrorHandler (StreamController controller, cancelOnError) {
      return cancelOnError
              ? (err) {
                controller.addError(err);
                controller.close();
              }
              : controller.addError;
  }

  static Stream merge(Stream stream1, Stream stream2, { bool cancelOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var completer1 = new Completer();
    var completer2 = new Completer();
    var onError    = _getOnErrorHandler(controller, cancelOnError);

    stream1.listen(controller.add,
                   onError : onError,
                   onDone : () => completer1.complete());
    stream2.listen(controller.add,
                   onError : onError,
                   onDone : () => completer2.complete());

    Future
      .wait([ completer1.future, completer2.future ])
      .then((_) => controller.close());

    return controller.stream;
  }

  static Stream delay(Stream input, Duration duration, { bool cancelOnError : false, bool sync : false }) {
    var controller = new StreamController.broadcast(sync : sync);
    var onError    = _getOnErrorHandler(controller, cancelOnError);

    delayCall(f, [ x ]) => x == null ? new Timer(duration, f) : new Timer(duration, () => f(x));

    input.listen((x) => delayCall(controller.add, x),
                 onError : (err) => delayCall(onError, err),
                 onDone  : () => delayCall(controller.close));

    return controller.stream;
  }

  // throttle

  // zip

  // repeat

  // retry

  // concat

  // catch

  // combineLatest

  // onErrorResumeNext

  // average

  // max

  // min

  // sum
}

main() {
//  Stream stream1 = new Stream.periodic(new Duration(seconds: 1), (n) => n).take(10).asBroadcastStream();
//  stream1.listen((n) => print("stream1 : $n"),
//                 onError : (err) => print("stream1 : $err"),
//                 onDone : () => print("stream1 : done"),
//                 cancelOnError : false);
//
//  Stream stream2 = stream1.where((n) => n % 2 == 0).take(2);
//  stream2.listen((n) => print("stream2 : $n"),
//                 onError : (err) => print("stream2 : $err"),
//                 onDone : () => print("stream2 : done"),
//                 cancelOnError : false);
//
//  Stream stream3 = stream1.where((n) => n % 2 != 0).take(2);
//  stream3.listen((n) => print("stream3 : $n"),
//                 onError : (err) => print("stream3 : $err"),
//                 onDone : () => print("stream3 : done"),
//                 cancelOnError : false);

//  Stream stream2 = stream1.map((n) => n * 2).skip(2).take(2);
//  stream2.listen((n) => print("stream2 : $n"));

//  Stream stream4 = stream1.skip(4).take(2).expand((n) => [ n * 3, n * 4 ]);
//  stream4.listen((n) => print("stream4 : $n"));

//  StreamController controller = new StreamController.broadcast();
//  controller.addStream(stream3)
//    .then((_) => controller.addStream(stream5))
//    .then((_) => controller.addStream(stream1));
//  controller.stream.listen((n) => print("stream6 : $n"));

//  StreamController controller = new StreamController.broadcast();
//  controller.addStream(stream1)
//    .then((_) => controller.addStream(stream2))
//    .then((_) => controller.addStream(stream3));
//  controller.stream.listen((n) => print("composite stream : $n"),
//                           onError : (err) => print("composite stream : $err"),
//                           onDone : () => print("composite stream : done"),
//                           cancelOnError : false);
}