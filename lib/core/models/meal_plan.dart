import 'daily_targets.dart';
import 'enums.dart';
import 'ingredient.dart';
import 'nutrients.dart';
import 'recipe.dart';

class PlannedMeal {
  const PlannedMeal({
    required this.type,
    required this.recipe,
    required this.scale,
    required this.nutrients,
    required this.ingredientGrams,
    required this.cost,
  });

  final MealType type;
  final Recipe recipe;
  final double scale;
  final Nutrients nutrients;
  final Map<String, double> ingredientGrams;
  final double cost;
}

class DayPlan {
  const DayPlan({required this.index, required this.meals});

  final int index;
  final List<PlannedMeal> meals;

  Nutrients get totals {
    return meals.fold<Nutrients>(
      Nutrients.zero,
      (sum, meal) => sum + meal.nutrients,
    );
  }

  double get totalCost {
    return meals.fold<double>(0, (sum, meal) => sum + meal.cost);
  }
}

class ShoppingItem {
  const ShoppingItem({required this.ingredient, required this.grams});

  final Ingredient ingredient;
  final double grams;
}

class WeeklyPlan {
  const WeeklyPlan({
    required this.days,
    required this.targets,
    required this.shoppingList,
  });

  final List<DayPlan> days;
  final DailyTargets targets;
  final List<ShoppingItem> shoppingList;

  double get totalCost {
    return days.fold<double>(0, (sum, day) => sum + day.totalCost);
  }
}
