enum Sex {
  male('Мужской'),
  female('Женский');

  const Sex(this.label);

  final String label;
}

enum ActivityLevel {
  sedentary('Минимальная', 1.2),
  light('Легкая', 1.375),
  moderate('Средняя', 1.55),
  high('Высокая', 1.725),
  veryHigh('Очень высокая', 1.9);

  const ActivityLevel(this.label, this.factor);

  final String label;
  final double factor;
}

enum Goal {
  lose('Похудение'),
  maintain('Поддержание'),
  gain('Набор массы');

  const Goal(this.label);

  final String label;
}

enum Pace {
  slow('Спокойный'),
  medium('Средний'),
  fast('Быстрый');

  const Pace(this.label);

  final String label;
}

enum MealType {
  breakfast('Завтрак'),
  lunch('Обед'),
  dinner('Ужин'),
  snack('Перекус');

  const MealType(this.label);

  final String label;
}

enum Allergen {
  gluten('Глютен'),
  lactose('Лактоза'),
  nuts('Орехи'),
  eggs('Яйца'),
  fish('Рыба'),
  seafood('Морепродукты');

  const Allergen(this.label);

  final String label;
}
