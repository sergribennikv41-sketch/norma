import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/app_database.dart';
import '../../core/data/recipe_repository.dart';
import '../../core/data/session_storage.dart';
import '../../core/models/daily_targets.dart';
import '../../core/models/meal_plan.dart';
import '../../core/models/plan_snapshot.dart';
import '../../core/models/recipe.dart';
import '../../core/models/retail.dart';
import '../../core/models/seed_bundle.dart';
import '../../core/models/user_profile.dart';
import '../../core/nutrition/targets_calculator.dart';
import '../../core/planner/menu_generator.dart';
import '../../core/planner/plan_restorer.dart';
import '../../core/planner/shopping_list_text.dart';
import '../../core/price/price_lookup.dart';
import '../catalog/catalog_page.dart';
import '../onboarding/onboarding_page.dart';
import '../shared/recipe_details.dart';
import '../shared/theme_mode_button.dart';

enum _MealAction { replace, like, block }

enum _PlanMenuAction { editProfile, importRecipes, resetProfile }

class PlanPage extends StatefulWidget {
  const PlanPage({
    super.key,
    required this.profile,
    required this.repository,
    this.initialSeed = 1,
    this.initialPlan,
    this.priceLookup,
  });

  final UserProfile profile;
  final RecipeRepository repository;
  final int initialSeed;
  final SavedPlan? initialPlan;
  final PriceLookupService? priceLookup;

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  late RecipeRepository _repository;
  final SessionStorage _storage = SessionStorage();
  late UserProfile _profile;
  WeeklyPlan? _plan;
  String? _error;
  late int _seed;
  late final PriceLookupService _priceLookup;
  final Map<String, PriceLookupState> _priceStates = {};
  StreamSubscription<PriceLookupEvent>? _priceSubscription;
  bool _shoppingExpanded = false;
  final Set<String> _checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;
    _profile = widget.profile;
    _seed = widget.initialSeed;
    _priceLookup = widget.priceLookup ?? ProcessPriceLookupService();
    _restoreOrGenerate();
  }

  @override
  void dispose() {
    unawaited(_priceSubscription?.cancel());
    super.dispose();
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
    _checkedIngredients.clear();
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
    if (_shoppingExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _ensurePricesLoaded();
        }
      });
    }
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

  void _onShoppingExpanded() {
    _shoppingExpanded = true;
    _ensurePricesLoaded();
  }

  void _ensurePricesLoaded() {
    if (_priceSubscription != null) {
      return;
    }
    final plan = _plan;
    if (plan == null) {
      return;
    }

    final seen = <String>{};
    final missing = <PriceLookupItem>[];
    for (final item in plan.shoppingList) {
      final ingredient = item.ingredient;
      if (!seen.add(ingredient.id)) {
        continue;
      }
      if (_priceStates[ingredient.id]?.status == PriceLookupStatus.found) {
        continue;
      }
      missing.add(PriceLookupItem(id: ingredient.id, name: ingredient.name));
    }
    if (missing.isEmpty) {
      return;
    }

    setState(() {
      for (final item in missing) {
        _priceStates[item.id] = const PriceLookupState.loading();
      }
    });

    final stream = _priceLookup.lookup(
      cityId: _profile.cityId,
      storeId: _profile.storeId,
      items: missing,
    );
    _priceSubscription = stream.listen(
      (event) {
        if (!mounted) {
          return;
        }
        setState(() => _priceStates[event.ingredientId] = event.state);
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          for (final item in missing) {
            if (_priceStates[item.id]?.status == PriceLookupStatus.loading) {
              _priceStates[item.id] = PriceLookupState.failed(error.toString());
            }
          }
        });
      },
      onDone: () {
        _priceSubscription = null;
        if (!mounted) {
          return;
        }
        setState(() {
          for (final item in missing) {
            if (_priceStates[item.id]?.status == PriceLookupStatus.loading) {
              _priceStates[item.id] = const PriceLookupState.failed(
                'Нет ответа от магазина',
              );
            }
          }
        });
      },
    );
  }

  void _resetPrices() {
    unawaited(_priceSubscription?.cancel());
    _priceSubscription = null;
    _priceLookup.clearCache();
    _priceStates.clear();
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

  Future<void> _openMeal(int dayIndex, int mealIndex) async {
    final plan = _plan;
    if (plan == null) {
      return;
    }
    final meal = plan.days[dayIndex].meals[mealIndex];
    final scale = await showRecipeDetails(
      context,
      title: meal.recipe.title,
      nutrients: meal.nutrients,
      ingredientGrams: meal.ingredientGrams,
      steps: meal.recipe.steps,
      repository: _repository,
      image: meal.recipe.image,
      source: meal.recipe.source,
      mealType: meal.type,
      minutes: meal.recipe.minutes,
      servings: meal.recipe.servings,
      allowScaleEdit: true,
      initialScale: meal.scale,
    );
    if (scale == null || !mounted) {
      return;
    }
    if ((scale - meal.scale).abs() < 0.001) {
      return;
    }
    final currentPlan = _plan;
    if (currentPlan == null) {
      return;
    }
    try {
      final updated = const MenuGenerator().rescaleMeal(
        plan: currentPlan,
        dayIndex: dayIndex,
        mealIndex: mealIndex,
        scale: scale,
        repository: _repository,
      );
      setState(() => _plan = updated);
      unawaited(_saveSession());
      _showMessage('Порция обновлена');
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  void _toggleIngredient(String ingredientId, bool checked) {
    setState(() {
      if (checked) {
        _checkedIngredients.add(ingredientId);
      } else {
        _checkedIngredients.remove(ingredientId);
      }
    });
  }

  Future<void> _copyShoppingList() async {
    final plan = _plan;
    if (plan == null) {
      return;
    }
    await Clipboard.setData(
      ClipboardData(text: buildShoppingListText(plan.shoppingList)),
    );
    _showMessage('Список покупок скопирован');
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
        builder: (context) =>
            OnboardingPage(repository: _repository, initialProfile: _profile),
      ),
    );
    if (updated == null || !mounted) {
      return;
    }
    final locationChanged =
        updated.cityId != _profile.cityId ||
        updated.storeId != _profile.storeId;
    if (locationChanged) {
      _resetPrices();
    }
    setState(() {
      _profile = updated;
      _seed = 1;
      _generate();
    });
    if (locationChanged && _shoppingExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _ensurePricesLoaded();
        }
      });
    }
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
      MaterialPageRoute<void>(
        builder: (context) => OnboardingPage(repository: _repository),
      ),
      (route) => false,
    );
  }

  Future<void> _importRecipes() async {
    const typeGroup = XTypeGroup(label: 'JSON', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !mounted) {
      return;
    }

    final SeedBundle bundle;
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Ожидается JSON-объект');
      }
      bundle = SeedBundle.fromJson(Map<String, dynamic>.from(decoded));
      if (bundle.recipes.isEmpty) {
        throw const FormatException('В файле нет рецептов');
      }
    } on FormatException catch (error) {
      _showMessage('Ошибка импорта: ${error.message}');
      return;
    } catch (error) {
      _showMessage('Не удалось прочитать файл: $error');
      return;
    }

    if (!mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Импортировать рецепты?'),
          content: Text(
            'Ингредиентов: ${bundle.ingredients.length}\n'
            'Рецептов: ${bundle.recipes.length}\n\n'
            'Совпадающие записи будут обновлены.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Импортировать'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    AppDatabase? database;
    try {
      database = await AppDatabase.open();
      final count = await database.merge(bundle);
      final repository = await database.loadRepository();
      if (!mounted) {
        return;
      }
      setState(() {
        _repository = repository;
        _seed++;
        _generate();
      });
      _showMessage('Импортировано рецептов: $count');
    } catch (error) {
      _showMessage('Не удалось импортировать: $error');
    } finally {
      await database?.close();
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCatalog() async {
    final plan = _plan;
    if (plan == null) {
      return;
    }
    final pick = await Navigator.of(context).push<CatalogPick>(
      MaterialPageRoute<CatalogPick>(
        builder: (context) => CatalogPage(repository: _repository, plan: plan),
      ),
    );
    if (pick == null || !mounted) {
      return;
    }
    final recipe = _repository.recipeById(pick.recipeId);
    if (recipe == null) {
      _showMessage('Рецепт не найден');
      return;
    }
    final currentPlan = _plan;
    if (currentPlan == null) {
      return;
    }
    try {
      final updated = const MenuGenerator().applyRecipeToMeal(
        plan: currentPlan,
        profile: _profile,
        repository: _repository,
        dayIndex: pick.dayIndex,
        mealIndex: pick.mealIndex,
        recipe: recipe,
      );
      setState(() => _plan = updated);
      unawaited(_saveSession());
      _showMessage('Блюдо добавлено в рацион');
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваш рацион'),
        actions: [
          const ThemeModeButton(),
          IconButton(
            onPressed: () {
              unawaited(_openCatalog());
            },
            tooltip: 'Каталог рецептов',
            icon: const Icon(Icons.menu_book_outlined),
          ),
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
                case _PlanMenuAction.importRecipes:
                  unawaited(_importRecipes());
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
                value: _PlanMenuAction.importRecipes,
                child: Text('Импортировать рецепты'),
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
              onReplace: _replaceMeal,
              onLike: _likeRecipe,
              onBlock: _blockRecipe,
              onOpenMeal: _openMeal,
              checkedIngredients: _checkedIngredients,
              onToggleIngredient: _toggleIngredient,
              onCopyShoppingList: _copyShoppingList,
              priceStates: _priceStates,
              onLoadPrices: _onShoppingExpanded,
            ),
    );
  }
}

class _PlanView extends StatelessWidget {
  const _PlanView({
    required this.plan,
    required this.profile,
    required this.onReplace,
    required this.onLike,
    required this.onBlock,
    required this.onOpenMeal,
    required this.checkedIngredients,
    required this.onToggleIngredient,
    required this.onCopyShoppingList,
    required this.priceStates,
    required this.onLoadPrices,
  });

  final WeeklyPlan plan;
  final UserProfile profile;
  final void Function(int dayIndex, int mealIndex) onReplace;
  final void Function(Recipe recipe) onLike;
  final void Function(Recipe recipe) onBlock;
  final void Function(int dayIndex, int mealIndex) onOpenMeal;
  final Set<String> checkedIngredients;
  final void Function(String ingredientId, bool checked) onToggleIngredient;
  final VoidCallback onCopyShoppingList;
  final Map<String, PriceLookupState> priceStates;
  final VoidCallback onLoadPrices;

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
              const SizedBox(height: 8),
              for (final day in plan.days)
                _DayCard(
                  day: day,
                  onReplace: onReplace,
                  onLike: onLike,
                  onBlock: onBlock,
                  onOpen: onOpenMeal,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Список покупок',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onCopyShoppingList,
                    tooltip: 'Скопировать список',
                    icon: const Icon(Icons.copy_all_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Цены: ${storeChainById(profile.storeId).name} · '
                '${retailCityById(profile.cityId).name}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final entry in grouped.entries)
                _ShoppingCard(
                  category: entry.key,
                  items: entry.value,
                  checkedIngredients: checkedIngredients,
                  onToggleIngredient: onToggleIngredient,
                  priceStates: priceStates,
                  onExpanded: onLoadPrices,
                ),
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
    required this.onReplace,
    required this.onLike,
    required this.onBlock,
    required this.onOpen,
  });

  final DayPlan day;
  final void Function(int dayIndex, int mealIndex) onReplace;
  final void Function(Recipe recipe) onLike;
  final void Function(Recipe recipe) onBlock;
  final void Function(int dayIndex, int mealIndex) onOpen;

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
          'У ${totals.carbs.round()}',
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
        '${(meal.scale * 100).round()}% порции',
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
      onTap: () => onOpen(day.index - 1, mealIndex),
    );
  }
}

