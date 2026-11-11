import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/in_memory_recipe_repository.dart';
import 'package:norma/core/models/enums.dart';
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
