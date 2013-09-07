part of stream_ext_test;

class ThrottleTests {
  void start() {
    group('throttle', () {
      _throttleWithNoErrors();
    });
  }

  void _throttleWithNoErrors() {
    test("no errors", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.throttle(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);
      controller.add(3);

      new Timer(new Duration(milliseconds : 2), () {
        controller.add(4);
        new Timer(new Duration(milliseconds : 2), () {
          controller.close();
        });
      });

      new Timer(new Duration(milliseconds : 10), () {
        expect(list.length, equals(3),   reason : "throttled stream should have only three events");
        expect(list, equals([ 0, 3, 4]), reason : "throttled stream should contain values 0, 3 and 4");

        expect(hasErr, equals(false), reason : "delayed stream should not have received error");
        expect(isDone, equals(true),  reason : "delayed stream should be completed");
      });
    });
  }
}