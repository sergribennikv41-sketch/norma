import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/week_storage.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/plan_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('сохраняет и загружает недели', () async {
    final week = SavedWeek(
      weekStart: DateTime(2026, 11, 9),
      seed: 42,
      plan: const SavedPlan(
        meals: [
          SavedMeal(
            dayIndex: 0,
            mealIndex: 0,
            type: MealType.breakfast,
            recipeId: 'rf_1',
            scale: 1,
          ),
        ],
      ),
      checkedIngredients: const {'chicken_breast'},
    );
    final storage = WeekStorage();
    await storage.save({week.key: week});

    final loaded = await storage.load();
    expect(loaded, hasLength(1));
    final restored = loaded['2026-11-09']!;
    expect(restored.seed, 42);
    expect(restored.checkedIngredients, {'chicken_breast'});
    expect(restored.plan.meals.single.recipeId, 'rf_1');
  });

  test('пустое хранилище и битые данные не падают', () async {
    final storage = WeekStorage();
    expect(await storage.load(), isEmpty);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('norma.weeks', 'not-json');
    expect(await storage.load(), isEmpty);
  });

  test('clear удаляет недели', () async {
    final storage = WeekStorage();
    await storage.save({
      '2026-11-09': SavedWeek(
        weekStart: DateTime(2026, 11, 9),
        seed: 1,
        plan: const SavedPlan(meals: []),
      ),
    });
    await storage.clear();
    expect(await storage.load(), isEmpty);
  });
}
