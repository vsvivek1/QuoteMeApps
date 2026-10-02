/// Minimal local-time conversion for the zones both apps send outreach to,
/// used only by the pre-send business-hours check. The database re-checks
/// with the full tz database (`private.outreach_in_business_hours`).
///
/// Returns null for an unknown zone so callers fall back to a default.
DateTime? localTimeIn(String? timezone, DateTime instant) {
  final utc = instant.toUtc();
  final zone = _zones[timezone];
  if (zone == null) return null;
  var offsetMinutes = zone.standardOffsetMinutes;
  if (zone.usDst && _inUsDst(utc, zone.standardOffsetMinutes)) offsetMinutes += 60;
  final shifted = utc.add(Duration(minutes: offsetMinutes));
  // Return a "wall clock" value with no zone semantics.
  return DateTime(shifted.year, shifted.month, shifted.day, shifted.hour, shifted.minute, shifted.second);
}

bool isKnownTimezone(String? timezone) => _zones.containsKey(timezone);

/// Weekdays 09:30 to 17:00 local, matching the database rule.
bool isBusinessHours(DateTime local) {
  if (local.weekday > DateTime.friday) return false;
  final minutes = local.hour * 60 + local.minute;
  return minutes >= 9 * 60 + 30 && minutes <= 17 * 60;
}

class _Zone {
  const _Zone(this.standardOffsetMinutes, {this.usDst = false});
  final int standardOffsetMinutes;
  final bool usDst;
}

const _zones = <String, _Zone>{
  'Asia/Kolkata': _Zone(330),
  'Asia/Calcutta': _Zone(330),
  'America/New_York': _Zone(-300, usDst: true),
  'America/Detroit': _Zone(-300, usDst: true),
  'America/Indiana/Indianapolis': _Zone(-300, usDst: true),
  'America/Chicago': _Zone(-360, usDst: true),
  'America/Denver': _Zone(-420, usDst: true),
  'America/Boise': _Zone(-420, usDst: true),
  'America/Phoenix': _Zone(-420),
  'America/Los_Angeles': _Zone(-480, usDst: true),
  'America/Anchorage': _Zone(-540, usDst: true),
  'Pacific/Honolulu': _Zone(-600),
  'UTC': _Zone(0),
};

/// US DST: from the second Sunday of March 02:00 local standard time to the
/// first Sunday of November 02:00 local daylight time.
bool _inUsDst(DateTime utc, int standardOffsetMinutes) {
  final year = utc.year;
  final start = _nthSunday(year, 3, 2).add(Duration(hours: 2, minutes: -standardOffsetMinutes));
  final end = _nthSunday(year, 11, 1).add(Duration(hours: 1, minutes: -standardOffsetMinutes));
  return !utc.isBefore(start) && utc.isBefore(end);
}

DateTime _nthSunday(int year, int month, int n) {
  var d = DateTime.utc(year, month, 1);
  while (d.weekday != DateTime.sunday) {
    d = d.add(const Duration(days: 1));
  }
  return d.add(Duration(days: 7 * (n - 1)));
}
