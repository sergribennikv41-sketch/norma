import 'enums.dart';

class RecipeIngredient {
  const RecipeIngredient({required this.ingredientId, required this.grams});

  final String ingredientId;
  final double grams;

  Map<String, Object?> toJson() {
    return {'ingredientId': ingredientId, 'grams': grams};
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientId: json['ingredientId'] is String
          ? json['ingredientId'] as String
          : '',
      grams: json['grams'] is num ? (json['grams'] as num).toDouble() : 0,
    );
  }
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
    this.image,
    this.source,
  });

  final String id;
  final String title;
  final Set<MealType> mealTypes;
  final int servings;
  final int minutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final String? image;
  final String? source;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'mealTypes': [for (final mealType in mealTypes) mealType.name],
      'servings': servings,
      'minutes': minutes,
      'ingredients': [
        for (final ingredient in ingredients) ingredient.toJson(),
      ],
      'steps': steps,
      'image': image,
      'source': source,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = <RecipeIngredient>[];
    final rawIngredients = json['ingredients'];
    if (rawIngredients is List) {
      for (final item in rawIngredients) {
        if (item is Map) {
          ingredients.add(
            RecipeIngredient.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final steps = <String>[];
    final rawSteps = json['steps'];
    if (rawSteps is List) {
      steps.addAll(rawSteps.whereType<String>());
    }

    return Recipe(
      id: json['id'] is String ? json['id'] as String : '',
      title: json['title'] is String ? json['title'] as String : '',
      mealTypes: _mealTypesFromJson(json['mealTypes']),
      servings: json['servings'] is num ? (json['servings'] as num).toInt() : 1,
      minutes: json['minutes'] is num ? (json['minutes'] as num).toInt() : 0,
      ingredients: ingredients,
      steps: steps,
      image: json['image'] is String && (json['image'] as String).isNotEmpty
          ? json['image'] as String
          : null,
      source: json['source'] is String && (json['source'] as String).isNotEmpty
          ? json['source'] as String
          : null,
    );
  }
}

Set<MealType> _mealTypesFromJson(Object? raw) {
  final result = <MealType>{};
  if (raw is List) {
    for (final item in raw) {
      for (final mealType in MealType.values) {
        if (mealType.name == item) {
          result.add(mealType);
        }
      }
    }
  }
  return result;
}
