import 'dart:math';

import '../models/daily_targets.dart';
import '../models/enums.dart';
import '../models/nutrients.dart';
import '../models/user_profile.dart';

class TargetsCalculator {
  const TargetsCalculator();

  DailyTargets calculate(UserProfile profile) {
    final sexOffset = profile.sex == Sex.male ? 5.0 : -161.0;
    final bmr =
        10 * profile.weightKg +
        6.25 * profile.heightCm -
        5 * profile.age +
        sexOffset;
    final tdee = bmr * profile.activity.factor;

    final adjustment = switch (profile.goal) {
      Goal.maintain => 0.0,
      Goal.lose => switch (profile.pace) {
        Pace.slow => -0.10,
        Pace.medium => -0.18,
        Pace.fast => -0.25,
      },
      Goal.gain => switch (profile.pace) {
        Pace.slow => 0.05,
        Pace.medium => 0.10,
        Pace.fast => 0.15,
      },
    };

    var calories = tdee * (1 + adjustment);
    if (profile.goal == Goal.lose) {
      final floor = profile.sex == Sex.male ? 1500.0 : 1200.0;
      calories = max(calories, floor);
    }

    final proteinPerKg = switch (profile.goal) {
      Goal.lose => 1.8,
      Goal.maintain => 1.6,
      Goal.gain => 1.8,
    };
    final protein = profile.weightKg * proteinPerKg;
    var fat = profile.weightKg * 0.9;
    var carbs = (calories - protein * 4 - fat * 9) / 4;

    if (carbs < 50) {
      carbs = 50;
      final fatCalories = calories - protein * 4 - carbs * 4;
      fat = max(profile.weightKg * 0.6, fatCalories / 9);
    }

    final nutrients = Nutrients(
      calories: protein * 4 + fat * 9 + carbs * 4,
      protein: protein,
      fat: fat,
      carbs: carbs,
    );

    return DailyTargets(bmr: bmr, tdee: tdee, nutrients: nutrients);
  }
}
