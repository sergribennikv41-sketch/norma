import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/in_memory_recipe_repository.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/user_profile.dart';
import 'package:norma/core/nutrition/targets_calculator.dart';
import 'package:norma/core/planner/menu_generator.dart';

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

  test('неделя содержит 7 дней и все приёмы пищи', () {
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );

    expect(plan.days, hasLength(7));
    for (final day in plan.days) {
      expect(day.meals, hasLength(4));
      expect(day.meals.map((meal) => meal.type), [
        MealType.breakfast,
        MealType.lunch,
        MealType.dinner,
        MealType.snack,
      ]);
      expect(day.totals.calories, greaterThan(0));
      for (final meal in day.meals) {
        expect(meal.scale, inInclusiveRange(0.5, 1.5));
      }
    }
  });

  test('исключает аллергены из меню', () {
    const noLactose = UserProfile(
      sex: Sex.female,
      age: 28,
      heightCm: 168,
      weightKg: 62,
      activity: ActivityLevel.light,
      goal: Goal.maintain,
      pace: Pace.medium,
      mealsPerDay: 4,
      excludedAllergens: {Allergen.lactose},
    );
    final noLactoseTargets = const TargetsCalculator().calculate(noLactose);
    final plan = const MenuGenerator().generate(
      profile: noLactose,
      targets: noLactoseTargets,
      repository: repository,
    );

    for (final day in plan.days) {
      for (final meal in day.meals) {
        expect(
          repository.allergensForRecipe(meal.recipe),
          isNot(contains(Allergen.lactose)),
        );
      }
    }
  });

  test('у ингредиентов есть цены, у блюд — стоимость', () {
    for (final ingredient in repository.ingredients) {
      expect(
        repository.pricePerKg(ingredient.id),
        greaterThan(0),
        reason: 'Нет цены для ${ingredient.id}',
      );
    }
    for (final recipe in repository.recipes) {
      expect(
        repository.costForRecipe(recipe),
        greaterThan(0),
        reason: 'Нулевая стоимость у ${recipe.id}',
      );
    }
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );
    expect(plan.totalCost, greaterThan(0));
    expect(plan.days.every((day) => day.totalCost > 0), isTrue);
  });

  test('фильтрует блюда по времени готовки', () {
    const quick = UserProfile(
      sex: Sex.male,
      age: 30,
      heightCm: 180,
      weightKg: 80,
      activity: ActivityLevel.moderate,
      goal: Goal.lose,
      pace: Pace.medium,
      mealsPerDay: 4,
      maxCookMinutes: 15,
    );
    final quickTargets = const TargetsCalculator().calculate(quick);
    final plan = const MenuGenerator().generate(
      profile: quick,
      targets: quickTargets,
      repository: repository,
    );

    for (final day in plan.days) {
      for (final meal in day.meals) {
        expect(meal.recipe.minutes, lessThanOrEqualTo(15));
      }
    }
  });

  test('исключает заблокированные блюда', () {
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );
    final blockedRecipeId = plan.days.first.meals.first.recipe.id;
    final blockedProfile = profile.copyWith(
      blockedRecipeIds: {blockedRecipeId},
    );
    final blockedTargets = const TargetsCalculator().calculate(blockedProfile);
    final blockedPlan = const MenuGenerator().generate(
      profile: blockedProfile,
      targets: blockedTargets,
      repository: repository,
    );

    for (final day in blockedPlan.days) {
      for (final meal in day.meals) {
        expect(meal.recipe.id, isNot(blockedRecipeId));
      }
    }
  });

  test('дневной бюджет ограничивает стоимость меню', () {
    final budgetProfile = profile.copyWith(dailyBudgetRub: 600);
    final budgetTargets = const TargetsCalculator().calculate(budgetProfile);
    final plan = const MenuGenerator().generate(
      profile: budgetProfile,
      targets: budgetTargets,
      repository: repository,
    );

    for (final day in plan.days) {
      expect(day.totalCost, lessThanOrEqualTo(600));
    }
  });

  test('замена блюда меняет только выбранный приём пищи', () {
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );
    final updated = const MenuGenerator().replaceMeal(
      plan: plan,
      profile: profile,
      repository: repository,
      dayIndex: 0,
      mealIndex: 0,
      seed: 7,
    );

    expect(
      updated.days.first.meals.first.recipe.id,
      isNot(plan.days.first.meals.first.recipe.id),
    );
    for (var dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      for (
        var mealIndex = 0;
        mealIndex < plan.days[dayIndex].meals.length;
        mealIndex++
      ) {
        if (dayIndex == 0 && mealIndex == 0) {
          continue;
        }
        expect(
          updated.days[dayIndex].meals[mealIndex].recipe.id,
          plan.days[dayIndex].meals[mealIndex].recipe.id,
        );
      }
    }
    expect(updated.shoppingList, isNotEmpty);
  });

  test('альтернативы соответствуют слоту и ограничениям', () {
    const noLactose = UserProfile(
      sex: Sex.female,
      age: 28,
      heightCm: 168,
      weightKg: 62,
      activity: ActivityLevel.light,
      goal: Goal.maintain,
      pace: Pace.medium,
      mealsPerDay: 4,
      excludedAllergens: {Allergen.lactose},
    );
    final noLactoseTargets = const TargetsCalculator().calculate(noLactose);
    final plan = const MenuGenerator().generate(
      profile: noLactose,
      targets: noLactoseTargets,
      repository: repository,
    );
    final alternatives = const MenuGenerator().alternativesForMeal(
      plan: plan,
      profile: noLactose,
      repository: repository,
      dayIndex: 0,
      mealIndex: 1,
    );
    final current = plan.days.first.meals[1];

    expect(alternatives, isNotEmpty);
    for (final alternative in alternatives) {
      expect(alternative.recipe.mealTypes, contains(MealType.lunch));
      expect(alternative.recipe.id, isNot(current.recipe.id));
      expect(
        repository.allergensForRecipe(alternative.recipe),
        isNot(contains(Allergen.lactose)),
      );
      expect(alternative.scale, inInclusiveRange(0.5, 1.5));
      expect(alternative.nutrients.calories, greaterThan(0));
      expect(alternative.cost, greaterThan(0));
    }
  });

  test('выбранная альтернатива применяется к рациону', () {
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );
    final alternatives = const MenuGenerator().alternativesForMeal(
      plan: plan,
      profile: profile,
      repository: repository,
      dayIndex: 0,
      mealIndex: 0,
    );
    expect(alternatives, isNotEmpty);

    final chosen = alternatives.first;
    final updated = const MenuGenerator().applyMealAlternative(
      plan: plan,
      dayIndex: 0,
      mealIndex: 0,
      alternative: chosen,
      repository: repository,
    );

    expect(updated.days.first.meals.first.recipe.id, chosen.recipe.id);
    expect(updated.days.first.meals.first.scale, closeTo(chosen.scale, 0.0001));
    expect(
      updated.days.first.meals.first.nutrients.calories,
      closeTo(chosen.nutrients.calories, 0.001),
    );
    for (
      var mealIndex = 1;
      mealIndex < plan.days.first.meals.length;
      mealIndex++
    ) {
      expect(
        updated.days.first.meals[mealIndex].recipe.id,
        plan.days.first.meals[mealIndex].recipe.id,
      );
    }
    expect(updated.shoppingList, isNotEmpty);
  });

  test('изменение порции пересчитывает блюдо и покупки', () {
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );
    final original = plan.days.first.meals.first;
    final updated = const MenuGenerator().rescaleMeal(
      plan: plan,
      dayIndex: 0,
      mealIndex: 0,
      scale: 1.25,
      repository: repository,
    );
    final meal = updated.days.first.meals.first;

    expect(meal.recipe.id, original.recipe.id);
    expect(meal.scale, closeTo(1.25, 0.0001));
    expect(
      meal.nutrients.calories,
      closeTo(original.nutrients.calories / original.scale * 1.25, 0.001),
    );
    expect(meal.cost, closeTo(original.cost / original.scale * 1.25, 0.001));
    expect(
      updated.days.first.meals[1].recipe.id,
      plan.days.first.meals[1].recipe.id,
    );
    expect(updated.shoppingList, isNotEmpty);
  });

  test('список покупок агрегирует ингредиенты без дублей', () {
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );
    final ids = plan.shoppingList.map((item) => item.ingredient.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
    expect(plan.shoppingList, isNotEmpty);
    expect(plan.shoppingList.every((item) => item.grams > 0), isTrue);
    expect(plan.shoppingList.every((item) => item.grams % 10 == 0), isTrue);
  });

  test('в сид-базе достаточно рецептов на каждый приём пищи', () {
    for (final mealType in MealType.values) {
      final count = repository.recipes
          .where((recipe) => recipe.mealTypes.contains(mealType))
          .length;
      expect(count, greaterThanOrEqualTo(2));
    }
  });
}
