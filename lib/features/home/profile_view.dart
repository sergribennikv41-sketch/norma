import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/recipe_repository.dart';
import '../../core/models/enums.dart';
import '../../core/models/retail.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/theme_controller.dart';
import '../shared/theme_mode_button.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.repository,
    required this.onSubmit,
    this.initialProfile,
    this.embedded = false,
    this.submitLabel = 'Рассчитать рацион',
    this.onImport,
    this.onReset,
  });

  final RecipeRepository repository;
  final ValueChanged<UserProfile> onSubmit;
  final UserProfile? initialProfile;
  final bool embedded;
  final String submitLabel;
  final VoidCallback? onImport;
  final VoidCallback? onReset;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController(text: '30');
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '75');

  static final _decimalFilter = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9.,]'),
  );

  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  Goal _goal = Goal.lose;
  Pace _pace = Pace.medium;
  int _mealsPerDay = 4;
  int? _maxCookMinutes;
  String _cityId = defaultCityId;
  String _storeId = defaultStoreId;
  final Set<Allergen> _excludedAllergens = {};

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    if (profile == null) {
      return;
    }
    _ageController.text = '${profile.age}';
    _heightController.text = _formatDecimal(profile.heightCm);
    _weightController.text = _formatDecimal(profile.weightKg);
    _sex = profile.sex;
    _activity = profile.activity;
    _goal = profile.goal;
    _pace = profile.pace;
    _mealsPerDay = profile.mealsPerDay;
    _maxCookMinutes = profile.maxCookMinutes;
    _cityId = profile.cityId;
    _storeId = profile.storeId;
    _excludedAllergens.addAll(profile.excludedAllergens);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String _formatDecimal(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }

  String? _validateInt(String? value, int min, int max) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < min || parsed > max) {
      return 'Введите $min–$max';
    }
    return null;
  }

  String? _validateDouble(String? value, double min, double max) {
    final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (parsed == null || parsed < min || parsed > max) {
      return 'Введите ${min.round()}–${max.round()}';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    widget.onSubmit(
      UserProfile(
        sex: _sex,
        age: int.parse(_ageController.text.trim()),
        heightCm: double.parse(
          _heightController.text.trim().replaceAll(',', '.'),
        ),
        weightKg: double.parse(
          _weightController.text.trim().replaceAll(',', '.'),
        ),
        activity: _activity,
        goal: _goal,
        pace: _pace,
        mealsPerDay: _mealsPerDay,
        maxCookMinutes: _maxCookMinutes,
        excludedAllergens: Set.unmodifiable(_excludedAllergens),
        cityId: _cityId,
        storeId: _storeId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.embedded) {
      return content;
    }
    return Scaffold(body: SafeArea(child: content));
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final themeController = ThemeControllerScope.maybeOf(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 32,
        compact ? 18 : 24,
        compact ? 16 : 32,
        compact ? 30 : 42,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.embedded) ...[
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'н',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'норма',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        color: scheme.onSurface,
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1,
                      ),
                    ),
                    const Spacer(),
                    const ThemeModeButton(),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'НАСТРОЙКА',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Рацион под вас',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Норма КБЖУ и меню на неделю с учётом цели и ограничений',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Шаг 1 из 3',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 920;
                  final hero = _HeroCard();
                  final form = _buildForm(context, themeController);
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [hero, const SizedBox(height: 16), form],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 100, child: hero),
                      const SizedBox(width: 22),
                      Expanded(flex: 85, child: form),
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

  Widget _buildForm(BuildContext context, ThemeController? themeController) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(22),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Основные параметры',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Unbounded',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Это займёт меньше минуты.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
            ),
            const SizedBox(height: 16),
            SegmentedButton<Sex>(
              segments: [
                for (final sex in Sex.values)
                  ButtonSegment<Sex>(value: sex, label: Text(sex.label)),
              ],
              selected: {_sex},
              onSelectionChanged: (selection) {
                setState(() => _sex = selection.first);
              },
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Возраст',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => _validateInt(value, 14, 90),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Рост, см',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_decimalFilter],
                    validator: (value) => _validateDouble(value, 120, 230),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Вес, кг',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_decimalFilter],
                    validator: (value) => _validateDouble(value, 35, 250),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ActivityLevel>(
              initialValue: _activity,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Активность',
                isDense: true,
              ),
              items: [
                for (final level in ActivityLevel.values)
                  DropdownMenuItem<ActivityLevel>(
                    value: level,
                    child: Text(level.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _activity = value);
                }
              },
            ),
            const _FormDivider(),
            _FormSection(
              title: 'Цель',
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final goal in Goal.values)
                    ChoiceChip(
                      label: Text(goal.label),
                      selected: _goal == goal,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _goal = goal);
                        }
                      },
                    ),
                ],
              ),
            ),
            if (_goal != Goal.maintain)
              _FormSection(
                title: 'Темп',
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final pace in Pace.values)
                      ChoiceChip(
                        label: Text(pace.label),
                        selected: _pace == pace,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _pace = pace);
                          }
                        },
                      ),
                  ],
                ),
              ),
            _FormSection(
              title: 'Приёмов пищи',
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final count in const [3, 4, 5])
                    ChoiceChip(
                      label: Text('$count'),
                      selected: _mealsPerDay == count,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _mealsPerDay = count);
                        }
                      },
                    ),
                ],
              ),
            ),
            _FormSection(
              title: 'Готовка',
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final option in const <int?>[15, 30, 45, null])
                    ChoiceChip(
                      label: Text(option == null ? 'Любое' : '$option мин'),
                      selected: _maxCookMinutes == option,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _maxCookMinutes = option);
                        }
                      },
                    ),
                ],
              ),
            ),
            _FormSection(
              title: 'Город и магазин',
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: DropdownButtonFormField<String>(
                      initialValue: _cityId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Город',
                        isDense: true,
                      ),
                      items: [
                        for (final city in retailCities)
                          DropdownMenuItem<String>(
                            value: city.id,
                            child: Text(city.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _cityId = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      initialValue: _storeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Магазин',
                        isDense: true,
                      ),
                      items: [
                        for (final store in storeChains)
                          DropdownMenuItem<String>(
                            value: store.id,
                            child: Text(store.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _storeId = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            _FormSection(
              title: 'Ограничения',
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final allergen in Allergen.values)
                    FilterChip(
                      label: Text(allergen.label),
                      selected: _excludedAllergens.contains(allergen),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _excludedAllergens.add(allergen);
                          } else {
                            _excludedAllergens.remove(allergen);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            _FormSection(
              title: 'Оформление',
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  ChoiceChip(
                    label: const Text('Светлая'),
                    selected: themeController?.mode != ThemeMode.dark,
                    onSelected: (_) =>
                        themeController?.setMode(ThemeMode.light),
                  ),
                  ChoiceChip(
                    label: const Text('Тёмная'),
                    selected: themeController?.mode == ThemeMode.dark,
                    onSelected: (_) => themeController?.setMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              child: Text(widget.submitLabel),
            ),
            const SizedBox(height: 8),
            Text(
              'Цены ищутся по выбранному магазину при раскрытии списка покупок. '
              'Сейчас подключён Магнит.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
            if (widget.onImport != null || widget.onReset != null) ...[
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  if (widget.onImport != null)
                    TextButton(
                      onPressed: widget.onImport,
                      child: const Text('Импорт рецептов'),
                    ),
                  if (widget.onReset != null)
                    TextButton(
                      onPressed: widget.onReset,
                      child: const Text('Сбросить профиль'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 430,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/recipes/wb_21678.jpg',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC07110C)],
                  stops: [0.45, 1],
                ),
              ),
            ),
            const Positioned(
              left: 22,
              right: 22,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Неделя еды, которая\nсходится с вашей нормой',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Без случайных цен и блюд «на глаз». Сначала профиль, потом меню.',
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FormDivider(),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        child,
        const SizedBox(height: 10),
      ],
    );
  }
}

class _FormDivider extends StatelessWidget {
  const _FormDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
