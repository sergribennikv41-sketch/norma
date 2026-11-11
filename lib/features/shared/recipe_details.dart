import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/recipe_repository.dart';
import '../../core/models/enums.dart';
import '../../core/models/nutrients.dart';
import 'recipe_image.dart';
import 'recipe_links.dart';

Future<double?> showRecipeDetails(
  BuildContext context, {
  required String title,
  required Nutrients nutrients,
  required Map<String, double> ingredientGrams,
  required List<String> steps,
  required RecipeRepository repository,
  String? image,
  String? source,
  MealType? mealType,
  bool allowScaleEdit = false,
  double initialScale = 1,
  VoidCallback? onAddToPlan,
}) {
  final safeScale = initialScale > 0 ? initialScale : 1.0;
  final baseNutrients = nutrients * (1 / safeScale);
  final baseGrams = {
    for (final entry in ingredientGrams.entries)
      entry.key: entry.value / safeScale,
  };
  var scale = safeScale;

  return showDialog<double>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final theme = Theme.of(dialogContext);
          final currentNutrients = baseNutrients * scale;
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (image != null && image.isNotEmpty) ...[
                      RecipeImage(
                        image: image,
                        mealType: mealType,
                        height: 180,
                        borderRadius: 12,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      '${currentNutrients.calories.round()} ккал · '
                      'Б ${currentNutrients.protein.round()} · '
                      'Ж ${currentNutrients.fat.round()} · '
                      'У ${currentNutrients.carbs.round()}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (allowScaleEdit) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Порция: ${(scale * 100).round()}%',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: scale,
                        min: 0.5,
                        max: 1.5,
                        divisions: 20,
                        label: '${(scale * 100).round()}%',
                        onChanged: (value) {
                          setDialogState(() => scale = value);
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Ингредиенты',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final entry in baseGrams.entries)
                      Text(
                        '• ${repository.ingredientById(entry.key)?.name ?? entry.key} — '
                        '${(entry.value * scale).round()} г',
                      ),
                    if (source != null && source.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Источник: $source',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(
                            Icons.play_circle_outline,
                            size: 18,
                          ),
                          label: const Text('Видео в Pinterest'),
                          onPressed: () {
                            _openLink(context, pinterestVideoSearchUri(title));
                          },
                        ),
                      ],
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
              if (onAddToPlan != null)
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onAddToPlan();
                  },
                  child: const Text('В рацион'),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Закрыть'),
              ),
              if (allowScaleEdit)
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(scale),
                  child: const Text('Применить'),
                ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _openLink(BuildContext context, Uri uri) async {
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Не удалось открыть ссылку')));
  }
}
