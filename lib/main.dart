import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/data/app_database.dart';
import 'core/data/in_memory_recipe_repository.dart';
import 'core/data/recipe_repository.dart';
import 'core/data/seed_loader.dart';
import 'core/data/session_storage.dart';
import 'core/data/theme_storage.dart';
import 'core/data/window_bounds_storage.dart';
import 'core/models/seed_bundle.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupWindow();

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
    await database.seedIfNeeded(seed);
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

  ThemeController themeController;
  try {
    final storage = ThemeStorage();
    themeController = ThemeController(
      storage: storage,
      initialMode: await storage.load(),
    );
  } catch (_) {
    themeController = ThemeController(storage: ThemeStorage());
  }

  runApp(
    NormaApp(
      initialSession: session,
      repository: repository,
      themeController: themeController,
    ),
  );
}

bool get _isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

Future<void> _setupWindow() async {
  if (!_isDesktop) {
    return;
  }
  await windowManager.ensureInitialized();
  final savedBounds = await WindowBoundsStorage().load();
  final size = savedBounds == null
      ? const Size(1280, 860)
      : Size(
          savedBounds.width < 1024 ? 1024 : savedBounds.width,
          savedBounds.height < 700 ? 700 : savedBounds.height,
        );
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: size,
      minimumSize: const Size(1024, 700),
      center: savedBounds == null,
      title: 'Норма',
    ),
    () async {
      if (savedBounds != null) {
        await windowManager.setBounds(
          Rect.fromLTWH(
            savedBounds.left,
            savedBounds.top,
            size.width,
            size.height,
          ),
        );
      }
      await windowManager.show();
      await windowManager.focus();
    },
  );
  await windowManager.setPreventClose(true);
  windowManager.addListener(_WindowStateListener());
}

class _WindowStateListener with WindowListener {
  @override
  void onWindowClose() {
    _saveAndDestroy();
  }

  Future<void> _saveAndDestroy() async {
    try {
      final bounds = await windowManager.getBounds();
      await WindowBoundsStorage().save(bounds);
    } finally {
      await windowManager.destroy();
    }
  }
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
