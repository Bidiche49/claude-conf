/// Fixture: a class with fields, ctor, public/private methods, getter.

class SampleClass {
  SampleClass(this.id, this._secret);

  final String id;
  final int _secret;

  int compute(int x) => x + _secret;

  int _hidden() => _secret * 2;

  String get description => 'SampleClass($id)';
}
