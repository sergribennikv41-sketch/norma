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

  Map<String, Object?> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
    };
  }

  factory Nutrients.fromJson(Map<String, dynamic> json) {
    return Nutrients(
      calories: _doubleValue(json['calories']),
      protein: _doubleValue(json['protein']),
      fat: _doubleValue(json['fat']),
      carbs: _doubleValue(json['carbs']),
    );
  }
}

double _doubleValue(Object? value) {
  return value is num ? value.toDouble() : 0;
}
