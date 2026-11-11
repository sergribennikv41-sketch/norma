import 'dart:convert';
import 'dart:io';

import 'package:norma/core/models/recipe.dart';
import 'package:norma/core/models/seed_bundle.dart';

void main() {
  final file = File('assets/data/seed.json');
  final bundle = SeedBundle.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  );

  for (final recipe in bundle.recipes) {
    final path = 'assets/images/recipes/${recipe.id}.png';
    if (!File(path).existsSync()) {
      stderr.writeln('missing illustration: $path');
      exitCode = 1;
      return;
    }
  }

  final recipes = [
    for (final recipe in bundle.recipes)
      Recipe(
        id: recipe.id,
        title: recipe.title,
        mealTypes: recipe.mealTypes,
        servings: recipe.servings,
        minutes: recipe.minutes,
        ingredients: recipe.ingredients,
        steps: recipe.steps,
        image: 'assets/images/recipes/${recipe.id}.png',
      ),
  ];

  final updated = SeedBundle(
    version: bundle.version + 1,
    ingredients: bundle.ingredients,
    recipes: recipes,
    prices: bundle.prices,
  );
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(updated.toJson())}\n',
  );
  stdout.writeln('recipes: ${recipes.length}, version: ${updated.version}');
}
