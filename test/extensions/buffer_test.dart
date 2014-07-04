part of stream_ext_test;

class BufferTests {
  void start() {
    group('buffer', () {
      _bufferWithNoErrors();
      _bufferNotCloseOnError();
      _bufferCloseOnError();
    });
  }

  void _bufferWithNoErrors() =>
    test("no errors", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.buffer(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);

      return new Future
        .delayed(new Duration(milliseconds : 2))
        .then((_) {
          controller.add(3);
          controller.add(4);
          return controller.close();
        })
        .then((_) {
          expect(list.length, equals(2),   reason : "buffered stream should have two events");
          expect(list, equals([ [ 0, 1, 2 ], [ 3, 4 ] ]), reason : "buffered stream should contain lists [ 0, 1, 2 ] and [ 3, 4 ]");

          expect(hasErr, equals(false), reason : "buffered stream should not have received error");
          expect(isDone, equals(true),  reason : "buffered stream should be completed");
        });
    });

  void _bufferNotCloseOnError() =>
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.buffer(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.addError("failed");
      controller.add(2);

      return new Future
        .delayed(new Duration(milliseconds : 2))
        .then((_) {
          controller.add(3);
          controller.add(4);
          return controller.close();
        })
        .then((_) {
          expect(list.length, equals(2), reason : "buffered stream should have two events");
          expect(list, equals([ [ 0, 1, 2 ], [ 3, 4 ] ]), reason : "buffered stream should contain lists [ 0, 1, 2 ], [ 3, 4 ]");

          expect(hasErr, equals(true), reason : "buffered stream should have received error");
          expect(isDone, equals(true), reason : "buffered stream should be completed");
        });
    });

  void _bufferCloseOnError() =>
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.buffer(input, new Duration(milliseconds : 1), closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);

      return new Future
        .delayed(new Duration(milliseconds : 2))
        .then((_) {
          controller.add(3);
          controller.add(4);
          controller.addError("failed");
          return controller.close();
        })
        .then((_) {
          expect(list.length, equals(1), reason : "buffered stream should have only one event before the error");
          expect(list, equals([ [ 0, 1, 2 ] ]), reason : "buffered stream should contain list [ 0, 1, 2 ]");

          expect(hasErr, equals(true), reason : "buffered stream should have received error");
          expect(isDone, equals(true), reason : "buffered stream should be completed");
        });
    });
}