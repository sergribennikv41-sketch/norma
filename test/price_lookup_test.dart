import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/data/in_memory_recipe_repository.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/plan_snapshot.dart';
import 'package:norma/core/models/user_profile.dart';
import 'package:norma/core/nutrition/targets_calculator.dart';
import 'package:norma/core/planner/menu_generator.dart';
import 'package:norma/core/price/price_lookup.dart';
import 'package:norma/features/plan/plan_page.dart';

import 'support/seed_fixture.dart';

void main() {
  late InMemoryRecipeRepository repository;
  setUpAll(() {
    repository = loadSeedRepository();
  });

  testWidgets('список покупок показывает загрузку и цену из магазина', (
    tester,
  ) async {
    const profile = UserProfile(
      sex: Sex.male,
      age: 30,
      heightCm: 180,
      weightKg: 80,
      activity: ActivityLevel.moderate,
      goal: Goal.lose,
      pace: Pace.medium,
      mealsPerDay: 4,
      cityId: 'kazan',
      storeId: 'lenta',
    );
    final targets = const TargetsCalculator().calculate(profile);
    final plan = const MenuGenerator().generate(
      profile: profile,
      targets: targets,
      repository: repository,
    );
    final fake = _FakePriceLookupService();
    addTearDown(fake.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: PlanPage(
          profile: profile,
          initialPlan: SavedPlan.fromWeeklyPlan(plan),
          repository: repository,
          priceLookup: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Цены: Лента · Казань'), findsOneWidget);

    final category = plan.shoppingList.first.ingredient.category;
    await tester.ensureVisible(find.text(category).first);
    await tester.tap(find.text(category).first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(fake.cityId, 'kazan');
    expect(fake.storeId, 'lenta');
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    fake.emitAll(price: 123.45);
    await tester.pump();

    expect(find.text('123 ₽'), findsWidgets);
  });
}

class _FakePriceLookupService implements PriceLookupService {
  final _controller = StreamController<PriceLookupEvent>.broadcast();
  List<PriceLookupItem> items = const [];
  String? cityId;
  String? storeId;

  @override
  Stream<PriceLookupEvent> lookup({
    required String cityId,
    required String storeId,
    required List<PriceLookupItem> items,
  }) {
    this.cityId = cityId;
    this.storeId = storeId;
    this.items = items;
    return _controller.stream;
  }

  void emitAll({required double price}) {
    for (final item in items) {
      _controller.add(
        PriceLookupEvent(
          ingredientId: item.id,
          state: PriceLookupState.found(
            PriceQuote(
              ingredientId: item.id,
              storeId: storeId ?? '',
              price: price,
              title: item.name,
            ),
          ),
        ),
      );
    }
  }

  @override
  void clearCache() {}

  Future<void> dispose() => _controller.close();
}
