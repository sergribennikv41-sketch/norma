import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan_snapshot.dart';

class WeekStorage {
  static const _weeksKey = 'norma.weeks';
  static const _maxWeeks = 52;

  Future<Map<String, SavedWeek>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_weeksKey);
    if (raw == null) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {};
      }
      final weeks = <String, SavedWeek>{};
      for (final entry in decoded.entries) {
        if (entry.value is! Map) {
          continue;
        }
        final week = SavedWeek.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (week.weekStart.year != 1970) {
          weeks[week.key] = week;
        }
      }
      return weeks;
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<String, SavedWeek> weeks) async {
    final preferences = await SharedPreferences.getInstance();
    final keys = weeks.keys.toList()..sort();
    while (keys.length > _maxWeeks) {
      keys.removeAt(0);
    }
    final payload = <String, Object?>{};
    for (final key in keys) {
      payload[key] = weeks[key]!.toJson();
    }
    await preferences.setString(_weeksKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_weeksKey);
  }
}
