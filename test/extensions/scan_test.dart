part of stream_ext_test;

class ScanTests {
  void start() {
    group('scan', () {
      _scanWithNoErrors();
      _scanNotCloseOnError();
      _scanCloseOnError();
    });
  }

  void _scanWithNoErrors() {
    test("no errors", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.scan(input, 0, (a, b) => a + b, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(1);
      controller.add(2);
      controller.add(3);
      controller.add(4);
      controller.close().then((_) {
        expect(list.length, equals(4), reason : "output stream should have 4 events");
        expect(list, equals([ 1, 3, 6, 10 ]),
               reason : "output stream should contain values 1, 3, 6 and 10");

        expect(hasErr, equals(false), reason : "output stream should not have received error");
        expect(isDone, equals(true),  reason : "output stream should be completed");
      });
    });
  }

  void _scanNotCloseOnError() {
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.scan(input, 0, (a, b) => a + b, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(1);
      controller.add(2);
      controller.addError("failed");
      controller.add(3);
      controller.add(4);
      controller.close().then((_) {
        expect(list.length, equals(4), reason : "output stream should have 4 events");
        expect(list, equals([ 1, 3, 6, 10 ]),
               reason : "output stream should contain values 1, 3, 6 and 10");

        expect(hasErr, equals(true), reason : "output stream should have received error");
        expect(isDone, equals(true), reason : "output stream should be completed");
      });
    });
  }

  void _scanCloseOnError() {
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.scan(input, 0, (a, b) => a + b, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(1);
      controller.add(2);
      controller.addError("failed");
      controller.add(3);
      controller.add(4);
      controller.close().then((_) {
        expect(list.length, equals(2), reason : "output stream should have only two events before the error");
        expect(list, equals([ 1, 3 ]),
               reason : "output stream should contain values 1 and 3");

        expect(hasErr, equals(true), reason : "output stream should have received error");
        expect(isDone, equals(true), reason : "output stream should be completed");
      });
    });
  }
}