part of stream_ext_test;

class MergeTests {
  void start() {
    group('merge', () {
      _mergeWithNoErrors();
      _mergeNotCloseOnError();
      _mergeCloseOnError();
    });
  }

  void _mergeWithNoErrors() {
    test('no errors', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.merge(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.add(1);
      controller2.add(2);
      controller1.add(3);

      Future
        .wait([ controller1.close(), controller2.close() ])
        .then((_) {
          expect(list.length, equals(4), reason : "merged stream should contain 4 values");
          expect(list, equals([ 0, 1, 2, 3 ]), reason : "merged stream should contain values 0, 1, 2 and 3");

          expect(hasErr, equals(false), reason : "merged stream should not have received error");
          expect(isDone, equals(true),  reason : "merged stream should be completed");
        });
    });
  }

  void _mergeNotCloseOnError() {
    test('not close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.merge(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.addError("failed");
      controller1.add(1);
      controller2.add(2);

      Future
        .wait([ controller1.close(), controller2.close() ])
        .then((_) {
          expect(list.length, equals(3), reason : "merged stream should have all three events");
          expect(list, equals([ 0, 1, 2 ]), reason : "merged stream should contain values 0, 1 and 2");

          expect(hasErr, equals(true), reason : "merged stream should have received error");
          expect(isDone, equals(true), reason : "merged stream should be completed");
        });
    });
  }

  void _mergeCloseOnError() {
    test('close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.merge(stream1, stream2, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.addError("failed");
      controller1.add(1);
      controller2.add(2);

      Future
        .wait([ controller1.close(), controller2.close() ])
        .then((_) {
          expect(list.length, equals(1), reason : "merged stream should have only one event before the error");
          expect(list[0],     equals(0), reason : "merged stream should contain the event value 0");

          expect(hasErr, equals(true), reason : "merged stream should have received error");
          expect(isDone, equals(true), reason : "merged stream should be completed");
        });
    });
  }
}