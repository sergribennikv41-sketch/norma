import '../models/enums.dart';
import '../models/ingredient.dart';
import '../models/nutrients.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import 'recipe_repository.dart';
import 'seed_data.dart';

class InMemoryRecipeRepository implements RecipeRepository {
  InMemoryRecipeRepository({
    required List<Ingredient> ingredients,
    required List<Recipe> recipes,
    Map<String, double> prices = seedPrices,
  }) : _ingredients = List.unmodifiable(ingredients),
       _recipes = List.unmodifiable(recipes),
       _prices = Map.unmodifiable(prices),
       _byId = {
         for (final ingredient in ingredients) ingredient.id: ingredient,
       };

  factory InMemoryRecipeRepository.seeded() {
    return InMemoryRecipeRepository(
      ingredients: seedIngredients,
      recipes: seedRecipes,
    );
  }

  final List<Ingredient> _ingredients;
  final List<Recipe> _recipes;
  final Map<String, double> _prices;
  final Map<String, Ingredient> _byId;

  @override
  List<Ingredient> get ingredients => _ingredients;

  @override
  List<Recipe> get recipes => _recipes;

  @override
  Ingredient? ingredientById(String id) => _byId[id];

  @override
  Nutrients nutrientsForRecipe(Recipe recipe) {
    var total = Nutrients.zero;
    for (final item in recipe.ingredients) {
      final ingredient = _byId[item.ingredientId];
      if (ingredient == null) {
        throw StateError('Неизвестный ингредиент: ${item.ingredientId}');
      }
      total += ingredient.nutrientsFor(item.grams);
    }
    return total;
  }

  @override
  Nutrients nutrientsPerServing(Recipe recipe) {
    return nutrientsForRecipe(recipe) * (1 / recipe.servings);
  }

  @override
  Set<Allergen> allergensForRecipe(Recipe recipe) {
    final result = <Allergen>{};
    for (final item in recipe.ingredients) {
      final ingredient = _byId[item.ingredientId];
      if (ingredient != null) {
        result.addAll(ingredient.allergens);
      }
    }
    return result;
  }

  @override
  double pricePerKg(String ingredientId) => _prices[ingredientId] ?? 0;

  @override
  double costForRecipe(Recipe recipe) {
    var total = 0.0;
    for (final item in recipe.ingredients) {
      total += item.grams / 1000 * pricePerKg(item.ingredientId);
    }
    return total;
  }

  @override
  double costPerServing(Recipe recipe) {
    return costForRecipe(recipe) / recipe.servings;
  }

  @override
  bool canUseRecipe(Recipe recipe, UserProfile profile) {
    if (profile.blockedRecipeIds.contains(recipe.id)) {
      return false;
    }
    final allergens = allergensForRecipe(recipe);
    if (allergens.any(profile.excludedAllergens.contains)) {
      return false;
    }
    return !recipe.ingredients.any(
      (item) => profile.dislikedIngredientIds.contains(item.ingredientId),
    );
  }
}
