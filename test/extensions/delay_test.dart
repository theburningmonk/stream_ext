part of stream_ext_test;

class DelayTests {
  void start() {
    group('delay', () {
      _mergeWithNoErrors();
    });
  }

  void _mergeWithNoErrors() {
    test("no errors", () {
      var data    = new List.generate(5, (n) => n);
      var origin  = new Stream.fromIterable(data);

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.delay(origin, new Duration(milliseconds : 1))
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      expect(list.length, lessThan(5), reason : "delayed stream should not have populated delayed list");

      // since each event is delayed by 1 milliseconds, give it some buffer space and check after 15 ms if
      // all the delayed events have been processed
      new Timer(new Duration(milliseconds : 10), () {
        expect(list.length, equals(5), reason : "delayed stream should have populated delayed list");
        expect(hasErr, equals(false), reason : "delayed stream should not have received error");
        expect(isDone, equals(true),  reason : "delayed stream should be completed");
      });
    });
  }
}