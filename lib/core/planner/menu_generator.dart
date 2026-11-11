import 'dart:math';

import '../data/recipe_repository.dart';
import '../models/daily_targets.dart';
import '../models/enums.dart';
import '../models/meal_plan.dart';
import '../models/nutrients.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import 'shopping_list_builder.dart';

class MenuSlot {
  const MenuSlot(this.type, this.share);

  final MealType type;
  final double share;
}

List<MenuSlot> slotsForMeals(int mealsPerDay) {
  return switch (mealsPerDay) {
    3 => const [
      MenuSlot(MealType.breakfast, 0.30),
      MenuSlot(MealType.lunch, 0.40),
      MenuSlot(MealType.dinner, 0.30),
    ],
    5 => const [
      MenuSlot(MealType.breakfast, 0.25),
      MenuSlot(MealType.lunch, 0.30),
      MenuSlot(MealType.snack, 0.10),
      MenuSlot(MealType.dinner, 0.25),
      MenuSlot(MealType.snack, 0.10),
    ],
    _ => const [
      MenuSlot(MealType.breakfast, 0.25),
      MenuSlot(MealType.lunch, 0.35),
      MenuSlot(MealType.dinner, 0.30),
      MenuSlot(MealType.snack, 0.10),
    ],
  };
}

class MealAlternative {
  const MealAlternative({
    required this.recipe,
    required this.scale,
    required this.nutrients,
    required this.cost,
  });

  final Recipe recipe;
  final double scale;
  final Nutrients nutrients;
  final double cost;
}

class _MealOption {
  const _MealOption({
    required this.meal,
    required this.score,
    required this.overBudget,
  });

  final PlannedMeal meal;
  final double score;
  final bool overBudget;
}

class _ScoredAlternative {
  const _ScoredAlternative(this.alternative, this.score);

  final MealAlternative alternative;
  final double score;
}

class MenuGenerator {
  const MenuGenerator({this.days = 7});

  final int days;

  WeeklyPlan generate({
    required UserProfile profile,
    required DailyTargets targets,
    required RecipeRepository repository,
    int seed = 1,
  }) {
    final slots = slotsForMeals(profile.mealsPerDay);
    final random = Random(seed);
    final usage = <String, int>{};
    final usedYesterday = <String>{};
    final dayPlans = <DayPlan>[];

    for (var dayIndex = 0; dayIndex < days; dayIndex++) {
      final usedToday = <String>{};
      final meals = <PlannedMeal>[];
      var spentToday = 0.0;

      for (final slot in slots) {
        var candidates = repository.recipes.where((recipe) {
          return recipe.mealTypes.contains(slot.type) &&
              repository.canUseRecipe(recipe, profile) &&
              _fitsTime(recipe, profile) &&
              !usedToday.contains(recipe.id);
        }).toList();

        if (candidates.isEmpty) {
          candidates = repository.recipes.where((recipe) {
            return recipe.mealTypes.contains(slot.type) &&
                repository.canUseRecipe(recipe, profile) &&
                _fitsTime(recipe, profile);
          }).toList();
        }

        if (candidates.isEmpty) {
          throw StateError(
            'Не хватает рецептов для «${slot.type.label}» с учётом ограничений',
          );
        }

        final meal = _pickMeal(
          candidates: candidates,
          slot: slot,
          targets: targets,
          repository: repository,
          usage: usage,
          usedYesterday: usedYesterday,
          random: random,
          profile: profile,
          spentToday: spentToday,
        );

        meals.add(meal);
        usedToday.add(meal.recipe.id);
        usage[meal.recipe.id] = (usage[meal.recipe.id] ?? 0) + 1;
        spentToday += meal.cost;
      }

      dayPlans.add(DayPlan(index: dayIndex + 1, meals: meals));
      usedYesterday
        ..clear()
        ..addAll(usedToday);
    }

    return WeeklyPlan(
      days: dayPlans,
      targets: targets,
      shoppingList: buildShoppingList(dayPlans, repository),
    );
  }

  WeeklyPlan replaceMeal({
    required WeeklyPlan plan,
    required UserProfile profile,
    required RecipeRepository repository,
    required int dayIndex,
    required int mealIndex,
    int seed = 1,
  }) {
    if (dayIndex < 0 || dayIndex >= plan.days.length) {
      throw StateError('Неверный день меню');
    }
    final day = plan.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) {
      throw StateError('Неверный приём пищи');
    }

    final current = day.meals[mealIndex];
    final slots = slotsForMeals(profile.mealsPerDay);
    if (mealIndex >= slots.length) {
      throw StateError('Не удалось определить приём пищи');
    }
    final slot = slots[mealIndex];

