import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/in_memory_recipe_repository.dart';
import '../../core/data/recipe_repository.dart';
import '../../core/data/session_storage.dart';
import '../../core/models/daily_targets.dart';
import '../../core/models/meal_plan.dart';
import '../../core/models/plan_snapshot.dart';
import '../../core/models/recipe.dart';
import '../../core/models/user_profile.dart';
import '../../core/nutrition/targets_calculator.dart';
import '../../core/planner/menu_generator.dart';
import '../../core/planner/plan_restorer.dart';
import '../onboarding/onboarding_page.dart';

enum _MealAction { replace, like, block }

enum _PlanMenuAction { editProfile, resetProfile }

class PlanPage extends StatefulWidget {
  const PlanPage({
    super.key,
    required this.profile,
    this.initialSeed = 1,
    this.initialPlan,
  });

  final UserProfile profile;
  final int initialSeed;
  final SavedPlan? initialPlan;

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  late final RecipeRepository _repository;
  final SessionStorage _storage = SessionStorage();
  late UserProfile _profile;
  WeeklyPlan? _plan;
  String? _error;
  late int _seed;

  @override
  void initState() {
    super.initState();
    _repository = InMemoryRecipeRepository.seeded();
    _profile = widget.profile;
    _seed = widget.initialSeed;
    _restoreOrGenerate();
  }

  void _restoreOrGenerate() {
    final snapshot = widget.initialPlan;
    if (snapshot != null) {
      final restored = restorePlan(
        snapshot: snapshot,
        repository: _repository,
        targets: const TargetsCalculator().calculate(_profile),
      );
      if (restored != null) {
        _plan = restored;
        _error = null;
        return;
      }
    }
    _generate();
  }

  void _generate() {
    final targets = const TargetsCalculator().calculate(_profile);
    try {
      _plan = const MenuGenerator().generate(
        profile: _profile,
        targets: targets,
        repository: _repository,
        seed: _seed,
      );
      _error = null;
    } on StateError catch (error) {
      _plan = null;
      _error = error.message;
    }
    unawaited(_saveSession());
  }

  Future<void> _saveSession() async {
    try {
      final plan = _plan;
      await _storage.save(
        _profile,
        _seed,
        plan: plan == null ? null : SavedPlan.fromWeeklyPlan(plan),
      );
    } catch (_) {
      return;
    }
  }

  void _regenerate() {
    setState(() {
      _seed++;
      _generate();
    });
  }

  Future<void> _replaceMeal(int dayIndex, int mealIndex) async {
    final current = _plan;
    if (current == null) {
      return;
    }

    final List<MealAlternative> alternatives;
    try {
      alternatives = const MenuGenerator().alternativesForMeal(
        plan: current,
        profile: _profile,
        repository: _repository,
        dayIndex: dayIndex,
        mealIndex: mealIndex,
      );
    } on StateError catch (error) {
      _showMessage(error.message);
      return;
    }

    if (alternatives.isEmpty) {
      _showMessage('Нет альтернатив с учётом ограничений');
      return;
    }

    final selected = await showModalBottomSheet<MealAlternative>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _AlternativesSheet(
        alternatives: alternatives,
        current: current.days[dayIndex].meals[mealIndex],
      ),
    );
    if (selected == null || !mounted) {
      return;
    }

    final plan = _plan;
    if (plan == null) {
      return;
    }
    try {
      final updated = const MenuGenerator().applyMealAlternative(
        plan: plan,
        dayIndex: dayIndex,
        mealIndex: mealIndex,
        alternative: selected,
        repository: _repository,
      );
      setState(() => _plan = updated);
      unawaited(_saveSession());
      _showMessage('Блюдо заменено');
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  void _likeRecipe(Recipe recipe) {
    setState(() {
      _profile = _profile.copyWith(
        preferredRecipeIds: {..._profile.preferredRecipeIds, recipe.id},
        blockedRecipeIds: {..._profile.blockedRecipeIds}..remove(recipe.id),
      );
    });
    unawaited(_saveSession());
    _showMessage('Учтем «${recipe.title}» в следующих подборах');
  }

  void _blockRecipe(Recipe recipe) {
    setState(() {
      _profile = _profile.copyWith(
        blockedRecipeIds: {..._profile.blockedRecipeIds, recipe.id},
        preferredRecipeIds: {..._profile.preferredRecipeIds}..remove(recipe.id),
      );
      _seed++;
      _generate();
    });
    _showMessage('Больше не будем предлагать «${recipe.title}»');
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute<UserProfile>(
        builder: (context) => OnboardingPage(initialProfile: _profile),
      ),
    );
    if (updated == null || !mounted) {
      return;
    }
    setState(() {
      _profile = updated;
      _seed = 1;
      _generate();
    });
  }

