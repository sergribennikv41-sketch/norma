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

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'per100g': per100g.toJson(),
      'allergens': [for (final allergen in allergens) allergen.name],
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] is String ? json['id'] as String : '',
      name: json['name'] is String ? json['name'] as String : '',
      category: json['category'] is String ? json['category'] as String : '',
      per100g: json['per100g'] is Map
          ? Nutrients.fromJson(
              Map<String, dynamic>.from(json['per100g'] as Map),
            )
          : Nutrients.zero,
      allergens: _allergensFromJson(json['allergens']),
    );
  }
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
