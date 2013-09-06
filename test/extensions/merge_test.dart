part of stream_ext_test;

class MergeTests {
  void start() {
    group('merge', () {
      _mergeWithNoErrors();
      _mergeNotCloseOnError();
      _mergeCloseOnError();
    });
  }

  void _mergeWithNoErrors() {
    test('no errors', () {
      var data = new List.generate(10, (n) => n);
      var stream1 = new Stream.fromIterable(data);
      var stream2 = new Stream.fromIterable(data);

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.merge(stream1, stream2).take(10)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      new Timer(new Duration(milliseconds : 5), () {
        expect(list.length, equals(10), reason : "merged stream should contain 10 values");

        for (var i = 0; i <= 4; i++) {
          expect(list.where((n) => n == i).length, equals(2), reason : "merged stream should contain 2 instances of [$i]");
        }

        expect(hasErr, equals(false), reason : "merged stream should not have received error");
        expect(isDone, equals(true),  reason : "merged stream should be completed");
      });
    });
  }

  void _mergeNotCloseOnError() {
    test('not close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.merge(stream1, stream2, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.addError("failed");
      controller1.add(1);
      controller2.add(2);

      controller1.close();
      controller2.close();

      // closing the controllers happen asynchronously, so give it a few milliseconds for both to complete and trigger
      // the merged stream to also complete
      new Timer(new Duration(milliseconds : 5), () {
        expect(list.length, equals(3), reason : "merged stream should have all three events");

        for (var i = 0; i <= 2; i++) {
          expect(list.where((n) => n == i).length, equals(1));
        }

        expect(hasErr, equals(true), reason : "merged stream should have received error");
        expect(isDone, equals(true), reason : "merged stream should be completed");
      });
    });
  }

  void _mergeCloseOnError() {
    test('close on error', () {
      var controller1 = new StreamController.broadcast(sync : true);
      var controller2 = new StreamController.broadcast(sync : true);

      var stream1 = controller1.stream;
      var stream2 = controller2.stream;

      var list   = new List();
      var hasErr = false;
      var isDone = false;
      StreamExt.merge(stream1, stream2, closeOnError : true, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller1.add(0);
      controller2.addError("failed");
      controller1.add(1);
      controller2.add(2);

      controller1.close();
      controller2.close();

      // closing the controllers happen asynchronously, so give it a few milliseconds for both to complete and trigger
      // the merged stream to also complete
      new Timer(new Duration(milliseconds : 5), () {
        expect(list.length, equals(1), reason : "merged stream should have only one event before the error");
        expect(list[0],     equals(0), reason : "merged stream should contain the event value 0");

        expect(hasErr, equals(true), reason : "merged stream should have received error");
        expect(isDone, equals(true), reason : "merged stream should be completed");
      });
    });
  }
}