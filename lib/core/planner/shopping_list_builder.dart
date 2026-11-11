import '../data/recipe_repository.dart';
import '../models/meal_plan.dart';

List<ShoppingItem> buildShoppingList(
  List<DayPlan> days,
  RecipeRepository repository,
) {
  final gramsById = <String, double>{};
  for (final day in days) {
    for (final meal in day.meals) {
      meal.ingredientGrams.forEach((id, grams) {
        gramsById[id] = (gramsById[id] ?? 0) + grams;
      });
    }
  }

  final items = <ShoppingItem>[];
  gramsById.forEach((id, grams) {
    final ingredient = repository.ingredientById(id);
    if (ingredient == null || grams <= 0) {
      return;
    }
    final roundedGrams = (grams / 10).ceil() * 10.0;
    items.add(ShoppingItem(ingredient: ingredient, grams: roundedGrams));
  });

  items.sort((a, b) {
    final byCategory = a.ingredient.category.compareTo(b.ingredient.category);
    if (byCategory != 0) {
      return byCategory;
    }
    return a.ingredient.name.compareTo(b.ingredient.name);
  });

  return items;
}
