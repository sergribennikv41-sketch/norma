import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/app_database.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/recipe.dart';
import 'package:norma/core/models/seed_bundle.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/seed_fixture.dart';

void main() {
  late SeedBundle seed;
  setUpAll(() {
    sqfliteFfiInit();
    seed = loadSeedBundleFromFile();
  });

  test('импортирует и загружает seed из SQLite', () async {
    final database = await AppDatabase.open(path: inMemoryDatabasePath);
    await database.seedIfNeeded(seed);
    final repository = await database.loadRepository();

    expect(repository.ingredients, hasLength(seed.ingredients.length));
    expect(repository.recipes, hasLength(seed.recipes.length));
    expect(
      repository.pricePerKg('chicken_breast'),
      seed.prices['chicken_breast'],
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
    await database.seedIfNeeded(seed);
    await database.seedIfNeeded(seed);
    final repository = await database.loadRepository();

    expect(repository.ingredients, hasLength(seed.ingredients.length));
    expect(repository.recipes, hasLength(seed.recipes.length));

    await database.close();
  });

  test('обновляет данные при росте версии seed', () async {
    final database = await AppDatabase.open(path: inMemoryDatabasePath);
    await database.seedIfNeeded(seed);

    final extra = Recipe(
      id: 'test_extra',
      title: 'Тестовый перекус',
      mealTypes: {MealType.snack},
      servings: 1,
      minutes: 3,
      ingredients: [RecipeIngredient(ingredientId: 'apple', grams: 100)],
      steps: ['Нарежьте яблоко.'],
    );
    final bumped = SeedBundle(
      version: seed.version + 1,
      ingredients: seed.ingredients,
      recipes: [...seed.recipes, extra],
      prices: seed.prices,
    );
    await database.seedIfNeeded(bumped);
    final repository = await database.loadRepository();

    expect(repository.recipes, hasLength(seed.recipes.length + 1));
    expect(repository.recipeById('test_extra'), isNotNull);

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
      Map<String, dynamic>.from(seed.toJson()),
    );

    expect(restored.ingredients, hasLength(seed.ingredients.length));
    expect(restored.recipes, hasLength(seed.recipes.length));
    expect(restored.prices.length, seed.prices.length);

    final ingredient = restored.ingredients.firstWhere(
      (item) => item.id == 'egg',
    );
    expect(ingredient.allergens, {Allergen.eggs});
    expect(restored.prices['egg'], seed.prices['egg']);
  });
}
