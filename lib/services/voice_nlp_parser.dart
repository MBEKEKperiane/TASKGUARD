import 'package:flutter/material.dart';
import '../features/voice/models/parsed_task_draft.dart';

/// Fully offline regex-based NLP that extracts task fields from a spoken transcript.
class VoiceNlpParser {
  VoiceNlpParser._();

  static ParsedTaskDraft parse(String transcript) {
    var text = transcript.trim();

    // ── 1. Strip common voice command prefixes ────────────────────────────────
    text = _stripPrefixes(text);

    // ── 2. Extract priority (remove matched phrase from text) ─────────────────
    final (:priority, :remaining) = _extractPriority(text);
    text = remaining;

    // ── 3. Extract time (before date, to avoid "at" ambiguity) ───────────────
    final (time: extractedTime, remaining: afterTime) = _extractTime(text);
    text = afterTime;

    // ── 4. Extract date ───────────────────────────────────────────────────────
    final (date: extractedDate, remaining: afterDate) = _extractDate(text);
    text = afterDate;

    // ── 5. Clean what's left → title ─────────────────────────────────────────
    final title = _cleanTitle(text);

    return ParsedTaskDraft(
      title: title.isEmpty ? _sentenceCase(transcript.trim()) : title,
      date: extractedDate,
      time: extractedTime,
      priority: priority,
      rawTranscript: transcript,
    );
  }

  // ── Prefix stripping ────────────────────────────────────────────────────────

  static final _prefixes = [
    r"remind me (to |about )?",
    r"reminder (to |for |about )?",
    r"create (a |an )?task (to |for |about )?",
    r"add (a |an )?(task |reminder )?(to |for |about )?",
    r"new task[: ]?",
    r"note (to self )?(to )?",
    r"remember (to )?",
    r"task[: ]+",
    r"set (a |an )?reminder (to |for |about )?",
    r"i (need|should|have) to ",
    r"make sure (to )?",
    r"don'?t forget (to )?",
    r"schedule (a |an )?",
    r"please (add |create |remind me to )?",
    r"can you (add |create |remind me to )?",
  ];

  static String _stripPrefixes(String text) {
    var t = text.toLowerCase();
    bool matched = true;
    while (matched) {
      matched = false;
      for (final p in _prefixes) {
        final stripped = t.replaceFirst(RegExp('^$p', caseSensitive: false), '').trim();
        if (stripped.length < t.length) {
          t = stripped;
          matched = true;
          break;
        }
      }
    }
    return t;
  }

  // ── Priority extraction ─────────────────────────────────────────────────────

  static ({String priority, String remaining}) _extractPriority(String text) {
    final patterns = <RegExp, String>{
      RegExp(r'\b(urgent(ly)?|critical|as soon as possible|asap|right away)\b',
          caseSensitive: false): 'URGENT',
      RegExp(
          r'\b(high([-\s])?priority|important|top priority|high importance)\b',
          caseSensitive: false): 'HIGH',
      RegExp(r"\b(low([-\s])?priority|not urgent|whenever|no rush|low importance|when (you'?re|i'?m) free)\b",
          caseSensitive: false): 'LOW',
      RegExp(r'\b(medium([-\s])?priority|normal priority|medium importance)\b',
          caseSensitive: false): 'MEDIUM',
    };

    for (final entry in patterns.entries) {
      if (entry.key.hasMatch(text)) {
        return (
          priority: entry.value,
          remaining: text.replaceAll(entry.key, ' ').trim(),
        );
      }
    }
    return (priority: 'MEDIUM', remaining: text);
  }

  // ── Time extraction ─────────────────────────────────────────────────────────

