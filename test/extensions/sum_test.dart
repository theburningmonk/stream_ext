part of stream_ext_test;

class SumTests {
  void start() {
    group('sum', () {
      _sumWithInts();
      _sumWithDoubles();
      _sumWithMixOfIntsAndDoubles();
      _sumNotCloseOnError();
      _sumCloseOnError();
      _sumWithUserErrorNotCloseOnError();
      _sumWithUserErrorCloseOnError();
      _sumWithMapper();
    });
  }

  void _sumWithInts() =>
    test("with ints", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.sum(input, sync : true);

      controller.add(1);
      controller.add(2);
      controller.add(3);
      controller.add(4);

      return controller
        .close()
        .then((_) => result)
        .then((sum) => expect(sum, equals(10), reason : "sum should be 10"));
    });

  void _sumWithDoubles() =>
    test("with doubles", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<double> result = StreamExt.sum(input, sync : true);

      controller.add(1.5);
      controller.add(2.5);
      controller.add(3.5);
      controller.add(4.5);

      return controller
        .close()
        .then((_) => result)
        .then((sum) => expect(sum, equals(12.0), reason : "sum should be 12.0"));
    });

  void _sumWithMixOfIntsAndDoubles() =>
    test("with mix of ints and doubles", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<num> result = StreamExt.sum(input, sync : true);

      controller.add(1);
      controller.add(2.5);
      controller.add(3);
      controller.add(4.5);

      return controller
        .close()
        .then((_) => result)
        .then((sum) => expect(sum, equals(11), reason : "sum should be 11"));
    });

  void _sumNotCloseOnError() =>
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.sum(input, sync : true);

      controller.add(1);
      controller.add(2);
      controller.addError("failed");
      controller.add(3);
      controller.add(4);

      return controller
        .close()
        .then((_) => result)
        .then((sum) => expect(sum, equals(10), reason : "sum should be 10"));
    });

  void _sumCloseOnError() =>
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var error;
      Future<int> result = StreamExt.sum(input, closeOnError : true, sync : true)
                              .catchError((err) => error = err);

      controller.add(1);
      controller.add(2);
      controller.addError("failed");
      controller.add(3);
      controller.add(4);

      return controller
        .close()
        .then((_) => result)
        .then((_) => expect(error, equals("failed"), reason : "sum should have failed"));
    });

  void _sumWithUserErrorNotCloseOnError() =>
    test("with user error not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.sum(input, sync : true);

      controller.add(1);
      controller.add(2.5);
      controller.add("3"); // this should cause error but ignored
      controller.add(4.5);

      return controller
        .close()
        .then((_) => result)
        .then((sum) => expect(sum, equals(8), reason : "sum should be 8"));
    });

  void _sumWithUserErrorCloseOnError() =>
    test("with user error close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var error;
      Future<int> result = StreamExt.sum(input, closeOnError : true, sync : true)
                              .catchError((err) => error = err);

      controller.add(1);
      controller.add(2.5);
      controller.add("failed"); // this should cause error and terminate the sum
      controller.add(4.5);

      return controller
        .close()
        .then((_) => result)
        .then((_) => expect(error is TypeError, equals(true), reason : "sum should have failed"));
    });

  void _sumWithMapper() =>
    test("with mapper", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.sum(input, map : (String str) => str.length, sync : true);

      controller.add("hello");
      controller.add(" ");
      controller.add("world");
      controller.add("!");

      return controller
        .close()
        .then((_) => result)
        .then((sum) => expect(sum, equals(12), reason : "sum should be 12"));
    });
}