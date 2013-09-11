part of stream_ext_test;

class MaxTests {
  int compare(a, b) => a.compareTo(b);

  void start() {
    group('max', () {
      _maxWithInts();
      _maxWithDoubles();
      _maxWithMixOfIntsAndDoubles();
      _maxNotCloseOnError();
      _maxCloseOnError();
      _maxWithUserErrorNotCloseOnError();
      _maxWithUserErrorCloseOnError();
      _maxWithMapper();
    });
  }

  void _maxWithInts() {
    test("with ints", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.max(input, compare, sync : true);

      controller.add(3);
      controller.add(2);
      controller.add(1);
      controller.add(4);
      controller.close()
        .then((_) => result)
        .then((max) => expect(max, equals(4), reason : "max should be 4"));
    });
  }

  void _maxWithDoubles() {
    test("with doubles", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<double> result = StreamExt.max(input, compare, sync : true);

      controller.add(3.5);
      controller.add(2.5);
      controller.add(1.5);
      controller.add(4.5);
      controller.close()
        .then((_) => result)
        .then((max) => expect(max, equals(4.5), reason : "max should be 4.5"));
    });
  }

  void _maxWithMixOfIntsAndDoubles() {
    test("with mix of ints and doubles", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<num> result = StreamExt.max(input, compare, sync : true);

      controller.add(3);
      controller.add(2.5);
      controller.add(1);
      controller.add(4.5);
      controller.close()
        .then((_) => result)
        .then((max) => expect(max, equals(4.5), reason : "max should be 4.5"));
    });
  }

  void _maxNotCloseOnError() {
    test("not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.max(input, compare, sync : true);

      controller.add(3);
      controller.add(2);
      controller.addError("failed");
      controller.add(1);
      controller.add(4);
      controller.close()
        .then((_) => result)
        .then((max) => expect(max, equals(4), reason : "max should be 4"));
    });
  }

  void _maxCloseOnError() {
    test("close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var error;
      Future<int> result = StreamExt.max(input, compare, closeOnError : true, sync : true)
                              .catchError((err) => error = err);

      controller.add(1);
      controller.add(2);
      controller.addError("failed");
      controller.add(3);
      controller.add(4);
      controller.close()
        .then((_) => result)
        .then((_) => expect(error, equals("failed"), reason : "max should have failed"));
    });
  }

  void _maxWithUserErrorNotCloseOnError() {
    test("with user error not close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.max(input, compare, sync : true);

      controller.add(3);
      controller.add(2.5);
      controller.add("3"); // this should cause error but ignored
      controller.add(4.5);
      controller.close()
        .then((_) => result)
        .then((max) => expect(max, equals(4.5), reason : "max should be 4.5"));
    });
  }

  void _maxWithUserErrorCloseOnError() {
    test("with user error close on error", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      var error;
      Future<int> result = StreamExt.max(input, compare, closeOnError : true, sync : true)
                              .catchError((err) => error = err);

      controller.add(2.5);
      controller.add(1);
      controller.add("failed"); // this should cause error and terminate the sum
      controller.add(4.5);
      controller.close()
        .then((_) => result)
        .then((_) => expect(error is TypeError, equals(true), reason : "max should have failed"));
    });
  }

  void _maxWithMapper() {
    test("with mapper", () {
      var controller = new StreamController.broadcast(sync : true);
      var input      = controller.stream;

      Future<int> result = StreamExt.max(input, (String l, String r) => l.length.compareTo(r.length), sync : true);

      controller.add("hello");
      controller.add(" ");
      controller.add("world");
      controller.add("!");
      controller.close()
        .then((_) => result)
        .then((max) => expect(max, equals("hello"), reason : "max should be 'hello'"));
    });
  }
}