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
  String? fallbackImage,
  MealType? mealType,
  Set<MealType> suitableFor = const {},
  int? minutes,
  int? servings,
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
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final theme = Theme.of(dialogContext);
          final scheme = theme.colorScheme;
          final currentNutrients = baseNutrients * scale;
          final meta = [
            if (mealType != null) mealType.label,
            if (minutes != null) '$minutes мин',
            if (servings != null) '$servings порции',
          ].join(' · ');

          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecipeImage(
                image: image,
                fallbackImage: fallbackImage,
                mealType: mealType,
                height: 300,
                borderRadius: 20,
                label: title,
                cacheWidth: 800,
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Ингредиенты',
                trailing: servings == null ? null : 'на $servings порции',
                child: Column(
                  children: [
                    for (final entry in baseGrams.entries)
                      _IngredientRow(
                        name:
                            repository.ingredientById(entry.key)?.name ??
                            entry.key,
                        grams: (entry.value * scale).round(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Приготовление',
                trailing: '${steps.length} шагов',
                child: Column(
                  children: [
                    for (var index = 0; index < steps.length; index++)
                      _StepRow(number: index + 1, text: steps[index]),
                  ],
                ),
              ),
            ],
          );

          final right = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: 'КБЖУ',
                trailing: 'на порцию',
                child: Column(
                  children: [
                    Row(
                      children: [
                        _MacroBox(
                          label: 'Белки',
                          value: '${currentNutrients.protein.round()} г',
                        ),
                        const SizedBox(width: 8),
                        _MacroBox(
                          label: 'Жиры',
                          value: '${currentNutrients.fat.round()} г',
                        ),
                        const SizedBox(width: 8),
                        _MacroBox(
                          label: 'Углеводы',
                          value: '${currentNutrients.carbs.round()} г',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${currentNutrients.calories.round()} ккал',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${(scale * 100).round()}%',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (allowScaleEdit) ...[
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
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  _openLink(context, pinterestVideoSearchUri(title));
                },
                icon: const Icon(Icons.play_circle_outline, size: 17),
                label: const Text('Видео в Pinterest'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Стоимость появится в списке покупок после live-поиска '
                  'по выбранному магазину. Норма — ориентир, а не медицинская '
                  'рекомендация.',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );

          return Dialog(
            insetPadding: const EdgeInsets.all(24),
            backgroundColor: scheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1100,
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: theme.textTheme.headlineSmall),
                              if (meta.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  meta,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (suitableFor.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Подходит: ${_mealTypesLabel(suitableFor)}',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          tooltip: 'Закрыть',
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 800) {
                          return Column(
                            children: [left, const SizedBox(height: 14), right],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 115, child: left),
                            const SizedBox(width: 22),
                            Expanded(flex: 85, child: right),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (onAddToPlan != null)
                          FilledButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              onAddToPlan();
                            },
                            child: const Text('В рацион'),
                          ),
                        if (allowScaleEdit)
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(scale),
                            child: const Text('Применить'),
                          ),
                        OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Закрыть'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.name, required this.grams});

  final String name;
  final int grams;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Text(
            '$grams г',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBox extends StatelessWidget {
  const _MacroBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openLink(BuildContext context, Uri uri) async {
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Не удалось открыть ссылку')));
  }
}

String _mealTypesLabel(Set<MealType> types) {
  final ordered = [
    for (final type in MealType.values)
      if (types.contains(type)) type.label,
  ];
  return ordered.join(', ');
}
