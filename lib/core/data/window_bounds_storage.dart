import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

class WindowBoundsStorage {
  static const _key = 'norma.window_bounds';

  Future<Rect?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) {
      return null;
    }
    final parts = raw.split(',');
    if (parts.length != 4) {
      return null;
    }
    final values = [for (final part in parts) double.tryParse(part)];
    if (values.any((value) => value == null)) {
      return null;
    }
    return Rect.fromLTWH(values[0]!, values[1]!, values[2]!, values[3]!);
  }

  Future<void> save(Rect bounds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      '${bounds.left},${bounds.top},${bounds.width},${bounds.height}',
    );
  }
}
