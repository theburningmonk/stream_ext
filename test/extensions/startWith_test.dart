part of stream_ext_test;

class StartWithTests {
  void start() {
    group('startWith', () {
      _startWithWithNoErrors();
      _startWithNotCloseOnError();
      _startWithCloseOnError();
    });
  }

  void _startWithWithNoErrors() {
    test('no errors', () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.startWith(input, [ -3, -2, -1 ], sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);
      controller.close()
        .then((_) {
          expect(list.length, equals(6), reason : "output stream should contain 6 values");
          expect(list, equals([ -3, -2, -1, 0, 1, 2 ]),
                 reason : "output stream should contain values from -3 to 2");

          expect(hasErr, equals(false), reason : "output stream should not have received error");
          expect(isDone, equals(true),  reason : "output stream should be completed");
        });
    });
  }

  void _startWithNotCloseOnError() {
    test('not close on error', () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.startWith(input, [ -3, -2, -1 ], sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.addError("failed");
      controller.add(2);
      controller.close()
        .then((_) {
          expect(list.length, equals(6), reason : "output stream should contain 6 values");
          expect(list, equals([ -3, -2, -1, 0, 1, 2 ]), reason : "output stream should contain values from -3 to 2");

          expect(hasErr, equals(true), reason : "output stream should have received error");
          expect(isDone, equals(true), reason : "output stream should be completed");
        });
    });
  }

  void _startWithCloseOnError() {
    test('close on error', () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.startWith(input, [ -3, -2, -1 ], closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.addError("failed");
      controller.add(1);
      controller.add(2);

      controller.close()
        .then((_) {
          expect(list.length, equals(4), reason : "output stream should have only four events before the error");
          expect(list,        equals([ -3, -2, -1, 0 ]), reason : "output stream should contain the event value 0");

          expect(hasErr, equals(true), reason : "output stream should have received error");
          expect(isDone, equals(true), reason : "output stream should be completed");
        });
    });
  }
}