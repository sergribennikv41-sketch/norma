import 'package:flutter/material.dart';

import 'core/data/recipe_repository.dart';
import 'core/data/session_storage.dart';
import 'core/data/theme_storage.dart';
import 'core/models/plan_snapshot.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/home/home_page.dart';
import 'features/home/profile_view.dart';

class NormaApp extends StatefulWidget {
  const NormaApp({
    super.key,
    required this.repository,
    this.initialSession,
    this.initialWeeks = const {},
    this.themeController,
  });

  final RecipeRepository repository;
  final SavedSession? initialSession;
  final Map<String, SavedWeek> initialWeeks;
  final ThemeController? themeController;

  @override
  State<NormaApp> createState() => _NormaAppState();
}

class _NormaAppState extends State<NormaApp> {
  late final ThemeController _themeController;
  late final bool _ownsThemeController;

  @override
  void initState() {
    super.initState();
    _ownsThemeController = widget.themeController == null;
    _themeController =
        widget.themeController ?? ThemeController(storage: ThemeStorage());
  }

  @override
  void dispose() {
    if (_ownsThemeController) {
      _themeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.initialSession;
    return ThemeControllerScope(
      controller: _themeController,
      child: ListenableBuilder(
        listenable: _themeController,
        builder: (context, child) {
          return MaterialApp(
            title: 'Норма',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _themeController.mode,
            home: session == null
                ? Builder(
                    builder: (context) => ProfileView(
                      repository: widget.repository,
                      onSubmit: (profile) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (context) => HomePage(
                              profile: profile,
                              initialWeeks: widget.initialWeeks,
                              repository: widget.repository,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : HomePage(
                    profile: session.profile,
                    initialSeed: session.seed,
                    initialPlan: session.plan,
                    initialWeeks: widget.initialWeeks,
                    repository: widget.repository,
                  ),
          );
        },
      ),
    );
  }
}
