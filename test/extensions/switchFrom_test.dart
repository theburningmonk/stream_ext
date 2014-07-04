part of stream_ext_test;

class SwitchFromTests {
  void start() {
    group('switchFrom', () {
      _switchStreamsWithValues();
      _swtichActiveStreamClosesFirst();
      _swtichNotCloseOnError();
      _swtichCloseOnError();
    });
  }

  void _switchStreamsWithValues() =>
    test('all streams produced value', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);
      var controller  = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;
      var input   = controller.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.switchFrom(input, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(stream1);
      controller1.add(0);
      controller1.add(1);
      controller.add(stream2);
      controller1.add(2); // ignore
      controller2.add(3);
      controller2.add(4);

      return controller
        .close()
        .then((_) {
          controller2.add(5);
          return controller2.close();
        })
        .then((_) {
          expect(list.length, equals(5), reason : "output stream should contain 5 values");
          expect(list, equals([ 0, 1, 3, 4, 5 ]), reason : "output stream should contain values 0, 1, 3, 4 and 5");

          expect(hasErr, equals(false), reason : "output stream should not have received error");
          expect(isDone, equals(true),  reason : "output stream should be completed");
        })
        .then((_) => controller1.close());
    });

  void _swtichActiveStreamClosesFirst() =>
    test('active stream closes first', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);
      var controller  = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;
      var input   = controller.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.switchFrom(input, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(stream1);
      controller.add(stream2);

      return controller2
        .close() // the active stream closes first but the input stream is still going
        .then((_) => expect(isDone, equals(false), reason : "output stream should be closed only after the input stream closes"))
        .then((_) => controller.close())
        .then((_) {
          expect(list.length, equals(0), reason : "output stream should contain no values");

          expect(hasErr, equals(false), reason : "output stream should not have received error");
          expect(isDone, equals(true),  reason : "output stream should be completed");
        })
        .then((_) => controller1.close());
    });

  void _swtichNotCloseOnError() =>
    test('not close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);
      var controller  = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;
      var input   = controller.stream;

      var list   = new List();
      var errors = new List();
      var isDone = false;
      StreamExt.switchFrom(input, sync : true)
        ..listen(list.add,
                 onError : errors.add,
                 onDone  : ()  => isDone = true);

      controller.add(stream1);
      controller1.add(0);
      controller1.addError("failed1");
      controller1.add(1);
      controller.add(stream2);
      controller2.add(2);
      controller1.addError("failed2"); // ignored
      controller2.addError("failed3");
      controller2.add(3);

      return controller
        .close() // the input stream closes first but the active stream is still going
        .then((_) => expect(isDone, equals(false), reason : "output stream should be closed only after the active stream closes"))
        .then((_) => controller2.close())
        .then((_) {
          expect(list.length, equals(4), reason : "output stream should contain 4 values");
          expect(list, equals([ 0, 1, 2, 3 ]), reason : "output stream should contain values 0, 1, 2 and 3");

          expect(errors, equals([ "failed1", "failed3" ]), reason : "output stream should have received error");
          expect(isDone, equals(true),  reason : "output stream should be completed");
        })
        .then((_) => controller1.close());
    });

  void _swtichCloseOnError() =>
    test('close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);
      var controller  = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;
      var input   = controller.stream;

      var list   = new List();
      var errors = new List();
      var isDone = false;
      StreamExt.switchFrom(input, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : errors.add,
                 onDone  : ()  => isDone = true);

      controller.add(stream1);
      controller1.add(0);
      controller1.addError("failed1");
      controller1.add(1);
      controller.add(stream2);
      controller2.add(2);
      controller1.addError("failed2"); // ignored
      controller2.addError("failed3");
      controller2.add(3);

      expect(list.length, equals(1), reason : "output stream should contain 1 value");
      expect(list, equals([ 0 ]), reason : "output stream should contain values 0");

      expect(errors, equals([ "failed1" ]), reason : "output stream should have received error");
      expect(isDone, equals(true),  reason : "output stream should be completed");

      return Future.wait([ controller1.close(), controller2.close() ]);
    });
}