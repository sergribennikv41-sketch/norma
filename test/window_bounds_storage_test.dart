import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/window_bounds_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('сохраняет и восстанавливает размеры окна', () async {
    final storage = WindowBoundsStorage();
    await storage.save(const Rect.fromLTWH(120, 80, 1280, 860));
    final bounds = await storage.load();

    expect(bounds, isNotNull);
    expect(bounds!.left, 120);
    expect(bounds.top, 80);
    expect(bounds.width, 1280);
    expect(bounds.height, 860);
  });

  test('битые данные возвращают null', () async {
    SharedPreferences.setMockInitialValues({'norma.window_bounds': 'broken'});
    expect(await WindowBoundsStorage().load(), isNull);
  });
}
