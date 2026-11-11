import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/models/ingredient.dart';
import 'package:norma/core/models/meal_plan.dart';
import 'package:norma/core/models/nutrients.dart';
import 'package:norma/core/planner/shopping_list_text.dart';

void main() {
  test('формирует текст списка покупок по категориям', () {
    const chicken = Ingredient(
      id: 'chicken',
      name: 'Куриная грудка',
      category: 'Мясо и птица',
      per100g: Nutrients(calories: 96),
    );
    const tomato = Ingredient(
      id: 'tomato',
      name: 'Помидор',
      category: 'Овощи',
      per100g: Nutrients(calories: 20),
    );
    final text = buildShoppingListText([
      const ShoppingItem(ingredient: chicken, grams: 500),
      const ShoppingItem(ingredient: tomato, grams: 250),
    ]);

    expect(text, startsWith('Список покупок'));
    expect(text, contains('МЯСО И ПТИЦА:'));
    expect(text, contains('- Куриная грудка: 500 г'));
    expect(text, contains('ОВОЩИ:'));
    expect(text, contains('- Помидор: 250 г'));
  });
}
