import 'package:flutter/material.dart';

import '../../core/data/recipe_repository.dart';
import '../../core/models/enums.dart';
import '../../core/models/meal_plan.dart';
import '../../core/models/recipe.dart';
import '../shared/recipe_details.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipes = widget.repository.recipes.where((recipe) {
      final matchesQuery =
          _query.isEmpty ||
          recipe.title.toLowerCase().contains(_query.toLowerCase());
      final matchesType =
          _mealType == null || recipe.mealTypes.contains(_mealType);
      return matchesQuery && matchesType;
    }).toList()..sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      appBar: AppBar(title: const Text('Каталог рецептов')),
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
                      hintText: 'Поиск по названию',
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
                  child: Text(
                    'Найдено: ${recipes.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: recipes.isEmpty
                      ? const Center(child: Text('Ничего не найдено'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: recipes.length,
                          itemBuilder: (context, index) {
                            final recipe = recipes[index];
                            final nutrients = widget.repository
                                .nutrientsPerServing(recipe);
                            final cost = widget.repository.costPerServing(
                              recipe,
                            );
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(recipe.title),
                                subtitle: Text(
                                  '${recipe.mealTypes.map((type) => type.label).join(' · ')} · '
                                  '${recipe.minutes} мин · '
                                  '${nutrients.calories.round()} ккал · '
                                  'Б ${nutrients.protein.round()}',
                                ),
                                trailing: Text('~${cost.round()} ₽'),
                                onTap: () => showRecipeDetails(
                                  context,
                                  title: recipe.title,
                                  nutrients: nutrients,
                                  cost: cost,
                                  ingredientGrams: {
                                    for (final item in recipe.ingredients)
                                      item.ingredientId: item.grams,
                                  },
                                  steps: recipe.steps,
                                  repository: widget.repository,
                                  onAddToPlan: widget.plan == null
                                      ? null
                                      : () => _addToPlan(recipe),
                                ),
                              ),
                            );
                          },
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
