part of stream_ext_test;

class TimeOutAtTests {
  void start() {
    group('timeOutAt', () {
      _timeOutAtWithNoValues();
      _timeOutAtWithValues();
      _timeOutAtNotCloseOnError();
      _timeOutAtCloseOnError();
    });
  }

  void _timeOutAtWithNoValues() {
    test("no values", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var dueTime = new DateTime.now().add(new Duration(milliseconds : 1));
      var list    = new List();
      var error;
      var isDone  = false;
      StreamExt.timeOutAt(input, dueTime, sync : true)
        ..listen(list.add,
                 onError : (err) => error = err,
                 onDone  : ()    => isDone = true);

      new Future.delayed(new Duration(milliseconds : 2), () {
        expect(list.length, equals(0),   reason : "output stream should have no value");

        expect(error is TimeoutError, equals(true), reason : "output stream should have received a timeout error");
        expect(isDone, equals(true),  reason : "output stream should be completed");
      }).then((_) => controller.close());
    });
  }

  void _timeOutAtWithValues() {
    test("with values", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var dueTime = new DateTime.now().add(new Duration(milliseconds : 1));
      var list    = new List();
      var error;
      var isDone  = false;
      StreamExt.timeOutAt(input, dueTime, sync : true)
        ..listen(list.add,
                 onError : (err) => error = err,
                 onDone  : ()    => isDone = true);

      controller.add(0);

      new Future.delayed(new Duration(milliseconds : 2), () {
        expect(list.length, equals(1), reason : "output stream should have 1 value");
        expect(list, equals([ 0 ]), reason : "output stream should contain the value 1");

        expect(error is TimeoutError, equals(true), reason : "output stream should have received a timeout error");
        expect(isDone, equals(true),  reason : "output stream should be completed");
      }).then((_) => controller.close());
    });
  }

  void _timeOutAtNotCloseOnError() {
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var dueTime = new DateTime.now().add(new Duration(milliseconds : 1));
      var list    = new List();
      var errors  = new List();
      var isDone  = false;
      StreamExt.timeOutAt(input, dueTime, sync : true)
        ..listen(list.add,
                 onError : errors.add,
                 onDone  : () => isDone = true);

      controller.add(0);
      controller.addError("failed");
      controller.add(1);

      new Future.delayed(new Duration(milliseconds : 2), () {
        expect(list.length, equals(2), reason : "output stream should have 2 value");
        expect(list, equals([ 0, 1 ]), reason : "output stream should contain the values 0 and 1");

        expect(errors.length, equals(2), reason : "output stream should have received 2 errors");
        expect(errors[0], equals("failed"), reason : "output stream should have an error value 'failed'");
        expect(errors[1] is TimeoutError, equals(true), reason : "output stream should have received a timeout error");
        expect(isDone, equals(true),  reason : "output stream should be completed");
      }).then((_) => controller.close());
    });
  }

  void _timeOutAtCloseOnError() {
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var dueTime = new DateTime.now().add(new Duration(milliseconds : 1));
      var list    = new List();
      var errors  = new List();
      var isDone  = false;
      StreamExt.timeOutAt(input, dueTime, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : errors.add,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.addError("failed");
      controller.add(1);

      new Future.delayed(new Duration(milliseconds : 2), () {
        expect(list.length, equals(1), reason : "output stream should have only 1 value before the error");
        expect(list, equals([ 0 ]), reason : "output stream should contain the value 0");

        expect(errors.length, equals(1), reason : "output stream should have received 1 error");
        expect(errors, equals([ "failed" ]), reason : "output stream should not have received a timeout error");
        expect(isDone, equals(true),  reason : "output stream should be completed");
      }).then((_) => controller.close());
    });
  }
}