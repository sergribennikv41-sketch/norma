import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/in_memory_recipe_repository.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/plan_snapshot.dart';
import 'package:norma/core/models/user_profile.dart';
import 'package:norma/core/nutrition/targets_calculator.dart';
import 'package:norma/core/planner/menu_generator.dart';
import 'package:norma/features/home/home_page.dart';

import 'support/seed_fixture.dart';

void main() {
  late InMemoryRecipeRepository repository;
  setUpAll(() {
    repository = loadSeedRepository();
  });

  testWidgets('mobile layout without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const profile = UserProfile(
      sex: Sex.male,
      age: 30,
      heightCm: 180,
      weightKg: 80,
      activity: ActivityLevel.moderate,
      goal: Goal.lose,
      pace: Pace.medium,
      mealsPerDay: 4,
      cityId: 'rostov_on_don',
      storeId: 'magnit',
    );
    final targets = const TargetsCalculator().calculate(profile);
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          profile: profile,
          repository: repository,
          initialPlan: SavedPlan.fromWeeklyPlan(plan),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Каталог').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Покупки').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
