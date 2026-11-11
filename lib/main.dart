import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/app_database.dart';
import 'core/data/in_memory_recipe_repository.dart';
import 'core/data/recipe_repository.dart';
import 'core/data/seed_loader.dart';
import 'core/data/session_storage.dart';
import 'core/models/seed_bundle.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SeedBundle seed;
  try {
    seed = await loadSeedBundle();
  } catch (error) {
    runApp(
      _StartupErrorApp(message: 'Не удалось загрузить базу рецептов: $error'),
    );
    return;
  }

  RecipeRepository repository;
  try {
    final database = await AppDatabase.open();
    await database.seedIfEmpty(seed);
    repository = await database.loadRepository();
  } catch (_) {
    repository = InMemoryRecipeRepository(
      ingredients: seed.ingredients,
      recipes: seed.recipes,
      prices: seed.prices,
    );
  }

  SavedSession? session;
  try {
    session = await SessionStorage().load();
  } catch (_) {
    session = null;
  }

  runApp(NormaApp(initialSession: session, repository: repository));
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Норма',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text('Не удалось запустить приложение'),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
