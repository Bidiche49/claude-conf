/// Fixture: an extension on String.

extension SampleExtension on String {
  String shout() => '${toUpperCase()}!';

  int get charCount => length;
}
