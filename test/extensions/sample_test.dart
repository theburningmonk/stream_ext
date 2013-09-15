part of stream_ext_test;

class SampleTests {
  void start() {
    group('sample', () {
      _sampleWithNoErrors();
      _sampleIgnoresEmptyTimeWindows();
      _sampleNotCloseOnError();
      _sampleCloseOnError();
    });
  }

  void _sampleWithNoErrors() {
    test("no errors", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.sample(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);
      controller.add(3);

      new Timer(new Duration(milliseconds : 1), () {
        controller.add(4);
        controller.close()
          .then((_) {
            expect(list.length, equals(2), reason : "sampled stream should have only two events");
            expect(list, equals([ 3, 4 ]), reason : "sampled stream should contain values 3 and 4");

            expect(hasErr, equals(false),  reason : "sampled stream should not have received error");
            expect(isDone, equals(true),   reason : "sampled stream should be completed");
          });
      });
    });
  }

  void _sampleIgnoresEmptyTimeWindows() {
    test("no errors", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.sample(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);
      controller.add(3);

      new Timer(new Duration(milliseconds : 2), () {
        controller.close()
          .then((_) {
            expect(list.length, equals(1), reason : "sampled stream should have only one event");
            expect(list, equals([ 3 ]),    reason : "sampled stream should contain value 3");

            expect(hasErr, equals(false),  reason : "sampled stream should not have received error");
            expect(isDone, equals(true),   reason : "sampled stream should be completed");
          });
      });
    });
  }

  void _sampleNotCloseOnError() {
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var error;
      var isDone  = false;
      StreamExt.sample(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (err) => error = err,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.addError("failed");
      controller.add(1);
      controller.add(2);
      controller.add(3);

      new Timer(new Duration(milliseconds : 1), () {
        controller.add(4);
        controller.close()
          .then((_) {
            expect(list.length, equals(2),    reason : "sampled stream should have only two events");
            expect(list, equals([ 3, 4 ]),    reason : "sampled stream should contain values 3 and 4");

            expect(error,  equals("failed"),  reason : "sampled stream should have received error");
            expect(isDone, equals(true),      reason : "sampled stream should be completed");
          });
      });
    });
  }

  void _sampleCloseOnError() {
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var error;
      var isDone  = false;
      StreamExt.sample(input, new Duration(milliseconds : 1), closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (err) => error = err,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.add(1);
      controller.add(2);
      controller.add(3);

      new Timer(new Duration(milliseconds : 1), () {
        controller.add(4); // this should not be received since the error would interrupt the sample window
        controller.addError("failed");
        controller.add(5);
        controller.close();
      });

      new Timer(new Duration(milliseconds : 10), () {
        expect(list.length, equals(1),  reason : "sampled stream should have only one event");
        expect(list, equals([ 3 ]),     reason : "sampled stream should contain value 3");

        expect(error, equals("failed"), reason : "sampled stream should have received error");
        expect(isDone, equals(true),    reason : "sampled stream should be completed");
      });
    });
  }
}