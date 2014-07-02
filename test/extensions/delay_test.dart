part of stream_ext_test;

class DelayTests {
  void start() {
    group('delay', () {
      _delayWithNoErrors();
      _delayNotCloseOnError();
      _delayCloseOnError();
    });
  }

  void _delayWithNoErrors() {
    test("no errors", () {
      var data    = new List.generate(3, (n) => n);
      var input   = new Stream.fromIterable(data);

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.delay(input, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      // since events are delayed by 1 milliseconds, give it some buffer space and check after 5 ms if
      // all the delayed events have been processed
      Future future = new Future.delayed(new Duration(milliseconds : 10), () {
        expect(list.length, equals(3), reason : "delayed stream should have all three events");

        for (var i = 0; i <= 2; i++) {
          expect(list.where((n) => n == i).length, equals(1), reason : "delayed stream should contain $i");
        }

        expect(hasErr, equals(false), reason : "delayed stream should not have received error");
        expect(isDone, equals(true),  reason : "delayed stream should be completed");
      });

      expect(future, completes);
    });
  }

  void _delayNotCloseOnError() {
    test('not close on error', () {
      var controller  = new StreamController.broadcast(sync : true);
      var origin      = controller.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.delay(origin, new Duration(milliseconds : 1), sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);
      controller.addError("failed");
      controller.add(1);
      controller.add(2);
      controller.close();

      Future future = new Future.delayed(new Duration(milliseconds : 2), () {
        expect(list.length, equals(3), reason : "delayed stream should have all three events");

        for (var i = 0; i <= 2; i++) {
          expect(list.where((n) => n == i).length, equals(1), reason : "delayed stream should contain $i");
        }

        expect(hasErr, equals(true), reason : "delayed stream should have received error");
        expect(isDone, equals(true), reason : "delayed stream should be completed");
      });

      expect(future, completes);
    });
  }

  void _delayCloseOnError() {
    test('close on error', () {
      var controller  = new StreamController.broadcast(sync : true);
      var origin      = controller.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.delay(origin, new Duration(milliseconds : 1), closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(0);

      // give sufficient time for the first message to be delivered before sending error
      new Timer(new Duration(milliseconds : 2), () {
        controller.addError("failed");
        controller.add(1);
        controller.add(2);
      });

      // closing the controllers happen asynchronously, so give it a few milliseconds for both to complete and trigger
      // the merged stream to also complete
      Future future = new Future.delayed(new Duration(milliseconds : 5), () {
        expect(list.length, equals(1), reason : "delayed stream should have only event before error");
        expect(list[0], equals(0),     reason : "delayed stream should contain the event value 0");

        expect(hasErr, equals(true), reason : "delayed stream should have received error");
        expect(isDone, equals(true), reason : "delayed stream should be completed");
      });

      expect(future, completes);
    });
  }
}