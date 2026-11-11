import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../models/enums.dart';
import '../models/ingredient.dart';
import '../models/nutrients.dart';
import '../models/recipe.dart';
import '../models/seed_bundle.dart';
import 'in_memory_recipe_repository.dart';

class AppDatabase {
  AppDatabase._(this._db);

  static const _version = 1;
  static const _dbName = 'norma.db';

  final ffi.Database _db;

  static Future<AppDatabase> open({String? path}) async {
    final factory = _factory();
    final databasePath = path ?? await _defaultPath();
    final db = await factory.openDatabase(
      databasePath,
      options: ffi.OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
        },
      ),
    );
    return AppDatabase._(db);
  }

  static ffi.DatabaseFactory _factory() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      ffi.sqfliteFfiInit();
      return ffi.databaseFactoryFfi;
    }
    return sqflite.databaseFactory;
  }

  static Future<String> _defaultPath() async {
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, _dbName);
  }

  static Future<void> _createSchema(ffi.Database db) async {
    await db.execute('''
CREATE TABLE ingredients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  kcal REAL NOT NULL,
  protein REAL NOT NULL,
  fat REAL NOT NULL,
  carbs REAL NOT NULL
)
''');
    await db.execute('''
CREATE TABLE ingredient_allergens (
  ingredient_id TEXT NOT NULL,
  allergen TEXT NOT NULL,
  PRIMARY KEY (ingredient_id, allergen),
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
)
''');
    await db.execute('''
CREATE TABLE ingredient_prices (
  ingredient_id TEXT PRIMARY KEY,
  price_per_kg REAL NOT NULL,
  updated_at TEXT,
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
)
''');
    await db.execute('''
CREATE TABLE recipes (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  servings INTEGER NOT NULL DEFAULT 1,
  minutes INTEGER NOT NULL,
  source TEXT
)
''');
    await db.execute('''
CREATE TABLE recipe_meal_types (
  recipe_id TEXT NOT NULL,
  meal_type TEXT NOT NULL,
  PRIMARY KEY (recipe_id, meal_type),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
)
''');
    await db.execute('''
CREATE TABLE recipe_ingredients (
  recipe_id TEXT NOT NULL,
  ingredient_id TEXT NOT NULL,
  grams REAL NOT NULL,
  PRIMARY KEY (recipe_id, ingredient_id),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
)
''');
    await db.execute('''
CREATE TABLE recipe_steps (
  recipe_id TEXT NOT NULL,
  step_no INTEGER NOT NULL,
  text TEXT NOT NULL,
  PRIMARY KEY (recipe_id, step_no),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
)
''');
    await db.execute(
      'CREATE INDEX idx_recipe_meal_types_type ON recipe_meal_types(meal_type)',
    );
    await db.execute(
      'CREATE INDEX idx_recipe_ingredients_ingredient ON recipe_ingredients(ingredient_id)',
    );
  }

  Future<bool> get isEmpty async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS count FROM ingredients',
    );
    final count = rows.first['count'];
    return count is num && count == 0;
  }

  Future<void> seedIfEmpty(SeedBundle bundle) async {
    if (!await isEmpty) {
      return;
    }
    await import(bundle);
  }

  Future<void> import(SeedBundle bundle) async {
    await _db.transaction((txn) async {
      await txn.delete('recipe_steps');
      await txn.delete('recipe_ingredients');
      await txn.delete('recipe_meal_types');
      await txn.delete('recipes');
      await txn.delete('ingredient_prices');
      await txn.delete('ingredient_allergens');
      await txn.delete('ingredients');

      for (final ingredient in bundle.ingredients) {
        await txn.insert('ingredients', {
          'id': ingredient.id,
          'name': ingredient.name,
          'category': ingredient.category,
          'kcal': ingredient.per100g.calories,
          'protein': ingredient.per100g.protein,
          'fat': ingredient.per100g.fat,
          'carbs': ingredient.per100g.carbs,
        });
        for (final allergen in ingredient.allergens) {
          await txn.insert('ingredient_allergens', {
            'ingredient_id': ingredient.id,
            'allergen': allergen.name,
          });
        }
        final price = bundle.prices[ingredient.id];
        if (price != null) {
          await txn.insert('ingredient_prices', {
            'ingredient_id': ingredient.id,
            'price_per_kg': price,
          });
        }
      }

      for (final recipe in bundle.recipes) {
        await txn.insert('recipes', {
          'id': recipe.id,
          'title': recipe.title,
          'servings': recipe.servings,
          'minutes': recipe.minutes,
        });
        for (final mealType in recipe.mealTypes) {
          await txn.insert('recipe_meal_types', {
            'recipe_id': recipe.id,
            'meal_type': mealType.name,
          });
        }
        for (final item in recipe.ingredients) {
          await txn.insert('recipe_ingredients', {
            'recipe_id': recipe.id,
            'ingredient_id': item.ingredientId,
            'grams': item.grams,
          });
        }
        for (var index = 0; index < recipe.steps.length; index++) {
          await txn.insert('recipe_steps', {
            'recipe_id': recipe.id,
            'step_no': index + 1,
            'text': recipe.steps[index],
          });
        }
      }
    });
  }

  Future<InMemoryRecipeRepository> loadRepository() async {
    final ingredientRows = await _db.query('ingredients', orderBy: 'id');
    final allergenRows = await _db.query('ingredient_allergens');
    final priceRows = await _db.query('ingredient_prices');
    final recipeRows = await _db.query('recipes', orderBy: 'id');
    final mealTypeRows = await _db.query('recipe_meal_types');
    final recipeIngredientRows = await _db.query(
      'recipe_ingredients',
      orderBy: 'recipe_id, ingredient_id',
    );
    final stepRows = await _db.query(
      'recipe_steps',
      orderBy: 'recipe_id, step_no',
    );

    final allergensByIngredient = <String, Set<Allergen>>{};
    for (final row in allergenRows) {
      final id = row['ingredient_id'] as String?;
      final name = row['allergen'] as String?;
      if (id == null || name == null) {
        continue;
      }
      final allergen = _allergenByName(name);
      if (allergen == null) {
        continue;
      }
      allergensByIngredient.putIfAbsent(id, () => <Allergen>{}).add(allergen);
    }

    final ingredients = <Ingredient>[
      for (final row in ingredientRows)
        Ingredient(
          id: row['id'] as String,
          name: row['name'] as String,
          category: row['category'] as String,
          per100g: Nutrients(
            calories: _toDouble(row['kcal']),
            protein: _toDouble(row['protein']),
            fat: _toDouble(row['fat']),
            carbs: _toDouble(row['carbs']),
          ),
          allergens: allergensByIngredient[row['id']] ?? const {},
        ),
    ];

    final prices = <String, double>{};
    for (final row in priceRows) {
      final id = row['ingredient_id'] as String?;
      if (id == null) {
        continue;
      }
      prices[id] = _toDouble(row['price_per_kg']);
    }

    final mealTypesByRecipe = <String, Set<MealType>>{};
    for (final row in mealTypeRows) {
      final id = row['recipe_id'] as String?;
      final name = row['meal_type'] as String?;
      if (id == null || name == null) {
        continue;
      }
      final mealType = _mealTypeByName(name);
      if (mealType == null) {
        continue;
      }
      mealTypesByRecipe.putIfAbsent(id, () => <MealType>{}).add(mealType);
    }

    final ingredientsByRecipe = <String, List<RecipeIngredient>>{};
    for (final row in recipeIngredientRows) {
      final id = row['recipe_id'] as String?;
      if (id == null) {
        continue;
      }
      ingredientsByRecipe
          .putIfAbsent(id, () => [])
          .add(
            RecipeIngredient(
              ingredientId: row['ingredient_id'] as String? ?? '',
              grams: _toDouble(row['grams']),
            ),
          );
    }

    final stepsByRecipe = <String, List<String>>{};
    for (final row in stepRows) {
      final id = row['recipe_id'] as String?;
      if (id == null) {
        continue;
      }
      stepsByRecipe.putIfAbsent(id, () => []).add(row['text'] as String? ?? '');
    }

    final recipes = <Recipe>[
      for (final row in recipeRows)
        Recipe(
          id: row['id'] as String,
          title: row['title'] as String,
          mealTypes: mealTypesByRecipe[row['id']] ?? const {},
          servings: _toInt(row['servings'], 1),
          minutes: _toInt(row['minutes'], 0),
          ingredients: ingredientsByRecipe[row['id']] ?? const [],
          steps: stepsByRecipe[row['id']] ?? const [],
        ),
    ];

    return InMemoryRecipeRepository(
      ingredients: ingredients,
      recipes: recipes,
      prices: prices,
    );
  }

  Future<void> close() => _db.close();
}

double _toDouble(Object? value) {
  return value is num ? value.toDouble() : 0;
}

int _toInt(Object? value, int fallback) {
  return value is num ? value.toInt() : fallback;
}

Allergen? _allergenByName(String name) {
  for (final allergen in Allergen.values) {
    if (allergen.name == name) {
      return allergen;
    }
  }
  return null;
}

MealType? _mealTypeByName(String name) {
  for (final mealType in MealType.values) {
    if (mealType.name == name) {
      return mealType;
    }
  }
  return null;
}
