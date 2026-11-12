import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/data/recipe_repository.dart';
import '../../core/models/meal_plan.dart';
import '../../core/models/recipe.dart';
import '../../core/models/retail.dart';
import '../../core/models/user_profile.dart';
import '../shared/recipe_image.dart';
import 'home_widgets.dart';

class PlanView extends StatelessWidget {
  const PlanView({
    super.key,
    required this.plan,
    required this.profile,
    required this.repository,
    required this.selectedDayIndex,
    required this.onSelectDay,
    required this.onReplace,
    required this.onLike,
    required this.onBlock,
    required this.onOpenMeal,
    required this.onOpenShopping,
  });

  final WeeklyPlan plan;
  final UserProfile profile;
  final RecipeRepository repository;
  final int selectedDayIndex;
  final ValueChanged<int> onSelectDay;
  final void Function(int dayIndex, int mealIndex) onReplace;
  final ValueChanged<Recipe> onLike;
  final ValueChanged<Recipe> onBlock;
  final void Function(int dayIndex, int mealIndex) onOpenMeal;
  final VoidCallback onOpenShopping;

  @override
  Widget build(BuildContext context) {
    final dayIndex = selectedDayIndex.clamp(0, plan.days.length - 1);
    final day = plan.days[dayIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Topbar(profile: profile),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 940;
                  final left = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TargetsCard(plan: plan, day: day),
                      const SizedBox(height: 20),
                      _DayTabs(
                        days: plan.days.length,
                        selectedIndex: dayIndex,
                        onSelect: onSelectDay,
                      ),
                      const SizedBox(height: 14),
                      for (
                        var mealIndex = 0;
                        mealIndex < day.meals.length;
                        mealIndex++
                      ) ...[
                        _MealCard(
                          meal: day.meals[mealIndex],
                          repository: repository,
                          onTap: () => onOpenMeal(dayIndex, mealIndex),
                          onReplace: () => onReplace(dayIndex, mealIndex),
                          onLike: () => onLike(day.meals[mealIndex].recipe),
                          onBlock: () => onBlock(day.meals[mealIndex].recipe),
                        ),
                        const SizedBox(height: 9),
                      ],
                    ],
                  );
                  final right = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DaySummaryCard(day: day, onOpenShopping: onOpenShopping),
                      const SizedBox(height: 16),
                      _MiniShoppingCard(
                        plan: plan,
                        profile: profile,
                        onOpenShopping: onOpenShopping,
                      ),
                    ],
                  );
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [left, const SizedBox(height: 16), right],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 155, child: left),
                      const SizedBox(width: 22),
                      Expanded(flex: 85, child: right),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [StoreChip(profile: profile)],
        );
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ПЛАН НА НЕДЕЛЮ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text('Ваш рацион', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Сбалансировано под цель «${profile.goal.label}» · '
              '${profile.mealsPerDay} приёма пищи',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
}

class _TargetsCard extends StatelessWidget {
  const _TargetsCard({required this.plan, required this.day});

  final WeeklyPlan plan;
  final DayPlan day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final target = plan.targets.nutrients;
    final ratio = target.calories <= 0
        ? 0.0
        : day.totals.calories / target.calories;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          final ring = CalorieRing(
            value: ratio,
            label: '${target.calories.round()}',
            caption: 'ккал',
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Норма на день',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${ratio > 1 ? 'Выше' : '${(ratio * 100).round()}%'} от цели. '
                'Ужин чуть легче — так проще держать дефицит без голода.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  MacroTile(
                    label: 'Белки',
                    value: '${target.protein.round()} г',
                  ),
                  const SizedBox(width: 8),
                  MacroTile(label: 'Жиры', value: '${target.fat.round()} г'),
                  const SizedBox(width: 8),
                  MacroTile(
                    label: 'Углеводы',
                    value: '${target.carbs.round()} г',
                  ),
                ],
              ),
            ],
          );
          if (compact) {
            return Column(children: [ring, const SizedBox(height: 18), copy]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ring,
              const SizedBox(width: 22),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}

class _DayTabs extends StatelessWidget {
  const _DayTabs({
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 7.0;
        final available = constraints.maxWidth - gap * (days - 1);
        final width = available / days;
        final tabs = [
          for (var index = 0; index < days; index++) ...[
            _DayTab(
              weekday: _weekdays[index % _weekdays.length],
              day: index + 1,
              selected: index == selectedIndex,
              onTap: () => onSelect(index),
              width: width >= 62 ? null : 62,
            ),
            if (index != days - 1) const SizedBox(width: gap),
          ],
        ];
        if (width >= 62) {
          final scheme = Theme.of(context).colorScheme;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                left: selectedIndex * (width + gap),
                top: 0,
                bottom: 0,
                width: width,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primary.withValues(alpha: 0.90),
                              scheme.primary.withValues(alpha: 0.66),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.26),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var index = 0; index < days; index++) ...[
                    Expanded(
                      child: _DayTab(
                        weekday: _weekdays[index % _weekdays.length],
                        day: index + 1,
                        selected: index == selectedIndex,
                        onTap: () => onSelect(index),
                        filled: false,
                      ),
                    ),
                    if (index != days - 1) const SizedBox(width: gap),
                  ],
                ],
              ),
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: tabs),
        );
      },
    );
  }
}

