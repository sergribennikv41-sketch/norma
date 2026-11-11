import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/recipe_repository.dart';
import '../../core/models/enums.dart';
import '../../core/models/retail.dart';
import '../../core/models/user_profile.dart';
import '../plan/plan_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.repository,
    this.initialProfile,
  });

  final RecipeRepository repository;
  final UserProfile? initialProfile;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
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

  String _formatDecimal(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
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
    final profile = UserProfile(
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
      dailyBudgetRub: null,
      excludedAllergens: Set.unmodifiable(_excludedAllergens),
      cityId: _cityId,
      storeId: _storeId,
    );
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(profile);
      return;
    }
    navigator.push(
      MaterialPageRoute<void>(
        builder: (context) =>
            PlanPage(profile: profile, repository: widget.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Норма')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Рацион под вас',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Норма КБЖУ и меню на неделю с учётом цели, активности и ограничений.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'О вас',
                      children: [
                        SegmentedButton<Sex>(
                          segments: [
                            for (final sex in Sex.values)
                              ButtonSegment<Sex>(
                                value: sex,
                                label: Text(sex.label),
                              ),
                          ],
                          selected: {_sex},
                          onSelectionChanged: (selection) {
                            setState(() => _sex = selection.first);
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                decoration: const InputDecoration(
                                  labelText: 'Возраст',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) =>
                                    _validateInt(value, 14, 90),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _heightController,
                                decoration: const InputDecoration(
                                  labelText: 'Рост, см',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [_decimalFilter],
                                validator: (value) =>
                                    _validateDouble(value, 120, 230),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                decoration: const InputDecoration(
                                  labelText: 'Вес, кг',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [_decimalFilter],
                                validator: (value) =>
                                    _validateDouble(value, 35, 250),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _SectionCard(
                      title: 'Активность и цель',
                      children: [
                        DropdownButtonFormField<ActivityLevel>(
                          initialValue: _activity,
                          decoration: const InputDecoration(
                            labelText: 'Активность',
                            border: OutlineInputBorder(),
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
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                        if (_goal != Goal.maintain) ...[
                          const SizedBox(height: 12),
                          Text('Темп', style: theme.textTheme.labelLarge),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
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
                        ],
                      ],
                    ),
                    _SectionCard(
                      title: 'Приёмы пищи',
                      children: [
                        Row(
                          children: [
                            Text(
                              '$_mealsPerDay в день',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Expanded(
                              child: Slider(
                                value: _mealsPerDay.toDouble(),
                                min: 3,
                                max: 5,
                                divisions: 2,
                                label: '$_mealsPerDay',
                                onChanged: (value) {
                                  setState(() => _mealsPerDay = value.round());
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _SectionCard(
                      title: 'Готовка и магазин',
                      children: [
                        Text(
                          'Максимальное время на готовку',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final option in const <int?>[15, 30, 45, null])
                              ChoiceChip(
                                label: Text(
                                  option == null ? 'Любое' : '$option мин',
                                ),
                                selected: _maxCookMinutes == option,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _maxCookMinutes = option);
                                  }
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _cityId,
                          decoration: const InputDecoration(
                            labelText: 'Город',
                            border: OutlineInputBorder(),
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
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _storeId,
                          decoration: const InputDecoration(
                            labelText: 'Магазин для цен',
                            border: OutlineInputBorder(),
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
                        const SizedBox(height: 8),
                        Text(
                          'Цены появятся в списке покупок при его раскрытии. '
                          'Сейчас подключён Магнит.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    _SectionCard(
                      title: 'Ограничения',
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Рассчитать рацион'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
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
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
