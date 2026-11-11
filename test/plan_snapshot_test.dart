import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/in_memory_recipe_repository.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/plan_snapshot.dart';
import 'package:norma/core/models/user_profile.dart';
import 'package:norma/core/nutrition/targets_calculator.dart';
import 'package:norma/core/planner/menu_generator.dart';
import 'package:norma/core/planner/plan_restorer.dart';

import 'support/seed_fixture.dart';

void main() {
  late InMemoryRecipeRepository repository;
  setUpAll(() {
    repository = loadSeedRepository();
  });
  const profile = UserProfile(
    sex: Sex.male,
    age: 30,
    heightCm: 180,
    weightKg: 80,
    activity: ActivityLevel.moderate,
    goal: Goal.lose,
    pace: Pace.medium,
    mealsPerDay: 4,
  );
  final targets = const TargetsCalculator().calculate(profile);

  test('снимок плана восстанавливает блюда и порции', () {
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );
    final snapshot = SavedPlan.fromWeeklyPlan(plan);
    final decoded = jsonDecode(jsonEncode(snapshot.toJson()));
    final restored = restorePlan(
      snapshot: SavedPlan.fromJson(Map<String, dynamic>.from(decoded as Map)),
      repository: repository,
      targets: targets,
    );

    expect(restored, isNotNull);
    final restoredPlan = restored!;
    expect(restoredPlan.days, hasLength(plan.days.length));
    for (var dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      final expectedMeals = plan.days[dayIndex].meals;
      final actualMeals = restoredPlan.days[dayIndex].meals;
      expect(actualMeals, hasLength(expectedMeals.length));
      for (var mealIndex = 0; mealIndex < expectedMeals.length; mealIndex++) {
        final expected = expectedMeals[mealIndex];
        final actual = actualMeals[mealIndex];
        expect(actual.recipe.id, expected.recipe.id);
        expect(actual.scale, closeTo(expected.scale, 0.0001));
        expect(
          actual.nutrients.calories,
          closeTo(expected.nutrients.calories, 0.001),
        );
        expect(actual.cost, closeTo(expected.cost, 0.001));
      }
    }
    expect(restoredPlan.shoppingList, isNotEmpty);
  });

  test('снимок с неизвестным рецептом не восстанавливается', () {
    final restored = restorePlan(
      snapshot: const SavedPlan(
        meals: [
          SavedMeal(
            dayIndex: 0,
            mealIndex: 0,
            type: MealType.lunch,
            recipeId: 'missing_recipe',
            scale: 1,
          ),
        ],
      ),
      repository: repository,
      targets: targets,
    );

    expect(restored, isNull);
  });
}
