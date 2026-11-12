import 'package:flutter/material.dart';

import '../../core/models/meal_plan.dart';
import '../../core/models/retail.dart';
import '../../core/models/user_profile.dart';
import '../../core/price/price_lookup.dart';
import 'home_widgets.dart';

class ShoppingView extends StatelessWidget {
  const ShoppingView({
    super.key,
    required this.plan,
    required this.profile,
    required this.priceStates,
    required this.checkedIngredients,
    required this.onToggleIngredient,
    required this.onExpandCategory,
    required this.onRefreshPrices,
    required this.onCopy,
  });

  final WeeklyPlan plan;
  final UserProfile profile;
  final Map<String, PriceLookupState> priceStates;
  final Set<String> checkedIngredients;
  final void Function(String ingredientId, bool checked) onToggleIngredient;
  final ValueChanged<List<ShoppingItem>> onExpandCategory;
  final VoidCallback onRefreshPrices;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in plan.shoppingList) {
      grouped.putIfAbsent(item.ingredient.category, () => []).add(item);
    }
    final found = priceStates.values
        .where((state) => state.status == PriceLookupStatus.found)
        .toList();
    final total = found.fold<double>(
      0,
      (sum, state) => sum + (state.quote?.price ?? 0),
    );
    final progress = plan.shoppingList.isEmpty
        ? 0.0
        : found.length / plan.shoppingList.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Topbar(
                profile: profile,
                onRefresh: onRefreshPrices,
                onCopy: onCopy,
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 940;
                  final list = Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'По категориям',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontFamily: 'Unbounded',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Text(
                              'раскройте, чтобы найти цены',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        for (final entry in grouped.entries) ...[
                          _ShoppingCategory(
                            category: entry.key,
                            items: entry.value,
                            checkedIngredients: checkedIngredients,
                            priceStates: priceStates,
                            onToggleIngredient: onToggleIngredient,
                            onExpanded: onExpandCategory,
                          ),
                          const SizedBox(height: 9),
                        ],
                      ],
                    ),
                  );
                  final summary = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryCard(
                        profile: profile,
                        foundCount: found.length,
                        totalCount: plan.shoppingList.length,
                        total: total,
                        progress: progress,
                      ),
                      const SizedBox(height: 16),
                      const _HowItWorks(),
                    ],
                  );
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [list, const SizedBox(height: 16), summary],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 155, child: list),
                      const SizedBox(width: 22),
                      Expanded(flex: 85, child: summary),
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
  const _Topbar({
    required this.profile,
    required this.onRefresh,
    required this.onCopy,
  });

  final UserProfile profile;
  final VoidCallback onRefresh;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ПОКУПКИ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text('Список покупок', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Цены загружаются по требованию и не сохраняются на диск',
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
            StoreChip(profile: profile),
            OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_all_outlined, size: 16),
              label: const Text('Скопировать'),
            ),
            FilledButton(
              onPressed: onRefresh,
              child: const Text('Обновить цены'),
            ),
          ],
        );
        if (constraints.maxWidth < 820) {
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

class _ShoppingCategory extends StatelessWidget {
  const _ShoppingCategory({
    required this.category,
    required this.items,
    required this.checkedIngredients,
    required this.priceStates,
    required this.onToggleIngredient,
    required this.onExpanded,
  });

  final String category;
  final List<ShoppingItem> items;
  final Set<String> checkedIngredients;
  final Map<String, PriceLookupState> priceStates;
  final void Function(String ingredientId, bool checked) onToggleIngredient;
  final ValueChanged<List<ShoppingItem>> onExpanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(15),
        color: scheme.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        onExpansionChanged: (expanded) {
          if (expanded) {
            onExpanded(items);
          }
        },
        title: Text(
          category,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${items.length} '
          '${pluralRu(items.length, 'позиция', 'позиции', 'позиций')}',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10.5),
        ),
        children: [
          for (final item in items)
            _ShoppingRow(
              item: item,
              checked: checkedIngredients.contains(item.ingredient.id),
              priceState: priceStates[item.ingredient.id],
              onChanged: (checked) {
                onToggleIngredient(item.ingredient.id, checked);
              },
            ),
        ],
      ),
    );
  }
}

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    required this.item,
    required this.checked,
    required this.priceState,
    required this.onChanged,
  });

  final ShoppingItem item;
  final bool checked;
  final PriceLookupState? priceState;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child: Checkbox(
                value: checked,
                onChanged: (value) => onChanged(value ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                item.ingredient.name,
                style: TextStyle(
                  color: checked ? scheme.onSurfaceVariant : scheme.onSurface,
                  fontSize: 12,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(
              '${item.grams.round()} г',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
            ),
            const SizedBox(width: 10),
            PriceBadge(state: priceState),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.profile,
    required this.foundCount,
    required this.totalCount,
    required this.total,
    required this.progress,
  });

  final UserProfile profile;
  final int foundCount;
  final int totalCount;
  final double total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Итог',
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
                'оценка',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: CalorieRing(
              value: progress,
              label: total.round().toString(),
              caption: 'рублей',
              size: 120,
              strokeWidth: 9,
            ),
          ),
          const SizedBox(height: 12),
          _Line(label: 'Найдено цен', value: '$foundCount из $totalCount'),
          _Line(label: 'Магазин', value: storeChainById(profile.storeId).name),
          _Line(label: 'Город', value: retailCityById(profile.cityId).name),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Если цена не нашлась, позиция остаётся с прочерком. '
              'Мы не подставляем случайное число.',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Как это работает',
            style: TextStyle(
              fontFamily: 'Unbounded',
              color: scheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 12),
          const _Step(
            number: '1',
            text: 'Раскройте категорию — у каждой позиции появится индикатор загрузки.',
          ),
          const _Step(
            number: '2',
            text: 'Цена приходит из каталога выбранного магазина и сразу показывается.',
          ),
          const _Step(
            number: '3',
            text: 'Кэш живёт только до закрытия приложения. Старые цены не хранятся.',
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
