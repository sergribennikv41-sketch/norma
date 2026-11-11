import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/app_database.dart';
import 'core/data/in_memory_recipe_repository.dart';
import 'core/data/recipe_repository.dart';
import 'core/data/seed_data.dart';
import 'core/data/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  RecipeRepository repository;
  try {
    final database = await AppDatabase.open();
    await database.seedIfEmpty(seedBundle);
    repository = await database.loadRepository();
  } catch (_) {
    repository = InMemoryRecipeRepository.seeded();
  }

  SavedSession? session;
  try {
    session = await SessionStorage().load();
  } catch (_) {
    session = null;
  }

  runApp(NormaApp(initialSession: session, repository: repository));
}
