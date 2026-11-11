import '../models/enums.dart';
import '../models/ingredient.dart';
import '../models/nutrients.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';

abstract class RecipeRepository {
  List<Ingredient> get ingredients;

  List<Recipe> get recipes;

  Ingredient? ingredientById(String id);

  Nutrients nutrientsForRecipe(Recipe recipe);

  Nutrients nutrientsPerServing(Recipe recipe);

  Set<Allergen> allergensForRecipe(Recipe recipe);

  double pricePerKg(String ingredientId);

  double costForRecipe(Recipe recipe);

  double costPerServing(Recipe recipe);

  bool canUseRecipe(Recipe recipe, UserProfile profile);
}
