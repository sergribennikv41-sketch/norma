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

  testWidgets('home profile screen builds', (tester) async {
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
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
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
    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    expect(find.text('Основные параметры'), findsOneWidget);
  });
}
