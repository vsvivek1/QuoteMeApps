/// Small RFC 4180 CSV reader / writer (quoted fields, escaped quotes,
/// embedded commas and newlines, CRLF or LF line endings).
List<List<String>> parseCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;
  // Strip a UTF-8 byte-order mark.
  final text = input.startsWith('﻿') ? input.substring(1) : input;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"' && field.isEmpty) {
      inQuotes = true;
    } else if (c == ',') {
      endField();
    } else if (c == '\r') {
      if (i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
    } else if (c == '\n') {
      endRow();
    } else {
      field.write(c);
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

String toCsv(List<List<Object?>> rows) => rows.map((r) => r.map(_cell).join(',')).join('\r\n');

String _cell(Object? v) {
  var s = v?.toString() ?? '';
  // Neutralise spreadsheet formula injection in exported data.
  if (s.isNotEmpty && '=+-@'.contains(s[0])) s = "'$s";
  if (s.contains(RegExp('[",\r\n]'))) return '"${s.replaceAll('"', '""')}"';
  return s;
}
