import 'enums.dart';

class RecipeIngredient {
  const RecipeIngredient({required this.ingredientId, required this.grams});

  final String ingredientId;
  final double grams;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.mealTypes,
    required this.servings,
    required this.minutes,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String title;
  final Set<MealType> mealTypes;
  final int servings;
  final int minutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
}
