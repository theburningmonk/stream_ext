part of stream_ext_test;

class ZipTests {
  void start() {
    group('zip', () {
      _zipWithNoErrors();
      _zipNotCloseOnError();
      _zipCloseOnError();
      _zipWithUserErrorNotCloseOnError();
      _zipWithUserErrorCloseOnError();
    });
  }

  void _zipWithNoErrors() {
    test("no errors", () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);
      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.zip(stream1, stream2, (a, b) => "$a, $b", sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller1.add(1);
      controller2.add(3); // paired with 0
      controller2.add(4); // paired with 1
      controller2.add(5);
      controller1.add(2); // paired with 2

      var future2 = controller2.close();
      controller1.add(6); // not received since other stream is complete
      var future1 = controller1.close();

      Future
        .wait([ future1, future2 ])
        .then((_) {
          expect(list.length, equals(3),   reason : "zipped stream should have three events");
          expect(list, equals([ "0, 3", "1, 4", "2, 5" ]),
                 reason : "zipped stream should contain values (0, 3), (1, 4) and (2, 5)");

          expect(hasErr, equals(false), reason : "zipped stream should not have received error");
          expect(isDone, equals(true),  reason : "zipped stream should be completed");
        });
    });
  }

  void _zipNotCloseOnError() {
    test("not close on error", () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);
      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.zip(stream1, stream2, (a, b) => "$a, $b", sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller1.add(1);
      controller2.addError("failed");
      controller2.add(3); // paired with 0
      controller2.add(4); // paired with 1
      controller1.addError("failed");
      controller2.add(5);
      controller1.add(2); // paired with 2

      var future2 = controller2.close();
      controller1.add(6); // not received since other stream is complete
      var future1 = controller1.close();

      Future
        .wait([ future1, future2 ])
        .then((_) {
          expect(list.length, equals(3),   reason : "zipped stream should have three events");
          expect(list, equals([ "0, 3", "1, 4", "2, 5" ]),
                 reason : "zipped stream should contain values (0, 3), (1, 4) and (2, 5)");

          expect(hasErr, equals(true), reason : "zipped stream should have received error");
          expect(isDone, equals(true), reason : "zipped stream should be completed");
        });
    });
  }

  void _zipCloseOnError() {
    test("close on error", () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);
      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.zip(stream1, stream2, (a, b) => "$a, $b", closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller1.add(1);
      controller2.add(3); // paired with 0
      controller1.addError("failed");
      controller2.add(4); // not paired

      new Timer(new Duration(milliseconds : 5), () {
        expect(list.length, equals(1),   reason : "zipped stream should have only one event before the error");
        expect(list, equals([ "0, 3" ]), reason : "zipped stream should contain values (0, 3)");

        expect(hasErr, equals(true), reason : "zipped stream should have received error");
        expect(isDone, equals(true), reason : "zipped stream should be completed");
      });
    });
  }

  void _zipWithUserErrorNotCloseOnError() {
    test("with user error not close on error", () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);
      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list      = new List();
      var numErrors = 0;
      var errors    = new List();
      var isDone    = false;
      StreamExt.zip(stream1, stream2, (a, b) => a + b, sync : true)
        ..listen(list.add,
                 onError : (err) {
                   numErrors++;
                   errors.add(err);
                 },
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller1.add(1);
      controller2.add(3); // paired with 0
      controller2.add("4"); // should cause error
      controller2.add(4); // will still error since "4" is the next value to be processed

      Future
        .wait([ controller1.close(), controller2.close() ])
        .then((_) {
          expect(list.length, equals(1), reason : "zipped stream should have only one event before bad value");
          expect(list, equals([ 3 ]), reason : "zipped stream should contain values 3");

          expect(numErrors, equals(2), reason : "zipped stream should have received 2 errors");
          expect(errors.every((x) => x is TypeError), equals(true), reason : "zipped stream should have received TypeErrors");
          expect(isDone, equals(true), reason : "zipped stream should be completed");
        });
    });
  }

  void _zipWithUserErrorCloseOnError() {
    test("with user error close on error", () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);
      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list    = new List();
      var numErrors = 0;
      var errors    = new List();
      var isDone  = false;
      StreamExt.zip(stream1, stream2, (a, b) => a + b, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (err) {
                   numErrors++;
                   errors.add(err);
                 },
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller1.add(1);
      controller2.add(3); // paired with 0
      controller2.add("4"); // should cause error
      controller2.add(4); // stream should be closed by now

      new Timer(new Duration(milliseconds : 5), () {
        expect(list.length, equals(1), reason : "zipped stream should have only one event before bad value");
        expect(list, equals([ 3 ]), reason : "zipped stream should contain values 3");

        expect(numErrors, equals(1), reason : "zipped stream should have received 1 error");
        expect(errors.every((x) => x is TypeError), equals(true), reason : "zipped stream should have received TypeError");
        expect(isDone, equals(true), reason : "zipped stream should be completed");
      });
    });
  }
}