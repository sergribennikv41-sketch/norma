import 'ingredient.dart';
import 'recipe.dart';

class SeedBundle {
  const SeedBundle({
    required this.ingredients,
    required this.recipes,
    required this.prices,
    this.version = 1,
  });

  final List<Ingredient> ingredients;
  final List<Recipe> recipes;
  final Map<String, double> prices;
  final int version;

  factory SeedBundle.fromJson(Map<String, dynamic> json) {
    final ingredients = <Ingredient>[];
    final prices = <String, double>{};
    final rawIngredients = json['ingredients'];
    if (rawIngredients is List) {
      for (final item in rawIngredients) {
        if (item is! Map) {
          continue;
        }
        final map = Map<String, dynamic>.from(item);
        final ingredient = Ingredient.fromJson(map);
        ingredients.add(ingredient);
        final price = map['pricePerKg'];
        if (price is num) {
          prices[ingredient.id] = price.toDouble();
        }
      }
    }

    final recipes = <Recipe>[];
    final rawRecipes = json['recipes'];
    if (rawRecipes is List) {
      for (final item in rawRecipes) {
        if (item is Map) {
          recipes.add(Recipe.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return SeedBundle(
      ingredients: ingredients,
      recipes: recipes,
      prices: prices,
      version: json['version'] is num ? (json['version'] as num).toInt() : 1,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'version': version,
      'ingredients': [
        for (final ingredient in ingredients)
          {...ingredient.toJson(), 'pricePerKg': prices[ingredient.id]},
      ],
      'recipes': [for (final recipe in recipes) recipe.toJson()],
    };
  }
}
