import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/app_database.dart';
import 'package:norma/core/data/seed_data.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/seed_bundle.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('импортирует и загружает seed из SQLite', () async {
    final database = await AppDatabase.open(path: inMemoryDatabasePath);
    await database.seedIfEmpty(seedBundle);
    final repository = await database.loadRepository();

    expect(repository.ingredients, hasLength(seedIngredients.length));
    expect(repository.recipes, hasLength(seedRecipes.length));
    expect(
      repository.pricePerKg('chicken_breast'),
      seedPrices['chicken_breast'],
    );

    final recipe = repository.recipes.firstWhere(
      (item) => item.id == 'oatmeal_banana_almonds',
    );
    expect(repository.nutrientsForRecipe(recipe).calories, greaterThan(0));
    expect(repository.allergensForRecipe(recipe), {
      Allergen.lactose,
      Allergen.nuts,
    });
    expect(recipe.steps, isNotEmpty);

    await database.close();
  });

  test('повторный импорт не дублирует данные', () async {
    final database = await AppDatabase.open(path: inMemoryDatabasePath);
    await database.seedIfEmpty(seedBundle);
    await database.seedIfEmpty(seedBundle);
    final repository = await database.loadRepository();

    expect(repository.ingredients, hasLength(seedIngredients.length));
    expect(repository.recipes, hasLength(seedRecipes.length));

    await database.close();
  });

  test('JSON-импорт парсит ингредиенты, рецепты и цены', () {
    final bundle = SeedBundle.fromJson({
      'version': 1,
      'ingredients': [
        {
          'id': 'test_ingredient',
          'name': 'Тестовый продукт',
          'category': 'Тест',
          'per100g': {'calories': 100, 'protein': 10, 'fat': 5, 'carbs': 3},
          'allergens': ['nuts'],
          'pricePerKg': 250,
        },
      ],
      'recipes': [
        {
          'id': 'test_recipe',
          'title': 'Тестовое блюдо',
          'mealTypes': ['lunch'],
          'servings': 1,
          'minutes': 10,
          'ingredients': [
            {'ingredientId': 'test_ingredient', 'grams': 100},
          ],
          'steps': ['Смешайте.'],
        },
      ],
    });

    expect(bundle.ingredients, hasLength(1));
    expect(bundle.ingredients.single.allergens, {Allergen.nuts});
    expect(bundle.prices['test_ingredient'], 250);
    expect(bundle.recipes.single.mealTypes, {MealType.lunch});
    expect(bundle.recipes.single.ingredients.single.grams, 100);
  });

  test('JSON round-trip сохраняет данные', () {
    final restored = SeedBundle.fromJson(
      Map<String, dynamic>.from(seedBundle.toJson()),
    );

    expect(restored.ingredients, hasLength(seedIngredients.length));
    expect(restored.recipes, hasLength(seedRecipes.length));
    expect(restored.prices.length, seedPrices.length);

    final ingredient = restored.ingredients.firstWhere(
      (item) => item.id == 'egg',
    );
    expect(ingredient.allergens, {Allergen.eggs});
    expect(restored.prices['egg'], seedPrices['egg']);
  });
}
