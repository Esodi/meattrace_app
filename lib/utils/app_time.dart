import 'package:intl/intl.dart' as intl;

/// The whole app displays dates and times in East Africa Time (GMT+3, no
/// daylight saving) regardless of the viewing device's own timezone —
/// otherwise the same sale/transfer/receipt shows a different time to
/// every viewer depending on how their phone happens to be configured.
class AppTime {
  static const Duration offset = Duration(hours: 3);

  /// Converts [dt] to the fixed GMT+3 wall-clock time. [dt] may be UTC
  /// (the normal case — the backend serializes timestamps with an explicit
  /// UTC offset, which `DateTime.parse` respects) or already device-local;
  /// either way this first normalizes to UTC before applying the fixed
  /// offset, so the result never depends on the device's timezone setting.
  static DateTime toAppTime(DateTime dt) => dt.toUtc().add(offset);

  /// The current moment, in GMT+3.
  static DateTime now() => toAppTime(DateTime.now());
}

/// Drop-in replacement for [intl.DateFormat] that always formats in GMT+3.
/// Construct and use exactly like DateFormat:
/// `AppDateFormat('dd/MM/yyyy').format(someDateTime)`.
class AppDateFormat {
  final intl.DateFormat _inner;

  AppDateFormat([String? newPattern, String? locale])
      : _inner = intl.DateFormat(newPattern, locale);

  String format(DateTime dateTime) => _inner.format(AppTime.toAppTime(dateTime));
}
