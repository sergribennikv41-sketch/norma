import 'package:flutter/material.dart';

import '../../core/data/recipe_repository.dart';
import '../../core/models/enums.dart';
import '../shared/recipe_details.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.repository});

  final RecipeRepository repository;

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
