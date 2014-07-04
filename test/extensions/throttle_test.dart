part of stream_ext_test;

class ThrottleTests {
  void start() {
    group('throttle', () {
      _throttleWithNoErrors();
      _throttleNotCloseOnError();
      _throttleCloseOnError();
    });
  }

  void _throttleWithNoErrors() =>
    test("no errors", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.throttle(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);
      controller.add(3);

      return new Future
        .delayed(new Duration(milliseconds : 2))
        .then((_) {
          controller.add(4);
          return controller.close();
        })
        .then((_) => new Future.delayed(new Duration(milliseconds : 10)))
        .then((_) {
          expect(list.length, equals(3),   reason : "throttled stream should have only three events");
          expect(list, equals([ 0, 3, 4]), reason : "throttled stream should contain values 0, 3 and 4");

          expect(hasErr, equals(false), reason : "throttled stream should not have received error");
          expect(isDone, equals(true),  reason : "throttled stream should be completed");
        });
    });

  void _throttleNotCloseOnError() =>
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.throttle(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.addError("failed");
      controller.add(1);
      controller.add(2);
      controller.add(3);

      return new Future
        .delayed(new Duration(milliseconds : 2))
        .then((_) {
          controller.add(4);
          return controller.close();
        })
        .then((_) => new Future.delayed(new Duration(milliseconds : 10)))
        .then((_) {
          expect(list.length, equals(3),   reason : "throttled stream should have only three events");
          expect(list, equals([ 0, 3, 4]), reason : "throttled stream should contain values 0, 3 and 4");

          expect(hasErr, equals(true), reason : "throttled stream should have received error");
          expect(isDone, equals(true), reason : "throttled stream should be completed");
        });
    });

  void _throttleCloseOnError() =>
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.throttle(input, new Duration(milliseconds : 1), closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);
      controller.add(3);

      return new Future
        .delayed(new Duration(milliseconds : 2))
        .then((_) {
          controller.add(4);
          controller.addError("failed");
          controller.add(5); // this should not be received since the error would have closed the output stream

          return controller.close();
        })
        .then((_) => new Future.delayed(new Duration(milliseconds : 10)))
        .then((_) {
          expect(list.length, equals(3),   reason : "throttled stream should have only three events");
          expect(list, equals([ 0, 3, 4]), reason : "throttled stream should contain values 0, 3 and 4");

          expect(hasErr, equals(true), reason : "throttled stream should have received error");
          expect(isDone, equals(true), reason : "throttled stream should be completed");
        });
    });
}