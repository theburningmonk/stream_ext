part of stream_ext_test;

class OnErrorResumeNextTests {
  void start() {
    group('onErrorResumeNext', () {
      _resumeWithNoErrors();
      _resumeStream2CompletesBeforeStream1();
      _resumeWithError();
      _resumeNotCloseOnError();
      _resumeCloseOnError();
    });
  }

  void _resumeWithNoErrors() =>
    test('no errors', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.onErrorResumeNext(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.add(1); // ignored
      controller2.add(2); // ignored
      controller1.add(3);

      return controller1
        .close() // now should be yielding from stream2
        .then((_) {
          controller2.add(4);
          controller2.add(5);
          return controller2.close();
        })
        .then((_) {
          expect(list.length, equals(4),       reason : "resumed stream should contain 4 values");
          expect(list, equals([ 0, 3, 4, 5 ]), reason : "resumed stream should contain values 0, 3, 4 and 5");

          expect(hasErr, equals(false), reason : "resumed stream should not have received error");
          expect(isDone, equals(true),  reason : "resumed stream should be completed");
        });
    });

  void _resumeStream2CompletesBeforeStream1() =>
    test('stream 2 completes before stream 1', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.onErrorResumeNext(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.add(1); // ignored
      controller2.add(2); // ignored
      controller1.add(3);

      return controller2
        .close()
        .then((_) {
          controller1.add(4);
          return controller1.close(); // since stream 2 is already done this should close the stream straight away
        })
        .then((_) {
          expect(list.length, equals(3),    reason : "resumed stream should contain 3 values");
          expect(list, equals([ 0, 3, 4 ]), reason : "resumed stream should contain values 0, 3 and 4");

          expect(hasErr, equals(false), reason : "resumed stream should not have received error");
          expect(isDone, equals(true),  reason : "resumed stream should be completed");
        });
    });

  void _resumeWithError() =>
    test('resume on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.onErrorResumeNext(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.add(1); // ignored
      controller2.add(2); // ignored
      controller1.add(3);
      controller1.addError("failed"); // now should be yielding from stream2
      controller1.add(4); // ignored
      controller2.add(5);

      return controller2
        .close()
        .then((_) {
            expect(list.length, equals(3),    reason : "resumed stream should contain 3 values");
            expect(list, equals([ 0, 3, 5 ]), reason : "resumed stream should contain values 0, 3 and 5");

            expect(hasErr, equals(false), reason : "resumed stream should not have received error");
            expect(isDone, equals(true),  reason : "resumed stream should be completed");
          })
        .then((_) => controller1.close());
    });

  void _resumeNotCloseOnError() =>
    test('not close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var errors = new List();
      var isDone = false;
      StreamExt.onErrorResumeNext(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : errors.add,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.add(1); // ignored
      controller2.addError("failed1"); // ignored since we're still yield stream 1
      controller2.add(2); // ignored
      controller1.addError("failed2"); // now start yielding stream 2
      controller1.add(3); // ignored
      controller1.close();
      controller2.add(4);
      controller2.addError("failed3");
      controller2.add(5);

      return controller2
        .close()
        .then((_) {
          expect(list.length, equals(3),    reason : "resumed stream should have only 3 events");
          expect(list, equals([ 0, 4, 5 ]), reason : "resumed stream should contain values 0, 4 and 5");

          expect(errors, equals([ "failed3" ]), reason : "resumed stream should have received error");
          expect(isDone, equals(true), reason : "resumed stream should be completed");
        });
    });

  void _resumeCloseOnError() =>
    test('close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var error;
      var isDone = false;
      StreamExt.onErrorResumeNext(stream1, stream2, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (err) => error = err,
                 onDone  : ()    => isDone = true);

      controller1.add(0);
      controller2.addError("failed1"); // ignored
      controller1.add(1);

      return controller1
        .close()
        .then((_) {
          controller2.addError("failed2"); // should close the output stream
          controller2.add(2);

          expect(list.length, equals(2), reason : "resumed stream should have only two events before the error");
          expect(list,        equals([ 0, 1 ]), reason : "resumed stream should contain the values 0 and 1");

          expect(error,  equals("failed2"), reason : "resumed stream should have received error");
          expect(isDone, equals(true),      reason : "resumed stream should be completed");

          return controller2.close();
        });
    });
}