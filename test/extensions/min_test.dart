part of stream_ext_test;

class MinTests {
  int compare(a, b) => a.compareTo(b);

  void start() {
    group('min', () {
      _minWithInts();
      _minWithDoubles();
      _minWithMixOfIntsAndDoubles();
      _minNotCloseOnError();
      _minCloseOnError();
      _minWithUserErrorNotCloseOnError();
      _minWithUserErrorCloseOnError();
      _minWithMapper();
    });
  }

  void _minWithInts() {
    test("with ints", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.min(input, compare, sync : true);

      controller.add(3);
      controller.add(2);
      controller.add(1);
      controller.add(4);
      controller.close()
        .then((_) => result)
        .then((min) => expect(min, equals(1), reason : "min should be 1"));
    });
  }

  void _minWithDoubles() {
    test("with doubles", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<double> result = StreamExt.min(input, compare, sync : true);

      controller.add(3.5);
      controller.add(2.5);
      controller.add(1.5);
      controller.add(4.5);
      controller.close()
        .then((_) => result)
        .then((min) => expect(min, equals(1.5), reason : "min should be 1.5"));
    });
  }

  void _minWithMixOfIntsAndDoubles() {
    test("with mix of ints and doubles", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<num> result = StreamExt.min(input, compare, sync : true);

      controller.add(3);
      controller.add(2.5);
      controller.add(1);
      controller.add(4.5);
      controller.close()
        .then((_) => result)
        .then((min) => expect(min, equals(1), reason : "min should be 1"));
    });
  }

  void _minNotCloseOnError() {
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.min(input, compare, sync : true);

      controller.add(3);
      controller.add(2);
      controller.addError("failed");
      controller.add(1);
      controller.add(4);
      controller.close()
        .then((_) => result)
        .then((min) => expect(min, equals(1), reason : "min should be 1"));
    });
  }

  void _minCloseOnError() {
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var error;
      Future<int> result = StreamExt.min(input, compare, closeOnError : true, sync : true)
                              .catchError((err) => error = err);

      controller.add(1);
      controller.add(2);
      controller.addError("failed");
      controller.add(3);
      controller.add(4);
      controller.close()
        .then((_) => result)
        .then((_) => expect(error, equals("failed"), reason : "min should have failed"));
    });
  }

  void _minWithUserErrorNotCloseOnError() {
    test("with user error not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.min(input, compare, sync : true);

      controller.add(3);
      controller.add(2.5);
      controller.add("3"); // this should cause error but ignored
      controller.add(4.5);
      controller.close()
        .then((_) => result)
        .then((min) => expect(min, equals(2.5), reason : "min should be 2.5"));
    });
  }

  void _minWithUserErrorCloseOnError() {
    test("with user error close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var error;
      Future<int> result = StreamExt.min(input, compare, closeOnError : true, sync : true)
                              .catchError((err) => error = err);

      controller.add(2.5);
      controller.add(1);
      controller.add("failed"); // this should cause error and terminate the sum
      controller.add(4.5);
      controller.close()
        .then((_) => result)
        .then((_) => expect(error is TypeError, equals(true), reason : "min should have failed"));
    });
  }

  void _minWithMapper() {
    test("with mapper", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.min(input, (String l, String r) => l.length.compareTo(r.length), sync : true);

      controller.add("hello");
      controller.add(" ");
      controller.add("world");
      controller.add("!");
      controller.close()
        .then((_) => result)
        .then((min) => expect(min, equals(" "), reason : "min should be ' '"));
    });
  }
}