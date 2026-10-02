import 'package:intl/intl.dart';

String fmtDate(DateTime? d) => d == null ? '-' : DateFormat.yMMMd().format(d.toLocal());
String fmtDateTime(DateTime? d) => d == null ? '-' : DateFormat.yMMMd().add_Hm().format(d.toLocal());
String fmtInt(int? v) => v == null ? 'n/a' : NumberFormat.decimalPattern().format(v);
String fmtPct(double? v) => v == null ? 'n/a' : '${v.toStringAsFixed(1)}%';
String fmtMins(double? v) {
  if (v == null) return 'n/a';
  if (v < 60) return '${v.round()} min';
  return '${(v / 60).toStringAsFixed(1)} h';
}
