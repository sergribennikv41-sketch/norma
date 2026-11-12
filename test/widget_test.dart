import 'package:flutter_test/flutter_test.dart';
import 'package:norma/app.dart';
import 'package:norma/core/data/in_memory_recipe_repository.dart';
import 'package:norma/core/data/session_storage.dart';
import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/seed_fixture.dart';

void main() {
  late InMemoryRecipeRepository repository;
  setUpAll(() {
    repository = loadSeedRepository();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('онбординг и переход к рациону', (tester) async {
    await tester.pumpWidget(NormaApp(repository: repository));

    expect(find.text('Рацион под вас'), findsOneWidget);
    expect(find.text('Рассчитать рацион'), findsOneWidget);

    await tester.ensureVisible(find.text('Рассчитать рацион'));
    await tester.tap(find.text('Рассчитать рацион'));
    await tester.pumpAndSettle();

    expect(find.text('Ваш рацион'), findsOneWidget);
    expect(find.text('Норма на день'), findsOneWidget);

    await tester.tap(find.text('Каталог').first);
    await tester.pumpAndSettle();
    expect(find.text('Каталог'), findsWidgets);
  });

  testWidgets('сохранённая сессия сразу открывает рацион', (tester) async {
    await tester.pumpWidget(
      NormaApp(
        repository: repository,
        initialSession: const SavedSession(
          profile: UserProfile(
            sex: Sex.female,
            age: 32,
            heightCm: 168,
            weightKg: 64,
            activity: ActivityLevel.moderate,
            goal: Goal.lose,
            pace: Pace.medium,
          ),
          seed: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ваш рацион'), findsOneWidget);
    expect(find.text('Норма на день'), findsOneWidget);
  });
}
