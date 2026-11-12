import 'package:flutter/material.dart';

import '../../core/data/recipe_repository.dart';
import '../../core/models/enums.dart';
import '../../core/models/ingredient.dart';
import '../../core/models/meal_plan.dart';
import '../../core/models/recipe.dart';
import '../shared/recipe_details.dart';
import '../shared/recipe_image.dart';
import '../shared/theme_mode_button.dart';

class CatalogPick {
  const CatalogPick({
    required this.recipeId,
    required this.dayIndex,
    required this.mealIndex,
  });

  final String recipeId;
  final int dayIndex;
  final int mealIndex;
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.repository, this.plan});

  final RecipeRepository repository;
  final WeeklyPlan? plan;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  MealType? _mealType;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addToPlan(Recipe recipe) async {
    final plan = widget.plan;
    if (plan == null) {
      return;
    }
    final choice = await _pickSlot(recipe, plan);
    if (choice == null || !mounted) {
      return;
    }
    Navigator.of(context).pop(
      CatalogPick(
        recipeId: recipe.id,
        dayIndex: choice.dayIndex,
        mealIndex: choice.mealIndex,
      ),
    );
  }

  Future<({int dayIndex, int mealIndex})?> _pickSlot(
    Recipe recipe,
    WeeklyPlan plan,
  ) async {
    var dayIndex = 0;
    final initialIndexes = _compatibleMealIndexes(recipe, plan.days[dayIndex]);
    if (initialIndexes.isEmpty) {
      _showMessage('Нет подходящего приёма пищи');
      return null;
    }
    var mealIndex = initialIndexes.first;

    return showDialog<({int dayIndex, int mealIndex})>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final day = plan.days[dayIndex];
            final indexes = _compatibleMealIndexes(recipe, day);
            if (!indexes.contains(mealIndex)) {
              mealIndex = indexes.first;
            }
            return AlertDialog(
              title: Text('Добавить «${recipe.title}»'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: dayIndex,
                    isExpanded: true,
                    items: [
                      for (var index = 0; index < plan.days.length; index++)
                        DropdownMenuItem<int>(
                          value: index,
                          child: Text('День ${index + 1}'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() {
                        dayIndex = value;
                        mealIndex = _compatibleMealIndexes(
                          recipe,
                          plan.days[dayIndex],
                        ).first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<int>(
                    value: mealIndex,
                    isExpanded: true,
                    items: [
                      for (final index in indexes)
                        DropdownMenuItem<int>(
                          value: index,
                          child: Text(
                            '${day.meals[index].type.label} · '
                            '${day.meals[index].nutrients.calories.round()} ккал',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => mealIndex = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext)
                          .pop((dayIndex: dayIndex, mealIndex: mealIndex)),
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<int> _compatibleMealIndexes(Recipe recipe, DayPlan day) {
    return [
      for (var index = 0; index < day.meals.length; index++)
        if (recipe.mealTypes.contains(day.meals[index].type)) index,
    ];
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openRecipe(Recipe recipe) {
    final nutrients = widget.repository.nutrientsPerServing(recipe);
    showRecipeDetails(
      context,
      title: recipe.title,
      nutrients: nutrients,
      ingredientGrams: {
        for (final item in recipe.ingredients) item.ingredientId: item.grams,
      },
      steps: recipe.steps,
      repository: widget.repository,
      image: recipe.image,
      source: recipe.source,
      mealType: recipe.mealTypes.isEmpty ? null : recipe.mealTypes.first,
      minutes: recipe.minutes,
      servings: recipe.servings,
      onAddToPlan: widget.plan == null ? null : () => _addToPlan(recipe),
    );
  }

  Widget _recipeTile({
    required Recipe recipe,
    required String query,
    Ingredient? containsIngredient,
  }) {
    final theme = Theme.of(context);
    final nutrients = widget.repository.nutrientsPerServing(recipe);
    final details =
        '${recipe.mealTypes.map((type) => type.label).join(' · ')} · '
        '${recipe.minutes} мин · '
        '${nutrients.calories.round()} ккал · '
        'Б ${nutrients.protein.round()}';
    return ListTile(
      leading: RecipeImage(
        image: recipe.image,
        mealType: recipe.mealTypes.isEmpty ? null : recipe.mealTypes.first,
        width: 56,
        height: 56,
        borderRadius: 10,
        label: recipe.title,
      ),
      title: Text(recipe.title),
      subtitle: containsIngredient == null
          ? Text(details)
          : _HighlightedText(
              text: 'Содержит: ${containsIngredient.name} · $details',
              query: query,
              style: theme.textTheme.bodyMedium,
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openRecipe(recipe),
    );
  }

  Widget _dishCard(Recipe recipe, String query) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: _recipeTile(recipe: recipe, query: query),
    );
  }

  Widget _productCard(
    ({Ingredient ingredient, List<Recipe> recipes}) entry,
    String query,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.shopping_basket_outlined),
        title: _HighlightedText(
          text: entry.ingredient.name,
          query: query,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${entry.recipes.length} ${_plural(entry.recipes.length, 'блюдо', 'блюда', 'блюд')}',
        ),
        children: [
          for (final recipe in entry.recipes)
            _recipeTile(
              recipe: recipe,
              query: query,
              containsIngredient: entry.ingredient,
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _normalize(_query.trim());
    final filteredRecipes = widget.repository.recipes.where((recipe) {
      return _mealType == null || recipe.mealTypes.contains(_mealType);
    }).toList()..sort((a, b) => a.title.compareTo(b.title));

    final dishMatches = query.isEmpty
        ? filteredRecipes
        : filteredRecipes
              .where((recipe) => _normalize(recipe.title).contains(query))
              .toList();

    final productMatches = <({Ingredient ingredient, List<Recipe> recipes})>[];
    if (query.isNotEmpty) {
      final ingredients =
          widget.repository.ingredients
              .where(
                (ingredient) => _normalize(ingredient.name).contains(query),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      for (final ingredient in ingredients) {
        final recipes =
            filteredRecipes
                .where(
                  (recipe) => recipe.ingredients.any(
                    (item) => item.ingredientId == ingredient.id,
                  ),
                )
                .toList()
              ..sort((a, b) => a.title.compareTo(b.title));
        if (recipes.isNotEmpty) {
          productMatches.add((ingredient: ingredient, recipes: recipes));
        }
      }
    }

    final hasResults = dishMatches.isNotEmpty || productMatches.isNotEmpty;
    final summary = query.isEmpty
        ? 'Найдено: ${filteredRecipes.length}'
        : 'Найдено: ${dishMatches.length} ${_plural(dishMatches.length, 'блюдо', 'блюда', 'блюд')} · '
              '${productMatches.length} ${_plural(productMatches.length, 'продукт', 'продукта', 'продуктов')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог рецептов'),
        actions: const [ThemeModeButton()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Поиск по блюду или продукту',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _query = value.trim());
                    },
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (final type in <MealType?>[null, ...MealType.values])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type?.label ?? 'Все'),
                            selected: _mealType == type,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _mealType = type);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(summary, style: theme.textTheme.bodySmall),
                ),
                Expanded(
                  child: !hasResults
                      ? const Center(child: Text('Ничего не найдено'))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            if (query.isNotEmpty && dishMatches.isNotEmpty) ...[
                              _sectionTitle('Блюда'),
                              for (final recipe in dishMatches)
                                _dishCard(recipe, ''),
                            ],
                            if (query.isNotEmpty &&
                                productMatches.isNotEmpty) ...[
                              if (dishMatches.isNotEmpty)
                                const SizedBox(height: 12),
                              _sectionTitle('Продукты'),
                              for (final entry in productMatches)
                                _productCard(entry, query),
                            ],
                            if (query.isEmpty)
                              for (final recipe in dishMatches)
                                _dishCard(recipe, ''),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll('ё', 'е');
}

String _plural(int count, String one, String few, String many) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) {
    return one;
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return few;
  }
  return many;
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.query, this.style});

  final String text;
  final String query;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final lowerText = _normalize(text);
    final lowerQuery = _normalize(query.trim());
    if (lowerQuery.isEmpty || !lowerText.contains(lowerQuery)) {
      return Text(text, style: style);
    }

    final spans = <TextSpan>[];
    var start = 0;
    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + lowerQuery.length),
          style: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + lowerQuery.length;
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }
}