  static ({TimeOfDay? time, String remaining}) _extractTime(String text) {
    final patterns = <RegExp, TimeOfDay? Function(RegExpMatch m)>{
      // "at 3:30pm", "at 15:45", "at 3:30 pm"
      RegExp(r'\bat\s+(\d{1,2}):(\d{2})\s*(am|pm|a\.m\.|p\.m\.)?',
          caseSensitive: false): (m) {
        var h = int.parse(m.group(1)!);
        final min = int.parse(m.group(2)!);
        final period = m.group(3)?.toLowerCase().replaceAll('.', '');
        if (period == 'pm' && h < 12) h += 12;
        if (period == 'am' && h == 12) h = 0;
        return TimeOfDay(hour: h.clamp(0, 23), minute: min.clamp(0, 59));
      },
      // "at 3pm", "at 3 pm", "at 3 p.m."
      RegExp(r'\bat\s+(\d{1,2})\s*(am|pm|a\.m\.|p\.m\.)',
          caseSensitive: false): (m) {
        var h = int.parse(m.group(1)!);
        final period = m.group(2)!.toLowerCase().replaceAll('.', '');
        if (period == 'pm' && h < 12) h += 12;
        if (period == 'am' && h == 12) h = 0;
        return TimeOfDay(hour: h.clamp(0, 23), minute: 0);
      },
      // "at 15" (24-hour with no am/pm, only if ≥13)
      RegExp(r'\bat\s+(1[3-9]|2[0-3])\b'): (m) =>
          TimeOfDay(hour: int.parse(m.group(1)!), minute: 0),
      // "at noon"
      RegExp(r'\bat noon\b', caseSensitive: false): (_) =>
          const TimeOfDay(hour: 12, minute: 0),
      // "at midnight"
      RegExp(r'\bat midnight\b', caseSensitive: false): (_) =>
          const TimeOfDay(hour: 0, minute: 0),
      // "in the morning"
      RegExp(r'\bin the morning\b', caseSensitive: false): (_) =>
          const TimeOfDay(hour: 9, minute: 0),
      // "this morning"
      RegExp(r'\bthis morning\b', caseSensitive: false): (_) =>
          const TimeOfDay(hour: 9, minute: 0),
      // "in the afternoon"
      RegExp(r'\bin the afternoon\b', caseSensitive: false): (_) =>
          const TimeOfDay(hour: 14, minute: 0),
      // "this afternoon"
      RegExp(r'\bthis afternoon\b', caseSensitive: false): (_) =>
          const TimeOfDay(hour: 14, minute: 0),
      // "in the evening"
      RegExp(r'\bin the evening\b', caseSensitive: false): (_) =>
          const TimeOfDay(hour: 18, minute: 0),
      // "this evening"
      RegExp(r'\bthis evening\b', caseSensitive: false): (_) =>
          const TimeOfDay(hour: 18, minute: 0),
      // "tonight"
      RegExp(r'\btonight\b', caseSensitive: false): (_) =>
          const TimeOfDay(hour: 20, minute: 0),
    };

    for (final entry in patterns.entries) {
      final match = entry.key.firstMatch(text);
      if (match != null) {
        final time = entry.value(match);
        return (
          time: time,
          remaining: text.replaceFirst(entry.key, ' ').trim(),
        );
      }
    }
    return (time: null, remaining: text);
  }

  // ── Date extraction ─────────────────────────────────────────────────────────

