/// Canonical record type identifiers used across the app.
///
/// Keep this list aligned with the product requirements in SPEC.md (Records
/// CRUD UI). UI layers should prefer these constants and `values` helper to
/// avoid typos.
class RecordTypes {
  static const String visit = 'visit';
  static const String lab = 'lab';
  static const String medication = 'med';
  static const String note = 'note';

  static const List<String> values = [
    visit,
    lab,
    medication,
    note,
  ];

  static bool isValid(String value) => values.contains(value);
}
