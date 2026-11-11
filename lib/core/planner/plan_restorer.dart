import '../data/recipe_repository.dart';
import '../models/daily_targets.dart';
import '../models/meal_plan.dart';
import '../models/plan_snapshot.dart';
import '../models/recipe.dart';
import 'shopping_list_builder.dart';

WeeklyPlan? restorePlan({
  required SavedPlan snapshot,
  required RecipeRepository repository,
  required DailyTargets targets,
}) {
  if (snapshot.meals.isEmpty) {
    return null;
  }

  final byDay = <int, List<(int, PlannedMeal)>>{};

  for (final item in snapshot.meals) {
    if (item.dayIndex < 0 || item.mealIndex < 0 || item.scale <= 0) {
      return null;
    }
    final recipe = _recipeById(repository, item.recipeId);
    if (recipe == null) {
      return null;
    }
    final perServing = repository.nutrientsPerServing(recipe);
    final meal = PlannedMeal(
      type: item.type,
      recipe: recipe,
      scale: item.scale,
      nutrients: perServing * item.scale,
      ingredientGrams: {
        for (final ingredient in recipe.ingredients)
          ingredient.ingredientId: ingredient.grams * item.scale,
      },
      cost: repository.costPerServing(recipe) * item.scale,
    );
    byDay.putIfAbsent(item.dayIndex, () => []).add((item.mealIndex, meal));
  }

  final dayIndexes = byDay.keys.toList()..sort();
  final days = <DayPlan>[];
  for (final dayIndex in dayIndexes) {
    final entries = byDay[dayIndex]!;
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    days.add(
      DayPlan(
        index: dayIndex + 1,
        meals: [for (final entry in entries) entry.$2],
      ),
    );
  }

  return WeeklyPlan(
    days: days,
    targets: targets,
    shoppingList: buildShoppingList(days, repository),
  );
}

Recipe? _recipeById(RecipeRepository repository, String id) {
  for (final recipe in repository.recipes) {
    if (recipe.id == id) {
      return recipe;
    }
  }
  return null;
}
