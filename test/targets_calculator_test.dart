import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/user_profile.dart';
import 'package:norma/core/nutrition/targets_calculator.dart';

void main() {
  const calculator = TargetsCalculator();

  UserProfile profile({
    Sex sex = Sex.male,
    Goal goal = Goal.maintain,
    Pace pace = Pace.medium,
    double weight = 80,
  }) {
    return UserProfile(
      sex: sex,
      age: 30,
      heightCm: 180,
      weightKg: weight,
      activity: ActivityLevel.moderate,
      goal: goal,
      pace: pace,
    );
  }

  test('BMR и TDEE считаются по Миффлину-Сент-Джору', () {
    final targets = calculator.calculate(profile());
    expect(targets.bmr, closeTo(1780, 0.1));
    expect(targets.tdee, closeTo(2759, 0.1));
    expect(targets.nutrients.calories, closeTo(2759, 1));
  });

  test('похудение создаёт дефицит и повышает белок', () {
    final targets = calculator.calculate(profile(goal: Goal.lose));
    expect(targets.nutrients.calories, lessThan(targets.tdee));
    expect(targets.nutrients.protein, closeTo(144, 0.1));
  });

  test('калорийность сходится с макросами', () {
    final targets = calculator.calculate(profile(goal: Goal.gain));
    final fromMacros =
        targets.nutrients.protein * 4 +
        targets.nutrients.fat * 9 +
        targets.nutrients.carbs * 4;
    expect(targets.nutrients.calories, closeTo(fromMacros, 0.001));
  });

  test('калорийность не опускается ниже безопасного минимума', () {
    final targets = calculator.calculate(
      const UserProfile(
        sex: Sex.female,
        age: 60,
        heightCm: 150,
        weightKg: 45,
        activity: ActivityLevel.sedentary,
        goal: Goal.lose,
        pace: Pace.fast,
        mealsPerDay: 3,
      ),
    );
    expect(targets.nutrients.calories, greaterThanOrEqualTo(1200));
  });
}
