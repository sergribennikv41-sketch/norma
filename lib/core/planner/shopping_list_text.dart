import '../models/meal_plan.dart';

String buildShoppingListText(List<ShoppingItem> items) {
  final buffer = StringBuffer('Список покупок\n\n');
  String? category;
  for (final item in items) {
    if (item.ingredient.category != category) {
      category = item.ingredient.category;
      buffer.writeln('${category.toUpperCase()}:');
    }
    buffer.writeln('- ${item.ingredient.name}: ${item.grams.round()} г');
  }
  return buffer.toString().trimRight();
}
