import 'dart:convert';
import 'dart:io';

import 'package:norma/core/models/enums.dart';
import 'package:norma/core/models/recipe.dart';
import 'package:norma/core/models/seed_bundle.dart';

const _proteinTitle = {
  'chicken_breast': 'Куриная грудка',
  'turkey_fillet': 'Индейка',
  'beef_chuck': 'Говядина',
  'salmon': 'Лосось',
  'cod': 'Треска',
  'shrimp': 'Креветки',
  'lentils': 'Чечевица',
  'canned_beans': 'Фасоль',
  'tuna_canned': 'Тунец',
};

const _proteinInstr = {
  'chicken_breast': 'курицей',
  'turkey_fillet': 'индейкой',
  'beef_chuck': 'говядиной',
  'salmon': 'лососем',
  'cod': 'треской',
  'shrimp': 'креветками',
  'lentils': 'чечевицей',
  'canned_beans': 'фасолью',
  'tuna_canned': 'тунцом',
  'egg': 'яйцом',
};

const _proteinAcc = {
  'chicken_breast': 'курицу',
  'turkey_fillet': 'индейку',
  'beef_chuck': 'говядину',
  'salmon': 'лосось',
  'cod': 'треску',
  'shrimp': 'креветки',
  'lentils': 'чечевицу',
  'canned_beans': 'фасоль',
  'tuna_canned': 'тунец',
  'egg': 'яйца',
};

const _grainTitle = {
  'buckwheat': 'гречкой',
  'brown_rice': 'бурым рисом',
  'pasta': 'пастой',
  'potato': 'картофелем',
  'sweet_potato': 'бататом',
};

const _grainAcc = {
  'buckwheat': 'гречку',
  'brown_rice': 'бурый рис',
  'pasta': 'пасту',
  'potato': 'картофель',
  'sweet_potato': 'батат',
};

const _vegTitle = {
  'broccoli': 'брокколи',
  'bell_pepper': 'болгарским перцем',
  'spinach': 'шпинатом',
  'carrot': 'морковью',
  'cabbage': 'капустой',
  'cucumber': 'огурцом',
  'tomato': 'помидором',
};

const _vegAcc = {
  'broccoli': 'брокколи',
  'bell_pepper': 'болгарский перец',
  'spinach': 'шпинат',
  'carrot': 'морковь',
  'cabbage': 'капусту',
  'cucumber': 'огурец',
  'tomato': 'помидор',
};

