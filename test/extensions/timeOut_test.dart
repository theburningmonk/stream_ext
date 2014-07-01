part of stream_ext_test;

class TimeOutTests {
  void start() {
    group('timeOut', () {
      _timeOutWithNoValues();
      _timeOutWithGapInValues();
      _timeOutNotCloseOnError();
      _timeOutCloseOnError();
    });
  }

  void _timeOutWithNoValues() {
    test("no values", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var error;
      var isDone  = false;
      StreamExt.timeOut(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (err) => error = err,
                 onDone  : ()    => isDone = true);

      Future future = new Future.delayed(new Duration(milliseconds : 2)).then((_) => controller.close());
      future.then((_) {
        expect(list.length, equals(0),   reason : "output stream should have no value");

        expect(error is TimeoutError, equals(true), reason : "output stream should have received a timeout error");
        expect(isDone, equals(true),  reason : "output stream should be completed");
      });
      
      expect(future, completes);
    });
  }

  void _timeOutWithGapInValues() {
    test("gap in values", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var error;
      var isDone  = false;
      StreamExt.timeOut(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (err) => error = err,
                 onDone  : ()    => isDone = true);

      controller.add(0);

      Future future = new Future.delayed(new Duration(milliseconds : 2)).then((_) => controller.close());
      future.then((_) {
        expect(list.length, equals(1), reason : "output stream should have 1 value");
        expect(list, equals([ 0 ]), reason : "output stream should contain the value 1");

        expect(error is TimeoutError, equals(true), reason : "output stream should have received a timeout error");
        expect(isDone, equals(true),  reason : "output stream should be completed");
      });
      
      expect(future, completes);
    });
  }

  void _timeOutNotCloseOnError() {
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var errors  = new List();
      var isDone  = false;
      StreamExt.timeOut(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : errors.add,
                 onDone  : () => isDone = true);

      controller.add(0);
      controller.addError("failed");
      controller.add(1);

      Future future = new Future.delayed(new Duration(milliseconds : 2)).then((_) => controller.close());
      future.then((_) {
        expect(list.length, equals(2), reason : "output stream should have 2 value");
        expect(list, equals([ 0, 1 ]), reason : "output stream should contain the values 0 and 1");

        expect(errors.length, equals(2), reason : "output stream should have received 2 errors");
        expect(errors[0], equals("failed"), reason : "output stream should have an error value 'failed'");
        expect(errors[1] is TimeoutError, equals(true), reason : "output stream should have received a timeout error");
        expect(isDone, equals(true),  reason : "output stream should be completed");
      });
      
      expect(future, completes);
    });
  }

  void _timeOutCloseOnError() {
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var errors  = new List();
      var isDone  = false;
      StreamExt.timeOut(input, new Duration(milliseconds : 1), closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : errors.add,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.addError("failed");
      controller.add(1);

      Future future = new Future.delayed(new Duration(milliseconds : 2)).then((_) => controller.close());
      future.then((_) {
        expect(list.length, equals(1), reason : "output stream should have only 1 value before the error");
        expect(list, equals([ 0 ]), reason : "output stream should contain the value 0");

        expect(errors.length, equals(1), reason : "output stream should have received 1 error");
        expect(errors, equals([ "failed" ]), reason : "output stream should not have received a timeout error");
        expect(isDone, equals(true),  reason : "output stream should be completed");
      });
      
      expect(future, completes);
    });
  }
}