import 'enums.dart';
import 'nutrients.dart';

class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.per100g,
    this.allergens = const {},
  });

  final String id;
  final String name;
  final String category;
  final Nutrients per100g;
  final Set<Allergen> allergens;

  Nutrients nutrientsFor(double grams) => per100g * (grams / 100);
}
