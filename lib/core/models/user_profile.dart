import 'enums.dart';

class UserProfile {
  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    required this.pace,
    this.mealsPerDay = 4,
    this.excludedAllergens = const {},
    this.dislikedIngredientIds = const {},
    this.maxCookMinutes,
    this.dailyBudgetRub,
    this.preferredRecipeIds = const {},
    this.blockedRecipeIds = const {},
  });

  static const _unset = Object();

  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final Goal goal;
  final Pace pace;
  final int mealsPerDay;
  final Set<Allergen> excludedAllergens;
  final Set<String> dislikedIngredientIds;
  final int? maxCookMinutes;
  final int? dailyBudgetRub;
  final Set<String> preferredRecipeIds;
  final Set<String> blockedRecipeIds;

  UserProfile copyWith({
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    Goal? goal,
    Pace? pace,
    int? mealsPerDay,
    Set<Allergen>? excludedAllergens,
    Set<String>? dislikedIngredientIds,
    Object? maxCookMinutes = _unset,
    Object? dailyBudgetRub = _unset,
    Set<String>? preferredRecipeIds,
    Set<String>? blockedRecipeIds,
  }) {
    return UserProfile(
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      pace: pace ?? this.pace,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      excludedAllergens: excludedAllergens ?? this.excludedAllergens,
      dislikedIngredientIds:
          dislikedIngredientIds ?? this.dislikedIngredientIds,
      maxCookMinutes: identical(maxCookMinutes, _unset)
          ? this.maxCookMinutes
          : maxCookMinutes as int?,
      dailyBudgetRub: identical(dailyBudgetRub, _unset)
          ? this.dailyBudgetRub
          : dailyBudgetRub as int?,
      preferredRecipeIds: preferredRecipeIds ?? this.preferredRecipeIds,
      blockedRecipeIds: blockedRecipeIds ?? this.blockedRecipeIds,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'sex': sex.name,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activity': activity.name,
      'goal': goal.name,
      'pace': pace.name,
      'mealsPerDay': mealsPerDay,
      'excludedAllergens': excludedAllergens.map((item) => item.name).toList(),
      'dislikedIngredientIds': dislikedIngredientIds.toList(),
      'maxCookMinutes': maxCookMinutes,
      'dailyBudgetRub': dailyBudgetRub,
      'preferredRecipeIds': preferredRecipeIds.toList(),
      'blockedRecipeIds': blockedRecipeIds.toList(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      sex: _sexFromName(json['sex']),
      age: _intValue(json['age'], 30),
      heightCm: _doubleValue(json['heightCm'], 175),
      weightKg: _doubleValue(json['weightKg'], 75),
      activity: _activityFromName(json['activity']),
      goal: _goalFromName(json['goal']),
      pace: _paceFromName(json['pace']),
      mealsPerDay: _intValue(json['mealsPerDay'], 4),
      excludedAllergens: _allergensFromJson(json['excludedAllergens']),
      dislikedIngredientIds: _stringsFromJson(json['dislikedIngredientIds']),
      maxCookMinutes: _nullableInt(json['maxCookMinutes']),
      dailyBudgetRub: _nullableInt(json['dailyBudgetRub']),
      preferredRecipeIds: _stringsFromJson(json['preferredRecipeIds']),
      blockedRecipeIds: _stringsFromJson(json['blockedRecipeIds']),
    );
  }
}

int _intValue(Object? value, int fallback) {
  return value is num ? value.toInt() : fallback;
}

double _doubleValue(Object? value, double fallback) {
  return value is num ? value.toDouble() : fallback;
}

int? _nullableInt(Object? value) {
  return value is num ? value.toInt() : null;
}

Sex _sexFromName(Object? name) {
  return Sex.values.firstWhere(
    (value) => value.name == name,
    orElse: () => Sex.male,
  );
}

ActivityLevel _activityFromName(Object? name) {
  return ActivityLevel.values.firstWhere(
    (value) => value.name == name,
    orElse: () => ActivityLevel.moderate,
  );
}

Goal _goalFromName(Object? name) {
  return Goal.values.firstWhere(
    (value) => value.name == name,
    orElse: () => Goal.lose,
  );
}

Pace _paceFromName(Object? name) {
  return Pace.values.firstWhere(
    (value) => value.name == name,
    orElse: () => Pace.medium,
  );
}

Set<Allergen> _allergensFromJson(Object? raw) {
  final result = <Allergen>{};
  if (raw is List) {
    for (final item in raw) {
      for (final allergen in Allergen.values) {
        if (allergen.name == item) {
          result.add(allergen);
        }
      }
    }
  }
  return result;
}

Set<String> _stringsFromJson(Object? raw) {
  if (raw is List) {
    return raw.whereType<String>().toSet();
  }
  return {};
}
