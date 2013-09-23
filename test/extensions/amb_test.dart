part of stream_ext_test;

class AmbTests {
  void start() {
    group('amb', () {
      _ambFirstStreamWins();
      _ambSecondStreamWins();
      _ambNoValues();
      _errorsBeforeValueAreIgnored();
      _ambNotCloseOnError();
      _ambCloseOnError();
    });
  }

  void _ambFirstStreamWins() {
    test('fst stream wins', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.amb(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0); // win!
      controller2.add(1); // ignored
      controller2.add(2); // ignored
      controller1.add(3);

      Future
        .wait([ controller1.close(), controller2.close() ])
        .then((_) {
          expect(list.length, equals(2), reason : "output stream should contain 2 values");
          expect(list, equals([ 0, 3 ]), reason : "output stream should contain values 0 and 3");

          expect(hasErr, equals(false), reason : "output stream should not have received error");
          expect(isDone, equals(true),  reason : "output stream should be completed");
        });
    });
  }

  void _ambSecondStreamWins() {
    test('snd stream wins', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.amb(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller2.add(0); // win!
      controller1.add(1); // ignored
      controller2.add(2);
      controller1.add(3); // ignored

      Future
        .wait([ controller1.close(), controller2.close() ])
        .then((_) {
          expect(list.length, equals(2), reason : "output stream should contain 2 values");
          expect(list, equals([ 0, 2 ]), reason : "output stream should contain values 0 and 2");

          expect(hasErr, equals(false), reason : "output stream should not have received error");
          expect(isDone, equals(true),  reason : "output stream should be completed");
        });
    });
  }

  void _ambNoValues() {
    test('no values', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.amb(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      Future
        .wait([ controller1.close(), controller2.close() ])
        .then((_) {
          expect(list.length, equals(0), reason : "output stream should contain no value");

          expect(hasErr, equals(false), reason : "output stream should not have received error");
          expect(isDone, equals(true),  reason : "output stream should be completed");
        });
    });
  }

  void _errorsBeforeValueAreIgnored() {
    test('errors before value ignored', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.amb(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.addError("failed"); // ignored
      controller2.addError("failed"); // ignored
      controller1.add(0); // win!
      controller2.add(1); // ignored
      controller2.add(2); // ignored
      controller1.add(3);

      Future
        .wait([ controller1.close(), controller2.close() ])
        .then((_) {
          expect(list.length, equals(2), reason : "output stream should contain 2 values");
          expect(list, equals([ 0, 3 ]), reason : "output stream should contain values 0 and 3");

          expect(hasErr, equals(false), reason : "output stream should not have received error");
          expect(isDone, equals(true),  reason : "output stream should be completed");
        });
    });
  }

  void _ambNotCloseOnError() {
    test('not close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var errors = new List();
      var isDone = false;
      StreamExt.amb(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : errors.add,
                 onDone  : ()  => isDone = true);

      controller1.add(0); // wins!
      controller2.addError("failed"); // ignored
      controller1.add(1);
      controller1.addError("failed2");
      controller1.add(2);
      controller2.add(3); // ignored

      Future
        .wait([ controller1.close(), controller2.close() ])
        .then((_) {
          expect(list.length, equals(3), reason : "output stream should have 3 values");
          expect(list, equals([ 0, 1, 2 ]), reason : "output stream should contain values 0, 1 and 2");

          expect(errors, equals([ "failed2" ]), reason : "output stream should have received error");
          expect(isDone, equals(true), reason : "output stream should be completed");
        });
    });
  }

  void _ambCloseOnError() {
    test('close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var errors = new List();
      var isDone = false;
      StreamExt.amb(stream1, stream2, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : errors.add,
                 onDone  : ()  => isDone = true);

      controller1.addError("failed1"); // ignored
      controller2.addError("failed2"); // ignored
      controller1.add(0); // wins!
      controller2.addError("failed3"); // ignored
      controller1.add(1);
      controller1.addError("failed4");
      controller2.add(2);

      expect(list.length, equals(2), reason : "output stream should have 2 values before the error");
      expect(list, equals([ 0, 1 ]), reason : "output stream should contain the event values 0 and 1");

      expect(errors, equals([ "failed4" ]), reason : "output stream should have received error");
      expect(isDone, equals(true), reason : "output stream should be completed");

      controller1.close();
      controller2.close();
    });
  }
}