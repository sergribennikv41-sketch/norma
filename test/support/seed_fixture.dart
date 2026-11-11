import 'dart:convert';
import 'dart:io';

import 'package:norma/core/data/in_memory_recipe_repository.dart';
import 'package:norma/core/models/seed_bundle.dart';

SeedBundle loadSeedBundleFromFile() {
  final raw = File('assets/data/seed.json').readAsStringSync();
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Некорректный seed-файл');
  }
  return SeedBundle.fromJson(Map<String, dynamic>.from(decoded));
}

InMemoryRecipeRepository loadSeedRepository() {
  final bundle = loadSeedBundleFromFile();
  return InMemoryRecipeRepository(
    ingredients: bundle.ingredients,
    recipes: bundle.recipes,
    prices: bundle.prices,
  );
}