void main() {
  final file = File('assets/data/seed.json');
  final bundle = SeedBundle.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  );
  final signatures = bundle.recipes.map(_signature).toSet();
  final ids = bundle.recipes.map((recipe) => recipe.id).toSet();
  final added = <Recipe>[];

  void add(Recipe recipe) {
    if (ids.contains(recipe.id)) {
      return;
    }
    final signature = _signature(recipe);
    if (signatures.contains(signature)) {
      return;
    }
    ids.add(recipe.id);
    signatures.add(signature);
    added.add(recipe);
  }

  const bowls = <(String, String, String)>[
    ('chicken_breast', 'buckwheat', 'broccoli'),
    ('chicken_breast', 'buckwheat', 'carrot'),
    ('chicken_breast', 'brown_rice', 'bell_pepper'),
    ('chicken_breast', 'brown_rice', 'spinach'),
    ('chicken_breast', 'pasta', 'spinach'),
    ('chicken_breast', 'potato', 'carrot'),
    ('chicken_breast', 'sweet_potato', 'broccoli'),
    ('turkey_fillet', 'buckwheat', 'broccoli'),
    ('turkey_fillet', 'brown_rice', 'bell_pepper'),
    ('turkey_fillet', 'brown_rice', 'spinach'),
    ('turkey_fillet', 'pasta', 'carrot'),
    ('turkey_fillet', 'potato', 'cabbage'),
    ('turkey_fillet', 'sweet_potato', 'broccoli'),
    ('salmon', 'brown_rice', 'broccoli'),
    ('salmon', 'brown_rice', 'spinach'),
    ('salmon', 'potato', 'bell_pepper'),
    ('salmon', 'sweet_potato', 'spinach'),
    ('cod', 'buckwheat', 'broccoli'),
    ('cod', 'brown_rice', 'spinach'),
    ('cod', 'potato', 'carrot'),
    ('cod', 'pasta', 'bell_pepper'),
    ('shrimp', 'brown_rice', 'bell_pepper'),
    ('shrimp', 'pasta', 'tomato'),
    ('shrimp', 'buckwheat', 'spinach'),
    ('beef_chuck', 'buckwheat', 'cabbage'),
    ('beef_chuck', 'brown_rice', 'bell_pepper'),
    ('beef_chuck', 'pasta', 'broccoli'),
    ('beef_chuck', 'potato', 'carrot'),
    ('lentils', 'buckwheat', 'broccoli'),
    ('lentils', 'brown_rice', 'carrot'),
    ('lentils', 'potato', 'spinach'),
    ('canned_beans', 'buckwheat', 'spinach'),
    ('canned_beans', 'brown_rice', 'tomato'),
    ('canned_beans', 'potato', 'broccoli'),
  ];
  for (final (protein, grain, veg) in bowls) {
    add(_bowl(protein, grain, veg));
  }

  const salads = <(String, String, String)>[
    ('chicken_breast', 'cucumber', 'bell_pepper'),
    ('chicken_breast', 'cabbage', 'carrot'),
    ('turkey_fillet', 'cucumber', 'tomato'),
    ('tuna_canned', 'cucumber', 'spinach'),
    ('tuna_canned', 'cabbage', 'carrot'),
    ('shrimp', 'spinach', 'bell_pepper'),
    ('egg', 'cucumber', 'tomato'),
    ('egg', 'spinach', 'bell_pepper'),
    ('canned_beans', 'cucumber', 'tomato'),
    ('canned_beans', 'cabbage', 'carrot'),
  ];
  for (final (protein, veg1, veg2) in salads) {
    add(_salad(protein, veg1, veg2));
  }

  const soups = <(String, String)>[
    ('lentils', 'cabbage'),
    ('lentils', 'bell_pepper'),
    ('canned_beans', 'cabbage'),
    ('canned_beans', 'spinach'),
  ];
  for (final (base, veg) in soups) {
    add(_soup(base, veg));
  }

  add(
    _recipe(
      id: 'oats_apple_walnuts',
      title: 'Овсянка с яблоком и грецким орехом',
      types: {MealType.breakfast},
      minutes: 10,
      ingredients: [
        ('oats', 60),
        ('milk_25', 200),
        ('apple', 120),
        ('walnuts', 15),
        ('honey', 5),
      ],
      steps: [
        'Сварите овсяные хлопья на молоке.',
        'Добавьте нарезанное яблоко, орехи и мед.',
      ],
    ),
  );
  add(
    _recipe(
      id: 'oats_blueberry_almonds',
      title: 'Овсянка с черникой и миндалем',
      types: {MealType.breakfast},
      minutes: 10,
      ingredients: [
        ('oats', 60),
        ('milk_25', 200),
        ('blueberry', 80),
        ('almonds', 15),
        ('honey', 5),
      ],
      steps: [
        'Сварите овсяные хлопья на молоке.',
        'Добавьте чернику, миндаль и мед.',
      ],
    ),
  );
  add(
    _recipe(
      id: 'oats_water_apple',
      title: 'Овсянка на воде с яблоком',
      types: {MealType.breakfast},
      minutes: 10,
      ingredients: [
        ('oats', 60),
        ('apple', 120),
        ('walnuts', 15),
        ('honey', 5),
      ],
      steps: [
        'Сварите овсяные хлопья на воде.',
        'Добавьте яблоко, орехи и мед.',
      ],
    ),
  );
  add(
    _recipe(
      id: 'cottage_banana_walnuts',
      title: 'Творог с бананом и грецким орехом',
      types: {MealType.breakfast},
      minutes: 5,
      ingredients: [
        ('cottage_5', 200),
        ('banana', 100),
        ('walnuts', 15),
        ('honey', 5),
      ],
      steps: ['Выложите творог в миску.', 'Добавьте банан, орехи и мед.'],
    ),
  );
  add(
    _recipe(
      id: 'cottage_apple_honey',
      title: 'Творог с яблоком и медом',
      types: {MealType.breakfast},
      minutes: 5,
      ingredients: [('cottage_2', 200), ('apple', 150), ('honey', 10)],
      steps: ['Нарежьте яблоко.', 'Смешайте с творогом и добавьте мед.'],
    ),
  );
  add(
    _recipe(
      id: 'yogurt_banana_almonds',
      title: 'Йогурт с бананом и миндалем',
      types: {MealType.breakfast},
      minutes: 5,
      ingredients: [
        ('greek_yogurt', 200),
        ('banana', 100),
        ('almonds', 15),
        ('honey', 5),
      ],
      steps: [
        'Нарежьте банан.',
        'Смешайте с йогуртом, добавьте миндаль и мед.',
      ],
    ),
  );
  add(
    _recipe(
      id: 'omelet_broccoli_cheese',
      title: 'Омлет с брокколи и сыром',
      types: {MealType.breakfast},
      minutes: 15,
      ingredients: [
        ('egg', 150),
        ('milk_25', 30),
        ('broccoli', 100),
        ('hard_cheese', 30),
        ('olive_oil', 5),
      ],
      steps: [
        'Взбейте яйца с молоком.',
        'Обжарьте брокколи на масле и залейте яйцами.',
        'Готовьте под крышкой 4 минуты, посыпьте сыром.',
      ],
    ),
  );
  add(
    _recipe(
      id: 'toast_cheese_tomato',
      title: 'Тост с сыром и помидором',
      types: {MealType.breakfast},
      minutes: 10,
      ingredients: [
        ('bread_rye', 80),
        ('hard_cheese', 50),
        ('tomato', 100),
        ('olive_oil', 3),
      ],
      steps: ['Подсушите хлеб.', 'Выложите сыр и помидор, сбрызните маслом.'],
    ),
  );

  add(
    _recipe(
      id: 'snack_egg_cucumber',
      title: 'Яйцо с огурцом',
      types: {MealType.snack},
      minutes: 5,
      ingredients: [('egg', 100), ('cucumber', 150)],
      steps: ['Отварите яйцо.', 'Нарежьте огурец и подавайте.'],
    ),
  );
  add(
    _recipe(
      id: 'snack_cottage_banana',
      title: 'Творог с бананом',
      types: {MealType.snack},
      minutes: 5,
      ingredients: [('cottage_2', 150), ('banana', 100)],
      steps: ['Нарежьте банан.', 'Смешайте с творогом.'],
    ),
  );
  add(
    _recipe(
      id: 'snack_yogurt_orange',
      title: 'Йогурт с апельсином',
      types: {MealType.snack},
      minutes: 5,
      ingredients: [('greek_yogurt', 150), ('orange', 120)],
      steps: ['Очистите апельсин.', 'Подавайте с йогуртом.'],
    ),
  );
  add(
    _recipe(
      id: 'snack_apple_walnuts',
      title: 'Яблоко с грецким орехом',
      types: {MealType.snack},
      minutes: 3,
      ingredients: [('apple', 150), ('walnuts', 15)],
      steps: ['Нарежьте яблоко.', 'Добавьте орехи.'],
    ),
  );
  add(
    _recipe(
      id: 'snack_banana_almonds',
      title: 'Банан с миндалем',
      types: {MealType.snack},
      minutes: 3,
      ingredients: [('banana', 120), ('almonds', 15)],
      steps: ['Нарежьте банан.', 'Добавьте миндаль.'],
    ),
  );
  add(
    _recipe(
      id: 'snack_cottage_blueberry',
      title: 'Творог с черникой',
      types: {MealType.snack},
      minutes: 5,
      ingredients: [('cottage_2', 150), ('blueberry', 100)],
      steps: ['Смешайте творог с черникой.'],
    ),
  );

  final updated = SeedBundle(
    version: bundle.version + 1,
    ingredients: bundle.ingredients,
    recipes: [...bundle.recipes, ...added],
    prices: bundle.prices,
  );
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(updated.toJson())}\n',
  );
  stdout.writeln(
    'added ${added.length}, total ${updated.recipes.length}, '
    'version ${updated.version}',
  );
}