  Future<void> _resetProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Сбросить профиль?'),
          content: const Text('Параметры и текущий рацион будут удалены.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Сбросить'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await _storage.clear();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (context) => const OnboardingPage()),
      (route) => false,
    );
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
    final plan = _plan;
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваш рацион'),
        actions: [
          IconButton(
            onPressed: _regenerate,
            tooltip: 'Перегенерировать меню',
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<_PlanMenuAction>(
            tooltip: 'Настройки',
            onSelected: (action) {
              switch (action) {
                case _PlanMenuAction.editProfile:
                  unawaited(_editProfile());
                  break;
                case _PlanMenuAction.resetProfile:
                  unawaited(_resetProfile());
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<_PlanMenuAction>(
                value: _PlanMenuAction.editProfile,
                child: Text('Изменить параметры'),
              ),
              PopupMenuItem<_PlanMenuAction>(
                value: _PlanMenuAction.resetProfile,
                child: Text('Сбросить профиль'),
              ),
            ],
          ),
        ],
      ),
      body: error != null
          ? _ErrorView(message: error, onRetry: _regenerate)
          : plan == null
          ? const Center(child: CircularProgressIndicator())
          : _PlanView(
              plan: plan,
              profile: _profile,
              repository: _repository,
              onReplace: _replaceMeal,
              onLike: _likeRecipe,
              onBlock: _blockRecipe,
            ),
    );
  }
}

class _PlanView extends StatelessWidget {
  const _PlanView({
    required this.plan,
    required this.profile,
    required this.repository,
    required this.onReplace,
    required this.onLike,
    required this.onBlock,
  });

