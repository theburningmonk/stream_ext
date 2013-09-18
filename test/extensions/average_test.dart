part of stream_ext_test;

class AverageTests {
  void start() {
    group('average', () {
      _avgWithInts();
      _avgWithDoubles();
      _avgWithMixOfIntsAndDoubles();
      _avgNotCloseOnError();
      _avgCloseOnError();
      _avgWithUserErrorNotCloseOnError();
      _avgWithUserErrorCloseOnError();
      _avgWithMapper();
    });
  }

  void _avgWithInts() {
    test("with ints", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.average(input, sync : true);

      controller.add(1);
      controller.add(2);
      controller.add(3);
      controller.add(4);
      controller.close()
        .then((_) => result)
        .then((avg) => expect(avg, equals(2.5), reason : "avg should be 2.5"));
    });
  }

  void _avgWithDoubles() {
    test("with doubles", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<double> result = StreamExt.average(input, sync : true);

      controller.add(1.5);
      controller.add(2.5);
      controller.add(3.5);
      controller.add(4.9);
      controller.close()
        .then((_) => result)
        .then((avg) => expect(avg, equals(3.1), reason : "avg should be 3.1"));
    });
  }

  void _avgWithMixOfIntsAndDoubles() {
    test("with mix of ints and doubles", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<num> result = StreamExt.average(input, sync : true);

      controller.add(1);
      controller.add(2.5);
      controller.add(3);
      controller.add(5.9);
      controller.close()
        .then((_) => result)
        .then((avg) => expect(avg, equals(3.1), reason : "avg should be 3.1"));
    });
  }

  void _avgNotCloseOnError() {
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.average(input, sync : true);

      controller.add(1);
      controller.add(2);
      controller.addError("failed");
      controller.add(3);
      controller.add(4);
      controller.close()
        .then((_) => result)
        .then((avg) => expect(avg, equals(2.5), reason : "avg should be 2.5"));
    });
  }

  void _avgCloseOnError() {
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var error;
      Future<int> result = StreamExt.average(input, closeOnError : true, sync : true)
                              .catchError((err) => error = err);

      controller.add(1);
      controller.add(2);
      controller.addError("failed");
      controller.add(3);
      controller.add(4);
      controller.close()
        .then((_) => result)
        .then((_) => expect(error, equals("failed"), reason : "avg should have failed"));
    });
  }

  void _avgWithUserErrorNotCloseOnError() {
    test("with user error not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.average(input, sync : true);

      controller.add(2);
      controller.add(2.5);
      controller.add("3"); // this should cause error but ignored
      controller.add(4.5);
      controller.close()
        .then((_) => result)
        .then((avg) => expect(avg, equals(3), reason : "avg should be 3"));
    });
  }

  void _avgWithUserErrorCloseOnError() {
    test("with user error close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var error;
      Future<int> result = StreamExt.average(input, closeOnError : true, sync : true)
                              .catchError((err) => error = err);

      controller.add(1);
      controller.add(2.5);
      controller.add("failed"); // this should cause error and terminate the avg
      controller.add(4.5);
      controller.close()
        .then((_) => result)
        .then((_) => expect(error is TypeError, equals(true), reason : "avg should have failed"));
    });
  }

  void _avgWithMapper() {
    test("with mapper", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.average(input, map : (String str) => str.length, sync : true);

      controller.add("hello");
      controller.add(" ");
      controller.add("world");
      controller.add("!");
      controller.close()
        .then((_) => result)
        .then((avg) => expect(avg, equals(3), reason : "avg should be 3"));
    });
  }
}