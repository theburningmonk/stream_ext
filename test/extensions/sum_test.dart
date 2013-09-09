part of stream_ext_test;

class SumTests {
  void start() {
    group('sum', () {
      _sumWithInts();
      _sumWithDoubles();
      _sumWithMixOfIntsAndDoubles();
      _sumWithMapper();
    });
  }

  void _sumWithInts() {
    test("with ints", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.sum(input, sync : true)
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

  void _sumWithDoubles() {
    test("with doubles", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.sum(input, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(1.5);
      controller.add(2.5);
      controller.add(3.5);
      controller.add(4.5);
      controller.close().then((_) {
        expect(list.length, equals(4), reason : "output stream should have 4 events");
        expect(list, equals([ 1.5, 4.0, 7.5, 12.0 ]),
               reason : "output stream should contain values 1.0, 3.0, 6.0 and 10.0");

        expect(hasErr, equals(false), reason : "output stream should not have received error");
        expect(isDone, equals(true),  reason : "output stream should be completed");
      });
    });
  }

  void _sumWithMixOfIntsAndDoubles() {
    test("with mix of ints and doubles", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.sum(input, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add(1);
      controller.add(2.5);
      controller.add(3);
      controller.add(4.5);
      controller.close().then((_) {
        expect(list.length, equals(4), reason : "output stream should have 4 events");
        expect(list, equals([ 1, 3.5, 6.5, 11 ]),
               reason : "output stream should contain values 1, 3.5, 6.5 and 11");

        expect(hasErr, equals(false), reason : "output stream should not have received error");
        expect(isDone, equals(true), reason : "output stream should be completed");
      });
    });
  }

  void _sumWithMapper() {
    test("with mapper", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var list    = new List();
      var hasErr  = false;
      var isDone  = false;
      StreamExt.sum(input, map : (String str) => str.length, sync : true)
        ..listen(list.add,
                 onError : (_) => hasErr = true,
                 onDone  : ()  => isDone = true);

      controller.add("hello");
      controller.add(" ");
      controller.add("world");
      controller.add("!");
      controller.close().then((_) {
        expect(list.length, equals(4), reason : "output stream should have 4 events");
        expect(list, equals([ 5, 6, 11, 12 ]),
               reason : "output stream should contain values 5, 6, 11 and 12");

        expect(hasErr, equals(false), reason : "output stream should not have received error");
        expect(isDone, equals(true), reason : "output stream should be completed");
      });
    });
  }
}