class Nutrients {
  const Nutrients({
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
  });

  static const zero = Nutrients();

  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  Nutrients operator +(Nutrients other) {
    return Nutrients(
      calories: calories + other.calories,
      protein: protein + other.protein,
      fat: fat + other.fat,
      carbs: carbs + other.carbs,
    );
  }

  Nutrients operator *(double factor) {
    return Nutrients(
      calories: calories * factor,
      protein: protein * factor,
      fat: fat * factor,
      carbs: carbs * factor,
    );
  }
}
