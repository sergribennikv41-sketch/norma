import 'package:flutter/material.dart';

import '../../core/data/recipe_repository.dart';
import '../../core/models/nutrients.dart';

void showRecipeDetails(
  BuildContext context, {
  required String title,
  required Nutrients nutrients,
  required double cost,
  required Map<String, double> ingredientGrams,
  required List<String> steps,
  required RecipeRepository repository,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${nutrients.calories.round()} ккал · '
                  'Б ${nutrients.protein.round()} · '
                  'Ж ${nutrients.fat.round()} · '
                  'У ${nutrients.carbs.round()} · '
                  '~${cost.round()} ₽',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ингредиенты',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                for (final entry in ingredientGrams.entries)
                  Text(
                    '• ${repository.ingredientById(entry.key)?.name ?? entry.key} — '
                    '${entry.value.round()} г',
                  ),
                const SizedBox(height: 16),
                Text(
                  'Приготовление',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                for (var index = 0; index < steps.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${index + 1}. ${steps[index]}'),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      );
    },
  );
}
