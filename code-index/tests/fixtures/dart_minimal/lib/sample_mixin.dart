/// Fixture: a mixin with a public method and a getter.

mixin SampleMixin {
  String greet(String who) => 'Hello, $who';

  int get magicNumber => 42;
}
