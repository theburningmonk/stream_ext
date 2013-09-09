part of stream_ext_test;

class WindowTests {
  void start() {
    group('window', () {
      _windowWithNoErrors();
      _windowNotCloseOnError();
      _windowCloseOnError();
    });
  }

  void _windowWithNoErrors() {
    test("no errors", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.window(input, 3, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);
      controller.add(3);
      controller.add(4);
      controller.add(5);
      controller.add(6);

      controller.close();

      new Timer(new Duration(milliseconds : 5), () {
        expect(list.length, equals(3),   reason : "windowed stream should have three events");
        expect(list, equals([ [ 0, 1, 2 ], [ 3, 4, 5 ], [ 6 ] ]),
               reason : "windowed stream should contain lists [ 0, 1, 2 ], [ 3, 4, 5 ] and [ 6 ]");

        expect(hasErr, equals(false), reason : "windowed stream should not have received error");
        expect(isDone, equals(true),  reason : "windowed stream should be completed");
      });
    });
  }

  void _windowNotCloseOnError() {
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.window(input, 3, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.addError("failed");
      controller.add(2);
      controller.add(3);
      controller.add(4);
      controller.add(5);
      controller.add(6);

      controller.close();

      new Timer(new Duration(milliseconds : 5), () {
        expect(list.length, equals(3),   reason : "windowed stream should have three events");
        expect(list, equals([ [ 0, 1, 2 ], [ 3, 4, 5 ], [ 6 ] ]),
               reason : "windowed stream should contain lists [ 0, 1, 2 ], [ 3, 4, 5 ] and [ 6 ]");

        expect(hasErr, equals(true), reason : "windowed stream should have received error");
        expect(isDone, equals(true), reason : "windowed stream should be completed");
      });
    });
  }

  void _windowCloseOnError() {
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.window(input, 3, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);
      controller.add(3);
      controller.addError("failed");
      controller.add(4);

      controller.close();

      new Timer(new Duration(milliseconds : 5), () {
        expect(list.length, equals(1),   reason : "windowed stream should have only one event before the error");
        expect(list, equals([ [ 0, 1, 2 ] ]),
               reason : "windowed stream should contain list [ 0, 1, 2 ]");

        expect(hasErr, equals(true), reason : "windowed stream should have received error");
        expect(isDone, equals(true), reason : "windowed stream should be completed");
      });
    });
  }
}