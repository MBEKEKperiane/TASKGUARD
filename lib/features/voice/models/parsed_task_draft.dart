import 'package:flutter/material.dart';

class ParsedTaskDraft {
  final String title;
  final DateTime? date;
  final TimeOfDay? time;
  final String priority; // LOW | MEDIUM | HIGH | URGENT
  final String rawTranscript;

  const ParsedTaskDraft({
    required this.title,
    required this.priority,
    required this.rawTranscript,
    this.date,
    this.time,
  });

  bool get hasDate => date != null;
  bool get hasTime => time != null;

  DateTime? get combinedDateTime {
    if (date == null) return null;
    final t = time ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(date!.year, date!.month, date!.day, t.hour, t.minute);
  }
}