class _ShoppingCard extends StatelessWidget {
  const _ShoppingCard({
    required this.category,
    required this.items,
    required this.checkedIngredients,
    required this.onToggleIngredient,
    required this.priceStates,
    required this.onExpanded,
  });

  final String category;
  final List<ShoppingItem> items;
  final Set<String> checkedIngredients;
  final void Function(String ingredientId, bool checked) onToggleIngredient;
  final Map<String, PriceLookupState> priceStates;
  final VoidCallback onExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(category),
        subtitle: Text('${items.length} поз.'),
        onExpansionChanged: (expanded) {
          if (expanded) {
            onExpanded();
          }
        },
        children: [
          for (final item in items)
            ListTile(
              dense: true,
              leading: Checkbox(
                value: checkedIngredients.contains(item.ingredient.id),
                onChanged: (value) {
                  onToggleIngredient(item.ingredient.id, value ?? false);
                },
              ),
              title: Text(
                item.ingredient.name,
                style: checkedIngredients.contains(item.ingredient.id)
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${item.grams.round()} г'),
                  const SizedBox(width: 8),
                  _PriceBadge(state: priceStates[item.ingredient.id]),
                ],
              ),
              onTap: () {
                onToggleIngredient(
                  item.ingredient.id,
                  !checkedIngredients.contains(item.ingredient.id),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.state});

  final PriceLookupState? state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = state;
    if (current == null) {
      return const SizedBox(width: 64);
    }
    return SizedBox(
      width: 64,
      child: Align(
        alignment: Alignment.centerRight,
        child: switch (current.status) {
          PriceLookupStatus.loading => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          PriceLookupStatus.found => Tooltip(
            message: [
              current.quote?.title ?? '',
              if (current.quote?.unit != null) current.quote!.unit!,
            ].where((item) => item.isNotEmpty).join(' · '),
            child: Text(
              '${current.quote!.price.round()} ₽',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PriceLookupStatus.notFound => Tooltip(
            message: 'Цена не найдена',
            child: Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: theme.colorScheme.outline,
            ),
          ),
          PriceLookupStatus.failed => Tooltip(
            message: current.message ?? 'Не удалось получить цену',
            child: Icon(
              Icons.error_outline,
              size: 18,
              color: theme.colorScheme.error,
            ),
          ),
        },
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
                  '${alternative.recipe.minutes} мин',
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
