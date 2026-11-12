import 'enums.dart';
import 'meal_plan.dart';

class SavedMeal {
  const SavedMeal({
    required this.dayIndex,
    required this.mealIndex,
    required this.type,
    required this.recipeId,
    required this.scale,
  });

  final int dayIndex;
  final int mealIndex;
  final MealType type;
  final String recipeId;
  final double scale;

  Map<String, Object?> toJson() {
    return {
      'day': dayIndex,
      'meal': mealIndex,
      'type': type.name,
      'recipe': recipeId,
      'scale': scale,
    };
  }

  factory SavedMeal.fromJson(Map<String, dynamic> json) {
    return SavedMeal(
      dayIndex: _intValue(json['day'], -1),
      mealIndex: _intValue(json['meal'], -1),
      type: _mealTypeFromName(json['type']),
      recipeId: json['recipe'] is String ? json['recipe'] as String : '',
      scale: _doubleValue(json['scale'], 0),
    );
  }
}

class SavedPlan {
  const SavedPlan({required this.meals});

  final List<SavedMeal> meals;

  factory SavedPlan.fromWeeklyPlan(WeeklyPlan plan) {
    final meals = <SavedMeal>[];
    for (var dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      final day = plan.days[dayIndex];
      for (var mealIndex = 0; mealIndex < day.meals.length; mealIndex++) {
        final meal = day.meals[mealIndex];
        meals.add(
          SavedMeal(
            dayIndex: dayIndex,
            mealIndex: mealIndex,
            type: meal.type,
            recipeId: meal.recipe.id,
            scale: meal.scale,
          ),
        );
      }
    }
    return SavedPlan(meals: meals);
  }

  factory SavedPlan.fromJson(Map<String, dynamic> json) {
    final meals = <SavedMeal>[];
    final raw = json['meals'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          meals.add(SavedMeal.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return SavedPlan(meals: meals);
  }

  Map<String, Object?> toJson() {
    return {
      'meals': [for (final meal in meals) meal.toJson()],
    };
  }
}

int _intValue(Object? value, int fallback) {
  return value is num ? value.toInt() : fallback;
}

double _doubleValue(Object? value, double fallback) {
  return value is num ? value.toDouble() : fallback;
}

MealType _mealTypeFromName(Object? name) {
  return MealType.values.firstWhere(
    (value) => value.name == name,
    orElse: () => MealType.breakfast,
  );
}

class SavedWeek {
  const SavedWeek({
    required this.weekStart,
    required this.seed,
    required this.plan,
    this.checkedIngredients = const {},
  });

  final DateTime weekStart;
  final int seed;
  final SavedPlan plan;
  final Set<String> checkedIngredients;

  String get key {
    final month = weekStart.month.toString().padLeft(2, '0');
    final day = weekStart.day.toString().padLeft(2, '0');
    return '${weekStart.year}-$month-$day';
  }

  Map<String, Object?> toJson() {
    return {
      'weekStart': key,
      'seed': seed,
      'plan': plan.toJson(),
      'checked': checkedIngredients.toList(),
    };
  }

  factory SavedWeek.fromJson(Map<String, dynamic> json) {
    final parsed = DateTime.tryParse(
      json['weekStart'] is String ? json['weekStart'] as String : '',
    );
    final weekStart = parsed == null
        ? DateTime(1970)
        : DateTime(parsed.year, parsed.month, parsed.day);
    final rawPlan = json['plan'];
    final plan = rawPlan is Map
        ? SavedPlan.fromJson(Map<String, dynamic>.from(rawPlan))
        : const SavedPlan(meals: []);
    final checked = <String>{};
    final rawChecked = json['checked'];
    if (rawChecked is List) {
      for (final item in rawChecked) {
        if (item is String && item.isNotEmpty) {
          checked.add(item);
        }
      }
    }
    return SavedWeek(
      weekStart: weekStart,
      seed: _intValue(json['seed'], 1),
      plan: plan,
      checkedIngredients: checked,
    );
  }
}