class _DayTab extends StatelessWidget {
  const _DayTab({
    required this.weekday,
    required this.day,
    required this.selected,
    required this.onTap,
    this.width,
    this.filled = true,
  });

  final String weekday;
  final int day;
  final bool selected;
  final VoidCallback onTap;
  final double? width;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? (filled ? scheme.primary : Colors.transparent)
          : scheme.surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.transparent : scheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            children: [
              Text(
                weekday,
                style: TextStyle(
                  color: selected
                      ? scheme.onPrimary.withValues(alpha: 0.72)
                      : scheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$day',
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.repository,
    required this.onTap,
    required this.onReplace,
    required this.onLike,
    required this.onBlock,
  });

  final PlannedMeal meal;
  final RecipeRepository repository;
  final VoidCallback onTap;
  final VoidCallback onReplace;
  final VoidCallback onLike;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recipe = meal.recipe;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              RecipeImage(
                image: recipe.image,
                mealType: meal.type,
                width: 88,
                height: 72,
                borderRadius: 13,
                label: recipe.title,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${meal.type.label} · ${recipe.minutes} мин · '
                      '${(meal.scale * 100).round()}% порции\n'
                      '${_ingredientPreview(meal)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${meal.nutrients.calories.round()}',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'ккал',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PopupMenuButton<_MealAction>(
                    tooltip: 'Действия с блюдом',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_horiz,
                      size: 19,
                      color: scheme.onSurfaceVariant,
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _MealAction.replace:
                          onReplace();
                          break;
                        case _MealAction.like:
                          onLike();
                          break;
                        case _MealAction.block:
                          onBlock();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _MealAction.replace,
                        child: Text('Заменить блюдо'),
                      ),
                      PopupMenuItem(
                        value: _MealAction.like,
                        child: Text('Нравится'),
                      ),
                      PopupMenuItem(
                        value: _MealAction.block,
                        child: Text('Не предлагать'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ingredientPreview(PlannedMeal meal) {
    final names = meal.recipe.ingredients
        .take(3)
        .map(
          (item) =>
              repository.ingredientById(item.ingredientId)?.name ??
              item.ingredientId,
        )
        .toList();
    if (names.isEmpty) {
      return 'Без ингредиентов';
    }
    return names.join(', ');
  }
}

enum _MealAction { replace, like, block }

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({required this.day, required this.onOpenShopping});

  final DayPlan day;
  final VoidCallback onOpenShopping;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = day.totals;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'День ${day.index}',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    color: scheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              Text(
                '${totals.calories.round()} ккал',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryLine(label: 'Белки', value: '${totals.protein.round()} г'),
          _SummaryLine(label: 'Жиры', value: '${totals.fat.round()} г'),
          _SummaryLine(label: 'Углеводы', value: '${totals.carbs.round()} г'),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onOpenShopping,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
            child: const Text('Открыть покупки'),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniShoppingCard extends StatelessWidget {
  const _MiniShoppingCard({
    required this.plan,
    required this.profile,
    required this.onOpenShopping,
  });

  final WeeklyPlan plan;
  final UserProfile profile;
  final VoidCallback onOpenShopping;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in plan.shoppingList) {
      grouped.putIfAbsent(item.ingredient.category, () => []).add(item);
    }
    final categories = grouped.entries.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Список покупок',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    color: scheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              Text(
                '${plan.shoppingList.length} поз.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Цены: ${storeChainOf(profile)} · ${retailCityOf(profile)}. '
            'Загружаются при раскрытии.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in categories)
            _MiniCategory(
              title: entry.key,
              count: entry.value.length,
              onTap: onOpenShopping,
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onOpenShopping,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(38),
            ),
            child: const Text('Весь список'),
          ),
        ],
      ),
    );
  }

  String storeChainOf(UserProfile profile) =>
      storeChainById(profile.storeId).name;
  String retailCityOf(UserProfile profile) =>
      retailCityById(profile.cityId).name;
}

class _MiniCategory extends StatelessWidget {
  const _MiniCategory({
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.chevron_right,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
