part of stream_ext_test;

class CombineLatestTests {
  void start() {
    group('combineLatest', () {
      _combineLatestWithNoErrors();
      _combineLatestNotCloseOnError();
      _combineLatestCloseOnError();
      _combineLatestWithUserNotCloseOnError();
      _combineLatestWithUserErrorCloseOnError();
    });
  }

  void _combineLatestWithNoErrors() {
    test('no errors', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.combineLatest(stream1, stream2, (a, b) => "($a, $b)", sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller1.add(1);
      controller2.add(2); // paired with 1
      controller2.add(3); // paired with 1
      controller1.add(4); // paired with 3

      var future1 = controller1.close();
      controller2.add(5); // paired with 4
      var future2 = controller2.close();

      Future
        .wait([ future1, future2 ])
        .then((_) {
          expect(list.length, equals(4), reason : "combined stream should have four combined events");
          expect(list, equals([ "(1, 2)", "(1, 3)", "(4, 3)", "(4, 5)" ]),
                 reason : "combined stream should contain the event value (1, 2), (1, 3), (4, 3) and (4, 5)");

          expect(hasErr, equals(false), reason : "combined stream should not have received error");
          expect(isDone, equals(true),  reason : "combined stream should be completed");
        });
    });
  }

  void _combineLatestNotCloseOnError() {
    test('not close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.combineLatest(stream1, stream2, (a, b) => "($a, $b)", sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.addError("failed");
      controller1.add(1);
      controller2.add(2); // paired with 1

      controller1.addError("failed");
      var future1 = controller1.close();
      controller2.add(3); // paired with 1
      var future2 = controller2.close();

      Future
        .wait([ future1, future2 ])
        .then((_) {
          expect(list.length, equals(2), reason : "combined stream should have two combind events");
          expect(list, equals([ "(1, 2)", "(1, 3)" ]), reason : "combined stream should contain the event value (1, 2) and (1, 3)");

          expect(hasErr, equals(true), reason : "combined stream should have received error");
          expect(isDone, equals(true), reason : "combined stream should be completed");
        });
    });
  }

  void _combineLatestCloseOnError() {
    test('close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.combineLatest(stream1, stream2, (a, b) => "($a, $b)", closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.add(1); // paired with 0
      controller2.add(2); // paired with 0
      controller2.addError("failed");
      controller1.add(3);
      controller2.add(4);

      new Timer(new Duration(milliseconds : 5), () {
        expect(list.length, equals(2), reason : "combined stream should have two events before the error");
        expect(list, equals([ "(0, 1)", "(0, 2)" ]), reason : "combined stream should contain the event value (0, 1) and (0, 2)");

        expect(hasErr, equals(true), reason : "combined stream should have received error");
        expect(isDone, equals(true), reason : "combined stream should be completed");
      });
    });
  }

  void _combineLatestWithUserNotCloseOnError() {
    test('with user error not close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var error;
      var isDone = false;

      // passes on a function that will except if given the wrong type of value
      StreamExt.combineLatest(stream1, stream2, (a, b) => a + b, sync : true)
        ..listen(list.add,
                 onError : (err) {
                   hasErr = true;
                   error  = err;
                 },
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.add(1); // paired with 0
      controller2.add(2); // paired with 0
      controller1.add("3"); // this should cause error
      controller1.add(3); // paired with 2

      Future
      .wait([ controller1.close(), controller2.close() ])
        .then((_) {
          expect(list.length, equals(3), reason : "combined stream should have three combind events");
          expect(list, equals([ 1, 2, 5 ]), reason : "combined stream should contain the event value 1, 2 and 5");

          expect(hasErr, equals(true), reason : "combined stream should have received error");
          expect(error is TypeError,  equals(true),  reason : "combined stream should have received a TypeError");
          expect(isDone, equals(true), reason : "combined stream should be completed");
        });
    });
  }

  void _combineLatestWithUserErrorCloseOnError() {
    test('with user error close on rrror', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var error;
      var isDone = false;

      // passes on a function that will except if given the wrong type of value
      StreamExt.combineLatest(stream1, stream2, (a, b) => a + b, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (err) {
                   hasErr = true;
                   error  = err;
                 },
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.add(1); // paired with 0
      controller2.add(2); // paired with 0
      controller1.add("3"); // this should cause error
      controller1.add(3);

      new Timer(new Duration(milliseconds : 5), () {
        expect(list.length, equals(2), reason : "combined stream should have two events before the error");
        expect(list, equals([ 1, 2 ]), reason : "combined stream should contain the event value 1 and 2");

        expect(hasErr, equals(true), reason : "combined stream should have received error");
        expect(error is TypeError,  equals(true),  reason : "combined stream should have received a TypeError");
        expect(isDone, equals(true), reason : "combined stream should be completed");
      });
    });
  }
}