import 'package:flutter/material.dart';

import '../data/theme_storage.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({
    required this.storage,
    ThemeMode initialMode = ThemeMode.light,
  }) : _mode = initialMode;

  final ThemeStorage storage;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> toggle() {
    return setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
    try {
      await storage.save(mode);
    } catch (_) {
      return;
    }
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'ThemeControllerScope не найден');
    return scope!;
  }

  static ThemeController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>()
        ?.notifier;
  }
}