    final usedToday = <String>{
      for (var index = 0; index < day.meals.length; index++)
        if (index != mealIndex) day.meals[index].recipe.id,
    };
    final usage = <String, int>{};
    for (final otherDay in plan.days) {
      for (final meal in otherDay.meals) {
        if (identical(meal, current)) {
          continue;
        }
        usage[meal.recipe.id] = (usage[meal.recipe.id] ?? 0) + 1;
      }
    }
    final spentToday = day.meals.fold<double>(
      0,
      (sum, meal) => identical(meal, current) ? sum : sum + meal.cost,
    );
    final usedYesterday = dayIndex > 0
        ? plan.days[dayIndex - 1].meals.map((meal) => meal.recipe.id).toSet()
        : <String>{};

    var candidates = repository.recipes.where((recipe) {
      return recipe.mealTypes.contains(current.type) &&
          repository.canUseRecipe(recipe, profile) &&
          _fitsTime(recipe, profile) &&
          recipe.id != current.recipe.id &&
          !usedToday.contains(recipe.id);
    }).toList();

    if (candidates.isEmpty) {
      candidates = repository.recipes.where((recipe) {
        return recipe.mealTypes.contains(current.type) &&
            repository.canUseRecipe(recipe, profile) &&
            _fitsTime(recipe, profile) &&
            recipe.id != current.recipe.id;
      }).toList();
    }

    if (candidates.isEmpty) {
      throw StateError('Нет альтернативы для «${current.type.label}»');
    }

    final replacement = _pickMeal(
      candidates: candidates,
      slot: slot,
      targets: plan.targets,
      repository: repository,
      usage: usage,
      usedYesterday: usedYesterday,
      random: Random(seed + dayIndex * 31 + mealIndex * 17),
      profile: profile,
      spentToday: spentToday,
    );

    final newMeals = [...day.meals];
    newMeals[mealIndex] = replacement;
    final newDays = [...plan.days];
    newDays[dayIndex] = DayPlan(index: day.index, meals: newMeals);

