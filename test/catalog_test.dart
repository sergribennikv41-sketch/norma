import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/in_memory_recipe_repository.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/user_profile.dart';
import 'package:norma/core/nutrition/targets_calculator.dart';
import 'package:norma/core/planner/menu_generator.dart';
import 'package:norma/features/catalog/catalog_page.dart';

import 'support/seed_fixture.dart';

void main() {
  late InMemoryRecipeRepository repository;
  setUpAll(() {
    repository = loadSeedRepository();
  });

  testWidgets('каталог показывает рецепты и ищет по названию', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(repository: repository)),
    );

    expect(find.text('Каталог рецептов'), findsOneWidget);
    expect(find.text('Найдено: ${repository.recipes.length}'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'овсянка');
    await tester.pump();

    expect(find.text('Овсянка с бананом и миндалем'), findsOneWidget);
    expect(find.text('Треска с картофелем и брокколи'), findsNothing);
  });

  testWidgets('каталог фильтрует по приёму пищи', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(repository: repository)),
    );
    final lunchCount = repository.recipes
        .where((recipe) => recipe.mealTypes.contains(MealType.lunch))
        .length;

    await tester.tap(find.widgetWithText(ChoiceChip, 'Обед'));
    await tester.pump();

    expect(find.text('Найдено: $lunchCount'), findsOneWidget);
  });

  testWidgets('из каталога можно добавить блюдо в рацион', (tester) async {
    const profile = UserProfile(
      sex: Sex.male,
      age: 30,
      heightCm: 180,
      weightKg: 80,
      activity: ActivityLevel.moderate,
      goal: Goal.lose,
      pace: Pace.medium,
      mealsPerDay: 4,
    );
    final targets = const TargetsCalculator().calculate(profile);
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );

    CatalogPick? pick;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () async {
                  pick = await Navigator.of(context).push<CatalogPick>(
                    MaterialPageRoute<CatalogPick>(
                      builder: (context) =>
                          CatalogPage(repository: repository, plan: plan),
                    ),
                  );
                },
                child: const Text('Открыть каталог'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Открыть каталог'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'овсянка');
    await tester.pump();
    await tester.tap(
      find.widgetWithText(ListTile, 'Овсянка с бананом и миндалем'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('В рацион'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect(pick, isNotNull);
    expect(pick!.recipeId, 'oatmeal_banana_almonds');
    expect(pick!.dayIndex, 0);
    expect(pick!.mealIndex, 0);
  });

  testWidgets('каталог открывает карточку рецепта', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(repository: repository)),
    );

    await tester.enterText(find.byType(TextField), 'овсянка');
    await tester.pump();
    await tester.tap(
      find.widgetWithText(ListTile, 'Овсянка с бананом и миндалем'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Приготовление'), findsOneWidget);
    expect(find.textContaining('Овсяные хлопья'), findsOneWidget);
    expect(find.text('Закрыть'), findsOneWidget);
  });
}
