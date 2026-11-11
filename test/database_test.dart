import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/app_database.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/ingredient.dart';
import 'package:norma/core/models/nutrients.dart';
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

  test('обновление seed не удаляет пользовательский импорт', () async {
    final database = await AppDatabase.open(path: inMemoryDatabasePath);
    await database.seedIfNeeded(seed);

    final userRecipe = Recipe(
      id: 'user_recipe',
      title: 'Пользовательский рецепт',
      mealTypes: {MealType.snack},
      servings: 1,
      minutes: 3,
      ingredients: const [RecipeIngredient(ingredientId: 'apple', grams: 100)],
      steps: const ['Съешьте яблоко.'],
    );
    await database.merge(
      SeedBundle(
        version: 1,
        ingredients: const [],
        recipes: [userRecipe],
        prices: const {},
      ),
    );

    final bumped = SeedBundle(
      version: seed.version + 1,
      ingredients: seed.ingredients,
      recipes: seed.recipes,
      prices: seed.prices,
    );
    await database.seedIfNeeded(bumped);
    final repository = await database.loadRepository();

    expect(repository.recipeById('user_recipe'), isNotNull);
    expect(repository.recipes, hasLength(seed.recipes.length + 1));

    await database.close();
  });

  test('merge добавляет новые ингредиенты и рецепты', () async {
    final database = await AppDatabase.open(path: inMemoryDatabasePath);
    await database.seedIfNeeded(seed);

    const ingredient = Ingredient(
      id: 'test_import_ingredient',
      name: 'Импорт-продукт',
      category: 'Тест',
      per100g: Nutrients(calories: 50, protein: 5, fat: 2, carbs: 3),
      allergens: {Allergen.nuts},
    );
    final recipe = Recipe(
      id: 'test_import_recipe',
      title: 'Импорт-блюдо',
      mealTypes: {MealType.snack},
      servings: 1,
      minutes: 5,
      ingredients: const [
        RecipeIngredient(ingredientId: 'test_import_ingredient', grams: 100),
      ],
      steps: const ['Съешьте.'],
      image: 'assets/import_recipe.jpg',
      source: 'https://ru.wikibooks.org/wiki/Рецепт:Сырники',
    );
    final count = await database.merge(
      SeedBundle(
        version: 99,
        ingredients: const [ingredient],
        recipes: [recipe],
        prices: const {'test_import_ingredient': 150},
      ),
    );
    final repository = await database.loadRepository();

    expect(count, 1);
    expect(repository.recipes, hasLength(seed.recipes.length + 1));
    expect(repository.recipeById('test_import_recipe'), isNotNull);
    expect(
      repository.recipeById('test_import_recipe')?.image,
      'assets/import_recipe.jpg',
    );
    expect(
      repository.recipeById('test_import_recipe')?.source,
      'https://ru.wikibooks.org/wiki/Рецепт:Сырники',
    );
    expect(repository.pricePerKg('test_import_ingredient'), 150);
    expect(repository.allergensForRecipe(recipe), {Allergen.nuts});

    await database.close();
  });

  test('merge обновляет рецепт с тем же id', () async {
    final database = await AppDatabase.open(path: inMemoryDatabasePath);
    await database.seedIfNeeded(seed);
    final original = seed.recipes.first;
    final updated = Recipe(
      id: original.id,
      title: 'Обновлённое название',
      mealTypes: original.mealTypes,
      servings: original.servings,
      minutes: original.minutes,
      ingredients: original.ingredients,
      steps: original.steps,
    );
    final count = await database.merge(
      SeedBundle(
        version: 99,
        ingredients: const [],
        recipes: [updated],
        prices: const {},
      ),
    );
    final repository = await database.loadRepository();

    expect(count, 1);
    expect(repository.recipes, hasLength(seed.recipes.length));
    expect(repository.recipeById(original.id)?.title, 'Обновлённое название');

    await database.close();
  });

  test('merge откатывается при неизвестном ингредиенте', () async {
    final database = await AppDatabase.open(path: inMemoryDatabasePath);
    await database.seedIfNeeded(seed);
    final badRecipe = Recipe(
      id: 'bad_import',
      title: 'Плохой импорт',
      mealTypes: {MealType.snack},
      servings: 1,
      minutes: 5,
      ingredients: const [
        RecipeIngredient(ingredientId: 'missing_ingredient', grams: 100),
      ],
      steps: const ['Ничего.'],
    );
    final badBundle = SeedBundle(
      version: 99,
      ingredients: const [],
      recipes: [badRecipe],
      prices: const {},
    );

    await expectLater(database.merge(badBundle), throwsFormatException);
    final repository = await database.loadRepository();
    expect(repository.recipeById('bad_import'), isNull);
    expect(repository.recipes, hasLength(seed.recipes.length));

    await database.close();
  });

  test('пример импорта из examples применяется', () async {
    final raw = File('examples/import_example.json').readAsStringSync();
    final bundle = SeedBundle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final database = await AppDatabase.open(path: inMemoryDatabasePath);
    await database.seedIfNeeded(seed);

    final count = await database.merge(bundle);
    final repository = await database.loadRepository();

    expect(count, bundle.recipes.length);
    expect(repository.recipeById('example_yogurt_chia'), isNotNull);
    expect(repository.pricePerKg('chia_seeds'), 900);

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
          'image': 'assets/test_recipe.jpg',
          'source': 'https://ru.wikibooks.org/wiki/Рецепт:Тест',
        },
      ],
    });

    expect(bundle.ingredients, hasLength(1));
    expect(bundle.ingredients.single.allergens, {Allergen.nuts});
    expect(bundle.prices['test_ingredient'], 250);
    expect(bundle.recipes.single.mealTypes, {MealType.lunch});
    expect(bundle.recipes.single.ingredients.single.grams, 100);
    expect(bundle.recipes.single.image, 'assets/test_recipe.jpg');
    expect(
      bundle.recipes.single.source,
      'https://ru.wikibooks.org/wiki/Рецепт:Тест',
    );
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