String _signature(Recipe recipe) {
  final ingredientIds =
      recipe.ingredients.map((ingredient) => ingredient.ingredientId).toList()
        ..sort();
  return ingredientIds.join('|');
}

Recipe _bowl(String protein, String grain, String veg) {
  final proteinGrams = protein == 'salmon' || protein == 'cod' ? 160.0 : 150.0;
  final grainGrams = grain == 'potato' || grain == 'sweet_potato'
      ? 200.0
      : 70.0;
  return _recipe(
    id: '${protein}_${grain}_$veg',
    title:
        '${_proteinTitle[protein]} с ${_grainTitle[grain]} и ${_vegTitle[veg]}',
    types: {MealType.lunch, MealType.dinner},
    minutes: 30,
    ingredients: [
      (protein, proteinGrams),
      (grain, grainGrams),
      (veg, 150),
      ('olive_oil', 6),
    ],
    steps: [
      'Отварите или запеките ${_grainAcc[grain]}.',
      'Обжарьте ${_proteinAcc[protein]} на масле до готовности.',
      'Добавьте ${_vegAcc[veg]} и готовьте 5 минут.',
      'Соедините, посолите и поперчите.',
    ],
  );
}

Recipe _salad(String protein, String veg1, String veg2) {
  final proteinGrams = protein == 'egg'
      ? 100.0
      : protein == 'tuna_canned'
      ? 120.0
      : 150.0;
  return _recipe(
    id: 'salad_${protein}_${veg1}_$veg2',
    title:
        'Салат с ${_proteinInstr[protein]}, ${_vegTitle[veg1]} и ${_vegTitle[veg2]}',
    types: {MealType.lunch},
    minutes: 15,
    ingredients: [
      (protein, proteinGrams),
      (veg1, 100),
      (veg2, 100),
      ('olive_oil', 5),
    ],
    steps: [
      'Нарежьте ${_vegAcc[veg1]} и ${_vegAcc[veg2]}.',
      protein == 'egg'
          ? 'Отварите яйца и нарежьте.'
          : protein == 'tuna_canned'
          ? 'Слейте жидкость из тунца.'
          : 'Подготовьте ${_proteinAcc[protein]}.',
      'Смешайте, посолите и заправьте маслом.',
    ],
  );
}

Recipe _soup(String base, String veg) {
  return _recipe(
    id: 'soup_${base}_$veg',
    title: 'Суп с ${_proteinInstr[base]} и ${_vegTitle[veg]}',
    types: {MealType.lunch},
    minutes: 35,
    ingredients: [
      (base, 70),
      (veg, 100),
      ('potato', 100),
      ('carrot', 80),
      ('onion', 60),
      ('tomato_paste', 20),
      ('olive_oil', 5),
    ],
    steps: [
      'Промойте ${_proteinAcc[base]}.',
      'Добавьте нарезанные картофель, морковь, лук и ${_vegAcc[veg]}.',
      'Варите 25 минут, в конце добавьте томатную пасту и масло.',
    ],
  );
}

Recipe _recipe({
  required String id,
  required String title,
  required Set<MealType> types,
  required int minutes,
  required List<(String, double)> ingredients,
  required List<String> steps,
}) {
  return Recipe(
    id: id,
    title: title,
    mealTypes: types,
    servings: 1,
    minutes: minutes,
    ingredients: [
      for (final (ingredientId, grams) in ingredients)
        RecipeIngredient(ingredientId: ingredientId, grams: grams),
    ],
    steps: steps,
  );
}
