import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norma/app.dart';
import 'package:norma/core/data/theme_storage.dart';
import 'package:norma/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/seed_fixture.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('тема сохраняется и загружается', () async {
    final storage = ThemeStorage();
    final controller = ThemeController(storage: storage);
    addTearDown(controller.dispose);

    expect(await storage.load(), ThemeMode.light);
    await controller.setMode(ThemeMode.dark);
    expect(controller.isDark, isTrue);
    expect(await storage.load(), ThemeMode.dark);

    await controller.toggle();
    expect(controller.mode, ThemeMode.light);
    expect(await storage.load(), ThemeMode.light);
  });

  testWidgets('кнопка переключает тему приложения', (tester) async {
    final repository = loadSeedRepository();
    await tester.pumpWidget(NormaApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Тёмная тема'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Рацион под вас'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byTooltip('Тёмная тема'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Светлая тема'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Рацион под вас'))).brightness,
      Brightness.dark,
    );
  });
}
