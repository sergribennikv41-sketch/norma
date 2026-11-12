import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/in_memory_recipe_repository.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/plan_snapshot.dart';
import 'package:norma/core/models/user_profile.dart';
import 'package:norma/core/nutrition/targets_calculator.dart';
import 'package:norma/core/planner/menu_generator.dart';
import 'package:norma/core/planner/week_calendar.dart';
import 'package:norma/features/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/seed_fixture.dart';

void main() {
  late InMemoryRecipeRepository repository;
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

  setUpAll(() {
    repository = loadSeedRepository();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('переключает недели и возвращается к текущей', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(profile: profile, repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final currentStart = startOfWeek(DateTime.now());
    final nextStart = addDays(currentStart, 7);
    expect(find.text('Текущая неделя'), findsOneWidget);
    expect(find.text(formatWeekRange(currentStart)), findsOneWidget);

    await tester.tap(find.byTooltip('Следующая неделя'));
    await tester.pumpAndSettle();
    expect(find.text('Неделя'), findsOneWidget);
    expect(find.text(formatWeekRange(nextStart)), findsOneWidget);

    await tester.tap(find.byTooltip('Текущая неделя'));
    await tester.pumpAndSettle();
    expect(find.text('Текущая неделя'), findsOneWidget);
    expect(find.text(formatWeekRange(currentStart)), findsOneWidget);
  });

  testWidgets('новая неделя не подменяется старым сохранённым планом', (
    tester,
  ) async {
    final previousStart = addDays(startOfWeek(DateTime.now()), -7);
    final oldPlan = SavedPlan(
      meals: [
        SavedMeal(
          dayIndex: 0,
          mealIndex: 0,
          type: MealType.breakfast,
          recipeId: repository.recipes.first.id,
          scale: 1,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          profile: profile,
          repository: repository,
          initialPlan: oldPlan,
          initialWeeks: {
            dateKey(previousStart): SavedWeek(
              weekStart: previousStart,
              seed: 1,
              plan: oldPlan,
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Текущая неделя'), findsOneWidget);
    expect(find.text('Вс'), findsOneWidget);
  });

  test('каждое блюдо соответствует своему приёму пищи', () {
    final targets = const TargetsCalculator().calculate(profile);
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );
    for (final day in plan.days) {
      for (final meal in day.meals) {
        expect(
          meal.recipe.mealTypes,
          contains(meal.type),
          reason: '${meal.recipe.title} не подходит для ${meal.type.label}',
        );
      }
    }
  });
}
