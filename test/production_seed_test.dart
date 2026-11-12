import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/models/seed_bundle.dart';

void main() {
  test('рабочий seed содержит только импортированный пилот', () {
    final raw = File('assets/data/seed.json').readAsStringSync();
    final bundle = SeedBundle.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
    final ingredientIds = {
      for (final ingredient in bundle.ingredients) ingredient.id,
    };

    expect(bundle.version, 24);
    expect(bundle.replaceAllRecipes, isTrue);
    expect(bundle.recipes, hasLength(1000));
    for (final recipe in bundle.recipes) {
      expect(recipe.ingredients, isNotEmpty, reason: recipe.id);
      expect(recipe.steps, isNotEmpty, reason: recipe.id);
      expect(recipe.mealTypes, isNotEmpty, reason: recipe.id);
      expect(recipe.source, contains('russianfood.com'), reason: recipe.id);
      expect(
        recipe.image,
        startsWith('assets/images/recipes/'),
        reason: recipe.id,
      );
      for (final item in recipe.ingredients) {
        expect(ingredientIds, contains(item.ingredientId), reason: recipe.id);
      }
    }
  });
}