  final WeeklyPlan plan;
  final UserProfile profile;
  final RecipeRepository repository;
  final void Function(int dayIndex, int mealIndex) onReplace;
  final void Function(Recipe recipe) onLike;
  final void Function(Recipe recipe) onBlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in plan.shoppingList) {
      grouped.putIfAbsent(item.ingredient.category, () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TargetsCard(targets: plan.targets, profile: profile),
              const SizedBox(height: 20),
              Text(
                'Меню на неделю',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ориентировочно ${plan.totalCost.round()} ₽ за неделю',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final day in plan.days)
                _DayCard(
                  day: day,
                  repository: repository,
                  onReplace: onReplace,
                  onLike: onLike,
                  onBlock: onBlock,
                ),
              const SizedBox(height: 12),
              Text(
                'Список покупок',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final entry in grouped.entries)
                _ShoppingCard(category: entry.key, items: entry.value),
              const SizedBox(height: 12),
              Text(
                'Норма — ориентир, а не медицинская рекомендация.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetsCard extends StatelessWidget {
  const _TargetsCard({required this.targets, required this.profile});

  final DailyTargets targets;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nutrients = targets.nutrients;
    final limits = <String>[
      if (profile.maxCookMinutes != null) 'до ${profile.maxCookMinutes} мин',
      if (profile.dailyBudgetRub != null) 'до ${profile.dailyBudgetRub} ₽/день',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Норма на день',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${profile.goal.label} · ${profile.mealsPerDay} приёма пищи',
              style: theme.textTheme.bodyMedium,
            ),
            if (limits.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Ограничения: ${limits.join(' · ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${nutrients.calories.round()}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('ккал', style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MacroChip(label: 'Белки', grams: nutrients.protein),
                _MacroChip(label: 'Жиры', grams: nutrients.fat),
                _MacroChip(label: 'Углеводы', grams: nutrients.carbs),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Базовый обмен: ${targets.bmr.round()} ккал · Расход: ${targets.tdee.round()} ккал',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.grams});

  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label ${grams.round()} г'),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.repository,
    required this.onReplace,
    required this.onLike,
    required this.onBlock,
  });

  final DayPlan day;
  final RecipeRepository repository;
  final void Function(int dayIndex, int mealIndex) onReplace;
  final void Function(Recipe recipe) onLike;
  final void Function(Recipe recipe) onBlock;

  @override
  Widget build(BuildContext context) {
    final totals = day.totals;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text('День ${day.index}'),
        subtitle: Text(
          '${totals.calories.round()} ккал · '
          'Б ${totals.protein.round()} · '
          'Ж ${totals.fat.round()} · '
          'У ${totals.carbs.round()}\n'
          '~${day.totalCost.round()} ₽ за день',
        ),
        children: [
          for (var mealIndex = 0; mealIndex < day.meals.length; mealIndex++)
            _buildMealTile(context, day.meals[mealIndex], mealIndex),
        ],
      ),
    );
  }

  Widget _buildMealTile(BuildContext context, PlannedMeal meal, int mealIndex) {
    return ListTile(
      leading: CircleAvatar(child: Text(meal.type.label.substring(0, 1))),
      title: Text(meal.recipe.title),
      subtitle: Text(
        '${meal.type.label} · ${meal.recipe.minutes} мин · '
        '${(meal.scale * 100).round()}% порции · ~${meal.cost.round()} ₽',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${meal.nutrients.calories.round()} ккал'),
          PopupMenuButton<_MealAction>(
            tooltip: 'Действия с блюдом',
            onSelected: (action) {
              switch (action) {
                case _MealAction.replace:
                  onReplace(day.index - 1, mealIndex);
                  break;
                case _MealAction.like:
                  onLike(meal.recipe);
                  break;
                case _MealAction.block:
                  onBlock(meal.recipe);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<_MealAction>(
                value: _MealAction.replace,
                child: Text('Заменить блюдо'),
              ),
              PopupMenuItem<_MealAction>(
                value: _MealAction.like,
                child: Text('Нравится'),
              ),
              PopupMenuItem<_MealAction>(
                value: _MealAction.block,
                child: Text('Не предлагать'),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _showRecipe(context, meal, repository),
    );
  }
}

void _showRecipe(
  BuildContext context,
  PlannedMeal meal,
  RecipeRepository repository,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final nutrients = meal.nutrients;
      return AlertDialog(
        title: Text(meal.recipe.title),
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
                  '~${meal.cost.round()} ₽',
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
                for (final entry in meal.ingredientGrams.entries)
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
                for (var index = 0; index < meal.recipe.steps.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${index + 1}. ${meal.recipe.steps[index]}'),
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

class _ShoppingCard extends StatelessWidget {
  const _ShoppingCard({required this.category, required this.items});

  final String category;
  final List<ShoppingItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(category),
        subtitle: Text('${items.length} поз.'),
        children: [
          for (final item in items)
            ListTile(
              dense: true,
              title: Text(item.ingredient.name),
              trailing: Text('${item.grams.round()} г'),
            ),
        ],
      ),
    );
  }
}

class _AlternativesSheet extends StatelessWidget {
  const _AlternativesSheet({required this.alternatives, required this.current});

  final List<MealAlternative> alternatives;
  final PlannedMeal current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              'Заменить «${current.recipe.title}»',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${current.type.label} · отсортировано по близости к норме',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final alternative in alternatives)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(alternative.recipe.title),
                subtitle: Text(
                  '${alternative.nutrients.calories.round()} ккал · '
                  'Б ${alternative.nutrients.protein.round()} · '
                  '${alternative.recipe.minutes} мин · '
                  '~${alternative.cost.round()} ₽',
                ),
                trailing: Text('${(alternative.scale * 100).round()}%'),
                onTap: () => Navigator.of(context).pop(alternative),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'Не удалось собрать меню',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }
}
