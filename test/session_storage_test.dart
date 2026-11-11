import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/session_storage.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/plan_snapshot.dart';
import 'package:norma/core/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const profile = UserProfile(
    sex: Sex.female,
    age: 34,
    heightCm: 168,
    weightKg: 61.5,
    activity: ActivityLevel.high,
    goal: Goal.gain,
    pace: Pace.slow,
    mealsPerDay: 5,
    excludedAllergens: {Allergen.lactose, Allergen.nuts},
    dislikedIngredientIds: {'hard_cheese'},
    maxCookMinutes: 30,
    dailyBudgetRub: 900,
    preferredRecipeIds: {'chicken_buckwheat'},
    blockedRecipeIds: {'lentil_stew'},
    cityId: 'kazan',
    storeId: 'lenta',
  );

  test('сохраняет и загружает профиль', () async {
    final storage = SessionStorage();
    await storage.save(profile, 12);
    final session = await storage.load();

    expect(session, isNotNull);
    final loaded = session!;
    expect(loaded.seed, 12);
    expect(loaded.profile.sex, Sex.female);
    expect(loaded.profile.age, 34);
    expect(loaded.profile.heightCm, 168);
    expect(loaded.profile.weightKg, 61.5);
    expect(loaded.profile.activity, ActivityLevel.high);
    expect(loaded.profile.goal, Goal.gain);
    expect(loaded.profile.pace, Pace.slow);
    expect(loaded.profile.mealsPerDay, 5);
    expect(loaded.profile.excludedAllergens, {Allergen.lactose, Allergen.nuts});
    expect(loaded.profile.dislikedIngredientIds, {'hard_cheese'});
    expect(loaded.profile.maxCookMinutes, 30);
    expect(loaded.profile.dailyBudgetRub, 900);
    expect(loaded.profile.preferredRecipeIds, {'chicken_buckwheat'});
    expect(loaded.profile.blockedRecipeIds, {'lentil_stew'});
    expect(loaded.profile.cityId, 'kazan');
    expect(loaded.profile.storeId, 'lenta');
  });

  test('сохраняет и загружает снимок плана', () async {
    final storage = SessionStorage();
    const plan = SavedPlan(
      meals: [
        SavedMeal(
          dayIndex: 0,
          mealIndex: 0,
          type: MealType.breakfast,
          recipeId: 'oatmeal_banana_plain',
          scale: 1.2,
        ),
      ],
    );
    await storage.save(profile, 3, plan: plan);
    final session = await storage.load();

    expect(session, isNotNull);
    expect(session!.plan, isNotNull);
    final loadedPlan = session.plan!;
    expect(loadedPlan.meals, hasLength(1));
    expect(loadedPlan.meals.first.recipeId, 'oatmeal_banana_plain');
    expect(loadedPlan.meals.first.type, MealType.breakfast);
    expect(loadedPlan.meals.first.scale, 1.2);
  });

  test('пустое хранилище возвращает null', () async {
    expect(await SessionStorage().load(), isNull);
  });

  test('битый JSON не ломает загрузку', () async {
    SharedPreferences.setMockInitialValues({'norma.profile': 'not json'});
    expect(await SessionStorage().load(), isNull);
  });

  test('очистка удаляет сохранённую сессию', () async {
    final storage = SessionStorage();
    await storage.save(profile, 5);
    await storage.clear();

    expect(await storage.load(), isNull);
  });
}
