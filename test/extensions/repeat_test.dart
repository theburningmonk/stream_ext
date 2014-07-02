part of stream_ext_test;

class RepeatTests {
  void start() {
    group('repeat', () {
      _repeatWithNoErrors(0);
      _repeatWithNoErrors(1);
      _repeatWithNoErrors(2);
      _repeatNotCloseOnError(0);
      _repeatNotCloseOnError(1);
      _repeatNotCloseOnError(2);
      _repeatCloseOnError();
    });
  }

  void _repeatWithNoErrors(int repeatCount) {
    test('$repeatCount times no errors', () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.repeat(input, repeatCount : repeatCount, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);

      Future future = controller.close().then((_) => new Future.delayed(new Duration(milliseconds : 2 * (repeatCount + 1))));
      future.then((_) {
            expect(list.length, equals(3 * (1 + repeatCount)), reason : "repeated [$repeatCount] stream should contain ${3 * (1 + repeatCount)} values");
            expect(list, equals(new List.generate(1 + repeatCount, (i) => i).expand((_) => [ 0, 1, 2 ])),
                   reason : "repeated stream should contain ${1 + repeatCount} sets of [ 0, 1, 2 ]");

            expect(hasErr, equals(false), reason : "repeated stream should not have received error");
            expect(isDone, equals(true),  reason : "repeated stream should be completed");
        });

      expect(future, completes);
    });
  }

  void _repeatNotCloseOnError(int repeatCount) {
    test('$repeatCount times not close on error', () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list   = new List();
      var errors = new List();
      var isDone = false;
      StreamExt.repeat(input, repeatCount : repeatCount, sync : true)
        ..listen(list.add,
                 onError : errors.add,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.addError("failed");
      controller.add(2);

      Future future = controller.close().then((_) => new Future.delayed(new Duration(milliseconds : 2 * (repeatCount + 1))));
      future.then((_) {
          expect(list.length, equals(3 * (1 + repeatCount)), reason : "repeated [$repeatCount] stream should contain ${3 * (1 + repeatCount)} values");
          expect(list, equals(new List.generate(1 + repeatCount, (i) => i).expand((_) => [ 0, 1, 2 ])),
                 reason : "repeated stream should contain ${1 + repeatCount} sets of [ 0, 1, 2 ]");

          expect(errors, equals([ "failed" ]), reason : "repeated stream should have received error only once (not repeated)");
          expect(isDone, equals(true),  reason : "repeated stream should be completed");
        });

      expect(future, completes);
    });
  }

  void _repeatCloseOnError() {
    test('close on error', () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list   = new List();
      var error;
      var isDone = false;
      StreamExt.repeat(input, repeatCount : 1, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (err) => error = err,
                 onDone  : ()    => isDone = true);

      controller.add(0);
      controller.addError("failed");
      controller.add(1);
      controller.add(2);

      expect(list.length, equals(1),      reason : "repeated stream should have only one event before the error");
      expect(list,        equals([ 0 ] ), reason : "repeated stream should contain the value 0");

      expect(error,  equals("failed"), reason : "repeated stream should have received error");
      expect(isDone, equals(true),     reason : "repeated stream should be completed");
    });
  }
}