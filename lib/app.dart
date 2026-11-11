import 'package:flutter/material.dart';

import 'core/data/in_memory_recipe_repository.dart';
import 'core/data/recipe_repository.dart';
import 'core/data/session_storage.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/plan/plan_page.dart';

class NormaApp extends StatelessWidget {
  const NormaApp({super.key, this.initialSession, this.repository});

  final SavedSession? initialSession;
  final RecipeRepository? repository;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
    );
    final session = initialSession;
    final recipeRepository = repository ?? InMemoryRecipeRepository.seeded();
    return MaterialApp(
      title: 'Норма',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      home: session == null
          ? OnboardingPage(repository: recipeRepository)
          : PlanPage(
              profile: session.profile,
              initialSeed: session.seed,
              initialPlan: session.plan,
              repository: recipeRepository,
            ),
    );
  }
}