    return WeeklyPlan(
      days: newDays,
      targets: plan.targets,
      shoppingList: buildShoppingList(newDays, repository),
    );
  }

  List<MealAlternative> alternativesForMeal({
    required WeeklyPlan plan,
    required UserProfile profile,
    required RecipeRepository repository,
    required int dayIndex,
    required int mealIndex,
  }) {
    if (dayIndex < 0 || dayIndex >= plan.days.length) {
      throw StateError('Неверный день меню');
    }
    final day = plan.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) {
      throw StateError('Неверный приём пищи');
    }
    final slots = slotsForMeals(profile.mealsPerDay);
    if (mealIndex >= slots.length) {
      throw StateError('Не удалось определить приём пищи');
    }

    final current = day.meals[mealIndex];
    final slot = slots[mealIndex];
    final targetCalories = plan.targets.nutrients.calories * slot.share;
    final targetProtein = plan.targets.nutrients.protein * slot.share;
    final targetFat = plan.targets.nutrients.fat * slot.share;
    final targetCarbs = plan.targets.nutrients.carbs * slot.share;
    final usedToday = <String>{
      for (var index = 0; index < day.meals.length; index++)
        if (index != mealIndex) day.meals[index].recipe.id,
    };

    final scored = <_ScoredAlternative>[];
    for (final recipe in repository.recipes) {
      if (!recipe.mealTypes.contains(current.type) ||
          recipe.id == current.recipe.id ||
          usedToday.contains(recipe.id) ||
          !repository.canUseRecipe(recipe, profile) ||
          !_fitsTime(recipe, profile)) {
        continue;
      }
      final perServing = repository.nutrientsPerServing(recipe);
      if (perServing.calories <= 0) {
        continue;
      }
      final scale = (targetCalories / perServing.calories)
          .clamp(0.5, 1.5)
          .toDouble();
      final nutrients = perServing * scale;
      final cost = repository.costPerServing(recipe) * scale;
      scored.add(
        _ScoredAlternative(
          MealAlternative(
            recipe: recipe,
            scale: scale,
            nutrients: nutrients,
            cost: cost,
          ),
          _deviationScore(
            nutrients: nutrients,
            targetCalories: targetCalories,
            targetProtein: targetProtein,
            targetFat: targetFat,
            targetCarbs: targetCarbs,
          ),
        ),
      );
    }

    scored.sort((a, b) => a.score.compareTo(b.score));
    return [for (final item in scored) item.alternative];
  }

  WeeklyPlan applyMealAlternative({
    required WeeklyPlan plan,
    required int dayIndex,
    required int mealIndex,
    required MealAlternative alternative,
    required RecipeRepository repository,
  }) {
    if (dayIndex < 0 || dayIndex >= plan.days.length) {
      throw StateError('Неверный день меню');
    }
    final day = plan.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) {
      throw StateError('Неверный приём пищи');
    }
    final current = day.meals[mealIndex];
    if (!alternative.recipe.mealTypes.contains(current.type)) {
      throw StateError('Блюдо не подходит для «${current.type.label}»');
    }
    if (alternative.scale <= 0) {
      throw StateError('Неверный размер порции');
    }

    final nutrients =
        repository.nutrientsPerServing(alternative.recipe) * alternative.scale;
    final cost =
        repository.costPerServing(alternative.recipe) * alternative.scale;
    final meal = PlannedMeal(
      type: current.type,
      recipe: alternative.recipe,
      scale: alternative.scale,
      nutrients: nutrients,
      ingredientGrams: {
        for (final item in alternative.recipe.ingredients)
          item.ingredientId: item.grams * alternative.scale,
      },
      cost: cost,
    );

    final newMeals = [...day.meals];
    newMeals[mealIndex] = meal;
    final newDays = [...plan.days];
    newDays[dayIndex] = DayPlan(index: day.index, meals: newMeals);

    return WeeklyPlan(
      days: newDays,
      targets: plan.targets,
      shoppingList: buildShoppingList(newDays, repository),
    );
  }

  bool _fitsTime(Recipe recipe, UserProfile profile) {
    final maxMinutes = profile.maxCookMinutes;
    return maxMinutes == null || recipe.minutes <= maxMinutes;
  }

  double _deviationScore({
    required Nutrients nutrients,
    required double targetCalories,
    required double targetProtein,
    required double targetFat,
    required double targetCarbs,
  }) {
    var score =
        (nutrients.calories - targetCalories).abs() / targetCalories * 2.0;
    score +=
        (nutrients.protein - targetProtein).abs() / max(targetProtein, 1) * 1.2;
    score += (nutrients.fat - targetFat).abs() / max(targetFat, 1) * 0.6;
    score += (nutrients.carbs - targetCarbs).abs() / max(targetCarbs, 1) * 0.6;
    return score;
  }

  PlannedMeal _pickMeal({
    required List<Recipe> candidates,
    required MenuSlot slot,
    required DailyTargets targets,
    required RecipeRepository repository,
    required Map<String, int> usage,
    required Set<String> usedYesterday,
    required Random random,
    required UserProfile profile,
    required double spentToday,
  }) {
    final targetCalories = targets.nutrients.calories * slot.share;
    final targetProtein = targets.nutrients.protein * slot.share;
    final targetFat = targets.nutrients.fat * slot.share;
    final targetCarbs = targets.nutrients.carbs * slot.share;
    final dailyBudget = profile.dailyBudgetRub;

    final options = <_MealOption>[];

    for (final recipe in candidates) {
      final perServing = repository.nutrientsPerServing(recipe);
      if (perServing.calories <= 0) {
        continue;
      }

      final rawScale = targetCalories / perServing.calories;
      final scale = rawScale.clamp(0.5, 1.5).toDouble();
      final nutrients = perServing * scale;
      final cost = repository.costPerServing(recipe) * scale;

      var score = _deviationScore(
        nutrients: nutrients,
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        targetFat: targetFat,
        targetCarbs: targetCarbs,
      );
      score += (usage[recipe.id] ?? 0) * 0.18;
      if (usedYesterday.contains(recipe.id)) {
        score += 0.5;
      }
      if (profile.preferredRecipeIds.contains(recipe.id)) {
        score -= 0.35;
      }

      var overBudget = false;
      if (dailyBudget != null) {
        final slotBudget = dailyBudget * slot.share;
        score += (cost - slotBudget).abs() / max(slotBudget, 1) * 0.4;
        overBudget = cost > slotBudget || spentToday + cost > dailyBudget;
        if (overBudget) {
          score += 5.0;
        }
      }

      score += random.nextDouble() * 0.04;

      options.add(
        _MealOption(
          meal: PlannedMeal(
            type: slot.type,
            recipe: recipe,
            scale: scale,
            nutrients: nutrients,
            ingredientGrams: {
              for (final item in recipe.ingredients)
                item.ingredientId: item.grams * scale,
            },
            cost: cost,
          ),
          score: score,
          overBudget: overBudget,
        ),
      );
    }

    if (options.isEmpty) {
      throw StateError('Не удалось подобрать блюдо для «${slot.type.label}»');
    }

    final affordable = options.where((option) => !option.overBudget).toList();
    final pool = affordable.isEmpty ? options : affordable;
    pool.sort((a, b) => a.score.compareTo(b.score));
    return pool.first.meal;
  }
}
