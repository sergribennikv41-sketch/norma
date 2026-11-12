import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/app_database.dart';
import '../../core/data/recipe_repository.dart';
import '../../core/data/session_storage.dart';
import '../../core/models/meal_plan.dart';
import '../../core/models/plan_snapshot.dart';
import '../../core/models/recipe.dart';
import '../../core/models/seed_bundle.dart';
import '../../core/models/user_profile.dart';
import '../../core/nutrition/targets_calculator.dart';
import '../../core/planner/menu_generator.dart';
import '../../core/planner/plan_restorer.dart';
import '../../core/planner/shopping_list_text.dart';
import '../../core/price/price_lookup.dart';
import '../shared/recipe_details.dart';
import 'catalog_view.dart';
import 'home_widgets.dart';
import 'plan_view.dart';
import 'profile_view.dart';
import 'shopping_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RecipeRepository _repository;
  late UserProfile _profile;
  late int _seed;
  late final PriceLookupService _priceLookup;
  final SessionStorage _storage = SessionStorage();
  final Map<String, PriceLookupState> _priceStates = {};
  final Set<String> _checkedIngredients = {};
  StreamSubscription<PriceLookupEvent>? _priceSubscription;
  WeeklyPlan? _plan;
  String? _error;
  HomeSection _section = HomeSection.plan;
  int _selectedDayIndex = 0;
  final List<PriceLookupItem> _priceQueue = [];

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
      _selectedDayIndex = _selectedDayIndex.clamp(
        0,
        (_plan?.days.length ?? 1) - 1,
      );
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

  void _selectSection(HomeSection section) {
    if (_section == section) {
      return;
    }
    setState(() => _section = section);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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

  void _openCatalogRecipe(Recipe recipe) {
    showRecipeDetails(
      context,
      title: recipe.title,
      nutrients: _repository.nutrientsPerServing(recipe),
      ingredientGrams: {
        for (final item in recipe.ingredients)
          item.ingredientId: item.grams / recipe.servings,
      },
      steps: recipe.steps,
      repository: _repository,
      image: recipe.image,
      source: recipe.source,
      mealType: recipe.mealTypes.isEmpty ? null : recipe.mealTypes.first,
      minutes: recipe.minutes,
      servings: recipe.servings,
      onAddToPlan: () => _addRecipeToPlan(recipe),
    );
  }

  Future<void> _addRecipeToPlan(Recipe recipe) async {
    final plan = _plan;
    if (plan == null) {
      _showMessage('Сначала сформируйте рацион');
      return;
    }
    final choice = await _pickSlot(recipe, plan);
    if (choice == null || !mounted) {
      return;
    }
    try {
      final updated = const MenuGenerator().applyRecipeToMeal(
        plan: plan,
        profile: _profile,
        repository: _repository,
        dayIndex: choice.dayIndex,
        mealIndex: choice.mealIndex,
        recipe: recipe,
      );
      setState(() => _plan = updated);
      unawaited(_saveSession());
      _showMessage('Блюдо добавлено в рацион');
    } on StateError catch (error) {
      _showMessage(error.message);
    }
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

  void _applyProfile(UserProfile updated) {
    final locationChanged =
        updated.cityId != _profile.cityId ||
        updated.storeId != _profile.storeId;
    if (locationChanged) {
      _resetPrices();
    }
    setState(() {
      _profile = updated;
      _seed = 1;
      _section = HomeSection.plan;
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
      MaterialPageRoute<void>(
        builder: (routeContext) => ProfileView(
          repository: _repository,
          onSubmit: (profile) {
            Navigator.of(routeContext).pushReplacement(
              MaterialPageRoute<void>(
                builder: (context) =>
                    HomePage(profile: profile, repository: _repository),
              ),
            );
          },
        ),
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

  void _onShoppingExpanded(List<ShoppingItem> items) {
    _ensurePricesLoaded(items);
  }

  void _ensurePricesLoaded([List<ShoppingItem>? source]) {
    final plan = _plan;
    if (plan == null) {
      return;
    }
    final items = source ?? plan.shoppingList;
    final seen = <String>{};
    final missing = <PriceLookupItem>[];
    for (final item in items) {
      final ingredient = item.ingredient;
      if (!seen.add(ingredient.id)) {
        continue;
      }
      final status = _priceStates[ingredient.id]?.status;
      if (status == PriceLookupStatus.found ||
          status == PriceLookupStatus.loading) {
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
    if (_priceSubscription != null) {
      for (final item in missing) {
        if (!_priceQueue.any((queued) => queued.id == item.id)) {
          _priceQueue.add(item);
        }
      }
      return;
    }
    _startPriceLookup(missing);
  }

  void _startPriceLookup(List<PriceLookupItem> items) {
    final stream = _priceLookup.lookup(
      cityId: _profile.cityId,
      storeId: _profile.storeId,
      items: items,
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
          for (final item in items) {
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
          for (final item in items) {
            if (_priceStates[item.id]?.status == PriceLookupStatus.loading) {
              _priceStates[item.id] = const PriceLookupState.failed(
                'Нет ответа от магазина',
              );
            }
          }
        });
        _startNextPriceBatch();
      },
    );
  }

  void _startNextPriceBatch() {
    if (_priceQueue.isEmpty) {
      return;
    }
    final queued = List<PriceLookupItem>.from(_priceQueue);
    _priceQueue.clear();
    final pending = [
      for (final item in queued)
        if (_priceStates[item.id]?.status != PriceLookupStatus.found) item,
    ];
    if (pending.isEmpty) {
      return;
    }
    setState(() {
      for (final item in pending) {
        _priceStates[item.id] = const PriceLookupState.loading();
      }
    });
    _startPriceLookup(pending);
  }

  void _refreshPrices() {
    _priceQueue.clear();
    final subscription = _priceSubscription;
    _priceSubscription = null;
    unawaited(subscription?.cancel());
    _priceLookup.clearCache();
    setState(_priceStates.clear);
    _ensurePricesLoaded();
  }

  void _resetPrices() {
    _priceQueue.clear();
    final subscription = _priceSubscription;
    _priceSubscription = null;
    unawaited(subscription?.cancel());
    _priceLookup.clearCache();
    _priceStates.clear();
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final content = switch (_section) {
      HomeSection.plan => _buildPlan(plan),
      HomeSection.catalog => CatalogView(
        repository: _repository,
        profile: _profile,
        onOpenRecipe: _openCatalogRecipe,
        onOpenShopping: () => _selectSection(HomeSection.shopping),
      ),
      HomeSection.shopping =>
        plan == null
            ? _ErrorView(message: _error ?? 'Нет рациона', onRetry: _regenerate)
            : ShoppingView(
                plan: plan,
                profile: _profile,
                priceStates: _priceStates,
                checkedIngredients: _checkedIngredients,
                onToggleIngredient: _toggleIngredient,
                onExpandCategory: _onShoppingExpanded,
                onRefreshPrices: _refreshPrices,
                onCopy: () {
                  unawaited(_copyShoppingList());
                },
              ),
      HomeSection.profile => ProfileView(
        repository: _repository,
        initialProfile: _profile,
        embedded: true,
        submitLabel: 'Сохранить и пересчитать',
        onSubmit: _applyProfile,
        onImport: _importRecipes,
        onReset: _resetProfile,
      ),
    };
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSidebar(section: _section, onSelect: _selectSection),
          Expanded(
            child: SafeArea(
              top: false,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlan(WeeklyPlan? plan) {
    if (_error != null && plan == null) {
      return _ErrorView(message: _error!, onRetry: _regenerate);
    }
    if (plan == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PlanView(
      plan: plan,
      profile: _profile,
      repository: _repository,
      selectedDayIndex: _selectedDayIndex,
      onSelectDay: (index) => setState(() => _selectedDayIndex = index),
      onReplace: _replaceMeal,
      onLike: _likeRecipe,
      onBlock: _blockRecipe,
      onOpenMeal: _openMeal,
      onOpenShopping: () => _selectSection(HomeSection.shopping),
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
              style: theme.textTheme.titleLarge,
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
            FilledButton(
              onPressed: onRetry,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }
}
