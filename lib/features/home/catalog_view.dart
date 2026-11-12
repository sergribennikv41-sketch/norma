import 'package:flutter/material.dart';

import '../../core/data/recipe_repository.dart';
import '../../core/models/enums.dart';
import '../../core/models/ingredient.dart';
import '../../core/models/recipe.dart';
import '../../core/models/user_profile.dart';
import '../shared/recipe_image.dart';
import '../shared/theme_mode_button.dart';
import 'home_widgets.dart';

class CatalogView extends StatefulWidget {
  const CatalogView({
    super.key,
    required this.repository,
    required this.profile,
    required this.onOpenRecipe,
    required this.onOpenShopping,
  });

  final RecipeRepository repository;
  final UserProfile profile;
  final ValueChanged<Recipe> onOpenRecipe;
  final VoidCallback onOpenShopping;

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
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
    final query = normalizeSearch(_query.trim());
    final filtered = widget.repository.recipes.where((recipe) {
      return _mealType == null || recipe.mealTypes.contains(_mealType);
    }).toList()..sort((a, b) => a.title.compareTo(b.title));

    final dishMatches = query.isEmpty
        ? filtered
        : filtered
              .where((recipe) => normalizeSearch(recipe.title).contains(query))
              .toList();

    final productMatches = <({Ingredient ingredient, List<Recipe> recipes})>[];
    if (query.isNotEmpty) {
      final ingredients =
          widget.repository.ingredients
              .where(
                (ingredient) =>
                    normalizeSearch(ingredient.name).contains(query),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      for (final ingredient in ingredients) {
        final recipes =
            filtered
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

    final productDishIds = <String>{
      for (final match in productMatches)
        for (final recipe in match.recipes) recipe.id,
    };
    final standaloneDishes = dishMatches
        .where((recipe) => !productDishIds.contains(recipe.id))
        .toList();

    final compact = MediaQuery.sizeOf(context).width < 600;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final baseSide = compact ? 16.0 : 32.0;
    final side = screenWidth > 1400
        ? (screenWidth - 1400) / 2 + baseSide
        : baseSide;
    final horizontal = EdgeInsets.symmetric(horizontal: side);

    Widget box(Widget child) {
      return SliverPadding(
        padding: horizontal,
        sliver: SliverToBoxAdapter(child: child),
      );
    }

    Widget grid(List<Recipe> recipes) {
      return SliverPadding(
        padding: horizontal,
        sliver: _RecipeSliverGrid(
          recipes: recipes,
          query: _query,
          onOpenRecipe: widget.onOpenRecipe,
        ),
      );
    }

    final slivers = <Widget>[
      SliverPadding(
        padding: EdgeInsets.fromLTRB(side, compact ? 20 : 28, side, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopbar(context),
              const SizedBox(height: 22),
              _buildSearch(context),
              const SizedBox(height: 12),
              _buildFilters(),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 22)),
    ];

    if (query.isEmpty) {
      slivers.add(
        box(
          _SectionHead(
            title: 'Все рецепты',
            subtitle:
                '${filtered.length} '
                '${pluralRu(filtered.length, 'блюдо', 'блюда', 'блюд')}',
          ),
        ),
      );
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 10)));
      slivers.add(filtered.isEmpty ? box(const _EmptyState()) : grid(filtered));
    } else {
      if (productMatches.isNotEmpty) {
        slivers.add(
          box(
            _SectionHead(
              title: 'Продукты',
              subtitle:
                  '${productMatches.length} '
                  '${pluralRu(productMatches.length, 'продукт', 'продукта', 'продуктов')}',
            ),
          ),
        );
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 10)));
        for (final match in productMatches) {
          slivers.add(
            box(
              _ProductCard(
                ingredient: match.ingredient,
                recipes: match.recipes,
                query: _query,
              ),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
          slivers.add(
            box(
              _SectionHead(
                title: 'Блюда с этим продуктом',
                subtitle:
                    '${match.recipes.length} '
                    '${pluralRu(match.recipes.length, 'блюдо', 'блюда', 'блюд')}',
              ),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 10)));
          slivers.add(grid(match.recipes));
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 18)));
        }
      }
      if (standaloneDishes.isNotEmpty) {
        slivers.add(
          box(
            _SectionHead(
              title: 'Блюда',
              subtitle:
                  '${standaloneDishes.length} '
                  '${pluralRu(standaloneDishes.length, 'блюдо', 'блюда', 'блюд')}',
            ),
          ),
        );
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 10)));
        slivers.add(grid(standaloneDishes));
      }
      if (productMatches.isEmpty && standaloneDishes.isEmpty) {
        slivers.add(box(const _EmptyState()));
      }
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 18)));
      slivers.add(
        box(
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Если блюда нет в каталоге по названию, попробуйте найти '
              'продукт. Например, «курица» покажет блюда, где она есть.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    slivers.add(SliverToBoxAdapter(child: SizedBox(height: compact ? 32 : 42)));
    return CustomScrollView(slivers: slivers);
  }

  Widget _buildTopbar(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'БИБЛИОТЕКА',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text('Каталог', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              '${widget.repository.recipes.length} рецептов из Викиучебника · '
              '${widget.repository.ingredients.length} ингредиентов',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StoreChip(profile: widget.profile),
            if (MediaQuery.sizeOf(context).width < 820) const ThemeModeButton(),
            OutlinedButton(
              onPressed: widget.onOpenShopping,
              child: const Text('Список покупок'),
            ),
          ],
        );
        if (constraints.maxWidth < 780) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildSearch(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 5, 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Поиск по блюду или продукту',
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _query = value.trim());
              },
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              tooltip: 'Очистить поиск',
              icon: const Icon(Icons.close, size: 17),
            ),
          FilledButton(
            onPressed: () => FocusScope.of(context).unfocus(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(68, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Все',
            selected: _mealType == null,
            onTap: () => setState(() => _mealType = null),
          ),
          for (final type in MealType.values) ...[
            const SizedBox(width: 7),
            _FilterChip(
              label: type.label,
              selected: _mealType == type,
              onTap: () => setState(() => _mealType = type),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Unbounded',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.transparent : scheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.ingredient,
    required this.recipes,
    required this.query,
  });

  final Ingredient ingredient;
  final List<Recipe> recipes;
  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.eco_outlined,
              size: 19,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HighlightedText(
                  text: ingredient.name,
                  query: query,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${ingredient.category} · '
                  '${recipes.length} '
                  '${pluralRu(recipes.length, 'блюдо', 'блюда', 'блюд')}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeSliverGrid extends StatelessWidget {
  const _RecipeSliverGrid({
    required this.recipes,
    required this.query,
    required this.onOpenRecipe,
  });

  final List<Recipe> recipes;
  final String query;
  final ValueChanged<Recipe> onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.crossAxisExtent >= 1080
            ? 4
            : constraints.crossAxisExtent >= 760
            ? 3
            : constraints.crossAxisExtent >= 480
            ? 2
            : 1;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 200,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final recipe = recipes[index];
            return _RecipeCard(
              recipe: recipe,
              query: query,
              onTap: () => onOpenRecipe(recipe),
            );
          }, childCount: recipes.length),
        );
      },
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.query,
    required this.onTap,
  });

  final Recipe recipe;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecipeImage(
                image: recipe.image,
                mealType: recipe.mealTypes.isEmpty
                    ? null
                    : recipe.mealTypes.first,
                height: 118,
                label: recipe.title,
                borderRadius: 15,
                cacheWidth: 400,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightedText(
                      text: recipe.title,
                      query: query,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recipe.mealTypes.map((type) => type.label).join(' · ')}'
                      ' · ${recipe.minutes} мин',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 36, color: scheme.outline),
          const SizedBox(height: 10),
          Text(
            'Ничего не найдено',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Попробуйте другое название блюда или продукта.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
