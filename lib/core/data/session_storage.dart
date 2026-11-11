import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan_snapshot.dart';
import '../models/user_profile.dart';

class SavedSession {
  const SavedSession({required this.profile, required this.seed, this.plan});

  final UserProfile profile;
  final int seed;
  final SavedPlan? plan;
}

class SessionStorage {
  static const _profileKey = 'norma.profile';
  static const _seedKey = 'norma.seed';
  static const _planKey = 'norma.plan';

  Future<SavedSession?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_profileKey);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return SavedSession(
        profile: UserProfile.fromJson(Map<String, dynamic>.from(decoded)),
        seed: preferences.getInt(_seedKey) ?? 1,
        plan: _loadPlan(preferences.getString(_planKey)),
      );
    } catch (_) {
      return null;
    }
  }

  SavedPlan? _loadPlan(String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return SavedPlan.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(UserProfile profile, int seed, {SavedPlan? plan}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profileKey, jsonEncode(profile.toJson()));
    await preferences.setInt(_seedKey, seed);
    if (plan == null) {
      await preferences.remove(_planKey);
    } else {
      await preferences.setString(_planKey, jsonEncode(plan.toJson()));
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_profileKey);
    await preferences.remove(_seedKey);
    await preferences.remove(_planKey);
  }
}