  static ({DateTime? date, String remaining}) _extractDate(String text) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final patterns = <RegExp, DateTime? Function(RegExpMatch m)>{
      // "today"
      RegExp(r'\btoday\b', caseSensitive: false): (_) => today,

      // "tomorrow"
      RegExp(r'\btomorrow\b', caseSensitive: false): (_) =>
          today.add(const Duration(days: 1)),

      // "day after tomorrow"
      RegExp(r'\bday after tomorrow\b', caseSensitive: false): (_) =>
          today.add(const Duration(days: 2)),

      // "in X days"
      RegExp(r'\bin (\d+) days?\b', caseSensitive: false): (m) =>
          today.add(Duration(days: int.parse(m.group(1)!))),

      // "next week"
      RegExp(r'\bnext week\b', caseSensitive: false): (_) =>
          today.add(Duration(days: 7 - today.weekday + 1)),

      // "this weekend"
      RegExp(r'\bthis weekend\b', caseSensitive: false): (_) {
        final daysToSat = (6 - today.weekday + 7) % 7;
        return today.add(Duration(days: daysToSat == 0 ? 7 : daysToSat));
      },

      // "end of the week" / "end of week"
      RegExp(r'\bend of (the )?week\b', caseSensitive: false): (_) {
        final daysToFri = (5 - today.weekday + 7) % 7;
        return today.add(Duration(days: daysToFri == 0 ? 7 : daysToFri));
      },

      // "next Monday/Tuesday/..."
      RegExp(
          r'\bnext (monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
          caseSensitive: false): (m) => _nextWeekday(m.group(1)!, today, forceNext: true),

      // "this Monday/Tuesday/..." or "on Monday/Tuesday/..."
      RegExp(
          r'\b(this|on) (monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
          caseSensitive: false): (m) => _nextWeekday(m.group(2)!, today),

      // "Monday" alone (next occurrence)
      RegExp(
          r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
          caseSensitive: false): (m) => _nextWeekday(m.group(1)!, today),

      // "January 15", "Jan 15th", etc.
      RegExp(
          r'\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?\b',
          caseSensitive: false): (m) {
        final month = _parseMonth(m.group(1)!);
        final day = int.parse(m.group(2)!);
        var year = today.year;
        final candidate = DateTime(year, month, day);
        if (candidate.isBefore(today)) year++;
        return DateTime(year, month, day);
      },

      // "the 15th", "the 3rd" (of current/next month)
      RegExp(r'\bthe (\d{1,2})(st|nd|rd|th)\b', caseSensitive: false): (m) {
        final day = int.parse(m.group(1)!);
        var candidate = DateTime(today.year, today.month, day);
        if (candidate.isBefore(today)) {
          candidate = DateTime(today.year, today.month + 1, day);
        }
        return candidate;
      },
    };

    for (final entry in patterns.entries) {
      final match = entry.key.firstMatch(text);
      if (match != null) {
        final date = entry.value(match);
        return (
          date: date,
          remaining: text.replaceFirst(entry.key, ' ').trim(),
        );
      }
    }
    return (date: null, remaining: text);
  }

  // ── Title cleanup ───────────────────────────────────────────────────────────

  static String _cleanTitle(String text) {
    var t = text;
    // Remove trailing/leading connectors
    t = t.replaceAll(RegExp(r'\b(by|at|on|in|the|this|that|and|or|for|a|an)\s*$',
        caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'^\s*(by|at|on|in|the|this|and|or)\b',
        caseSensitive: false), '');
    // Collapse multiple spaces and clean punctuation
    t = t.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    t = t.replaceAll(RegExp(r'^[,.\-:;]+'), '').trim();
    t = t.replaceAll(RegExp(r'[,.\-:;]+$'), '').trim();
    return _sentenceCase(t);
  }

  // ── Pure helpers ────────────────────────────────────────────────────────────

  static DateTime _nextWeekday(String name, DateTime today,
      {bool forceNext = false}) {
    const map = {
      'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
      'friday': 5, 'saturday': 6, 'sunday': 7,
    };
    final target = map[name.toLowerCase()] ?? 1;
    var days = target - today.weekday;
    if (days <= 0 || forceNext) days += 7;
    return today.add(Duration(days: days));
  }

  static int _parseMonth(String s) {
    const map = {
      'january': 1, 'jan': 1,
      'february': 2, 'feb': 2,
      'march': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'may': 5,
      'june': 6, 'jun': 6,
      'july': 7, 'jul': 7,
      'august': 8, 'aug': 8,
      'september': 9, 'sep': 9,
      'october': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'december': 12, 'dec': 12,
    };
    return map[s.toLowerCase()] ?? 1;
  }

  static String _sentenceCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
