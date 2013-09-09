part of stream_ext_test;

class ZipTests {
  void start() {
    group('zip', () {
      _zipWithNoErrors();
      _zipNotCloseOnError();
      _zipCloseOnError();
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

      var future2 = controller2.close();
      var future1 = controller1.close();

      Future
        .wait([ future1, future2 ])
        .then((_) {
          expect(list.length, equals(1),   reason : "zipped stream should have only one event before the error");
          expect(list, equals([ "0, 3" ]), reason : "zipped stream should contain values (0, 3)");

          expect(hasErr, equals(true), reason : "zipped stream should have received error");
          expect(isDone, equals(true), reason : "zipped stream should be completed");
        });
    });
  }
}