"""Import a curated pilot from chipslays/russian-recipes-parser.

The parser repository is not bundled. Clone it once and pass --source:

    git clone --depth 1 https://github.com/chipslays/russian-recipes-parser.git
    py -3 tool/import_vkuso.py --source russian-recipes-parser/storage/recipes

The generated seed deliberately keeps only recipes whose ingredients can be
mapped to the local ingredient catalogue. Unknown ingredients are rejected.
"""

from __future__ import annotations

import argparse
import glob
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_BASE = ROOT / 'test/fixtures/seed_legacy.json'
DEFAULT_OUTPUT = ROOT / 'assets/data/seed.json'
SOURCE_REPO = 'https://github.com/chipslays/russian-recipes-parser'
SOURCE_SITE = 'https://vkuso.ru'

ALIASES = {
    'chicken_breast': ['куриная грудка', 'куриное филе', 'куриного филе', 'куриной грудки', 'филе куриное', 'филе грудки', 'грудка куриная', 'курица'],
    'beef_chuck': ['говядина', 'говядины', 'говяжье мясо', 'телятина'],
    'egg': ['яйцо', 'яйца', 'яиц', 'яичный'],
    'cottage_5': ['творог'],
    'greek_yogurt': ['греческий йогурт', 'йогурт'],
    'milk_25': ['молоко'],
    'feta': ['фета'],
    'hard_cheese': ['сыр твердый', 'сыр твёрдый', 'твердый сыр', 'твёрдый сыр', 'сыр'],
    'brown_rice': ['рис бурый', 'бурый рис'],
    'potato': ['картофель', 'картошка'],
    'olive_oil': ['масло оливковое', 'оливковое масло'],
    'butter': ['масло сливочное', 'сливочное масло'],
    'cucumber': ['огурцы свежие', 'огурец', 'огурцы'],
    'tomato': ['помидор', 'томат', 'помидоры', 'томаты'],
    'bell_pepper': ['перец болгарский', 'болгарский перец', 'перец сладкий', 'сладкий перец'],
    'cabbage': ['капуста белокочанная', 'белокочанная капуста', 'капуста'],
    'carrot': ['морковь', 'морковка'],
    'onion': ['лук репчатый', 'репчатый лук', 'лук'],
    'spinach': ['шпинат'],
    'apple': ['яблоко', 'яблоки'],
    'banana': ['банан', 'бананы'],
    'orange': ['апельсин'],
    'almonds': ['миндаль'],
    'walnuts': ['грецкий орех', 'грецкие орехи'],
    'salmon': ['лосось', 'семга', 'сёмга'],
    'cod': ['треска'],
    'tomato_paste': ['томатная паста', 'томатный соус'],
    'honey': ['мед', 'мёд'],
    'beetroot': ['свекла', 'свёкла'],
    'capers': ['каперсы'],
    'cream': ['сливки'],
    'eggplant': ['баклажан', 'баклажаны'],
    'flour': ['мука пшеничная', 'мука'],
    'garlic': ['чеснок', 'зубчик'],
    'green_peas': ['горошек зеленый', 'зеленый горошек', 'горошек'],
    'greens': ['зелень', 'укроп', 'петрушка', 'зеленый лук', 'зелёный лук', 'базилик', 'кинза', 'тимьян'],
    'jam': ['варенье', 'джем'],
    'lamb': ['баранина'],
    'lemon': ['лимон'],
    'mushrooms': ['шампиньоны', 'грибы'],
    'pickle': ['огурцы соленые', 'соленые огурцы', 'огурцы маринованные'],
    'pork': ['свинина', 'свинины'],
    'sour_cream': ['сметана'],
    'sugar': ['сахар'],
    'sunflower_oil': ['масло подсолнечное', 'подсолнечное масло', 'растительное масло', 'масло растительное', 'масло растительное рафинированное', 'масло растительное без запаха'],
    'wine': ['вино'],
    'yeast': ['дрожжи'],
    'zucchini': ['кабачок', 'кабачки'],
    'herring': ['сельдь'],
    'kefir': ['кефир'],
    'bacon': ['бекон'],
    'bread_white': ['хлеб белый', 'хлеб'],
    'breadcrumbs': ['сухари панировочные', 'панировочные сухари', 'сухари'],
    'liver': ['печень'],
    'mayonnaise': ['майонез'],
    'starch': ['крахмал'],
    'prunes': ['чернослив'],
    'raisins': ['изюм'],
    'chocolate': ['шоколад'],
    'cocoa': ['какао-порошок', 'какао'],
    'ground_beef': ['фарш говяжий', 'говяжий фарш', 'фарш'],
    'ham': ['ветчина'],
    'millet': ['пшено'],
    'pumpkin': ['тыква'],
    'sauerkraut': ['капуста квашеная', 'квашеная капуста'],
    'turnip': ['репа'],
    'celery': ['сельдерей'],
    'mustard': ['горчица'],
    'sesame': ['кунжут'],
}

EXTRA_INGREDIENTS = {
    'buckwheat': {
        'name': 'Гречка', 'category': 'Крупы и макароны',
        'per100g': (343, 13.3, 3.4, 71.5), 'keys': ['гречка', 'гречневая крупа'],
        'allergens': [],
    },
    'oats': {
        'name': 'Овсяные хлопья', 'category': 'Крупы и макароны',
        'per100g': (352, 12.3, 6.1, 61.8), 'keys': ['овсяные хлопья', 'овсянка', 'геркулес'],
        'allergens': [],
    },
    'white_rice': {
        'name': 'Рис белый (сухой)', 'category': 'Крупы и макароны',
        'per100g': (344, 6.7, 0.7, 78.9), 'keys': ['рис белый', 'белый рис', 'рис'],
        'allergens': [],
    },
    'pasta': {
        'name': 'Макароны (сухие)', 'category': 'Крупы и макароны',
        'per100g': (350, 12, 1.5, 70), 'keys': ['макароны', 'спагетти', 'лапша', 'вермишель'],
        'allergens': ['gluten'],
    },
    'chicken_thigh': {
        'name': 'Куриное бедро', 'category': 'Мясо и птица',
        'per100g': (185, 21, 10, 0), 'keys': ['куриное бедро', 'куриные бедра', 'бедро куриное'],
        'allergens': [],
    },
    'corn': {
        'name': 'Кукуруза консервированная', 'category': 'Овощи',
        'per100g': (119, 3.3, 1.2, 22.8), 'keys': ['кукуруза', 'кукуруза консервированная'],
        'allergens': [],
    },
    'beans': {
        'name': 'Фасоль (сухая)', 'category': 'Овощи',
        'per100g': (298, 21, 1.6, 45), 'keys': ['фасоль'],
        'allergens': [],
    },
    'salt': {
        'name': 'Соль', 'category': 'Специи',
        'per100g': (0, 0, 0, 0), 'keys': ['соль'],
        'allergens': [],
    },
    'pepper': {
        'name': 'Перец черный молотый', 'category': 'Специи',
        'per100g': (251, 10.4, 3.3, 38.7),
        'keys': ['перец черный', 'черный перец', 'перец молотый', 'перец'],
        'allergens': [],
    },
    'water': {
        'name': 'Вода', 'category': 'Напитки',
        'per100g': (0, 0, 0, 0), 'keys': ['вода'],
        'allergens': [],
    },
    'vinegar': {
        'name': 'Уксус', 'category': 'Специи',
        'per100g': (18, 0, 0, 0.9), 'keys': ['уксус'],
        'allergens': [],
    },
    'soda': {
        'name': 'Сода', 'category': 'Специи',
        'per100g': (0, 0, 0, 0), 'keys': ['сода'],
        'allergens': [],
    },
    'baking_powder': {
        'name': 'Разрыхлитель', 'category': 'Специи',
        'per100g': (0, 0, 0, 0), 'keys': ['разрыхлитель'],
        'allergens': [],
    },
    'spices': {
        'name': 'Специи', 'category': 'Специи',
        'per100g': (0, 0, 0, 0),
        'keys': ['специи', 'приправа', 'лавровый лист', 'корица', 'ванилин', 'ванильный сахар'],
        'allergens': [],
    },
}

SPICES = {'salt', 'pepper', 'water', 'vinegar', 'soda', 'baking_powder', 'spices'}
UNIT_GRAMS = {
    'egg': 55, 'onion': 100, 'potato': 150, 'tomato': 100, 'cucumber': 100,
    'carrot': 80, 'apple': 150, 'banana': 120, 'lemon': 100, 'garlic': 5,
    'bell_pepper': 150, 'beetroot': 100, 'eggplant': 200, 'zucchini': 200,
    'chicken_breast': 200, 'chicken_thigh': 200, 'beef_chuck': 200, 'pork': 200,
    'ground_beef': 200, 'hard_cheese': 30, 'feta': 30, 'cottage_5': 100,
    'butter': 10, 'olive_oil': 15, 'sunflower_oil': 15, 'sour_cream': 20,
    'mayonnaise': 15, 'honey': 21, 'sugar': 20, 'flour': 10,
    'tomato_paste': 25, 'bread_white': 30, 'mushrooms': 100, 'salmon': 150,
    'cod': 150, 'herring': 150, 'liver': 150, 'bacon': 30, 'ham': 30,
}
CATEGORY_MEALS = {
    'салаты': ['lunch', 'dinner'],
    'закуски': ['lunch', 'dinner'],
    'супы': ['lunch', 'dinner'],
    'вторые блюда': ['lunch', 'dinner'],
    'выпечка': ['breakfast', 'snack'],
    'десерты': ['snack'],
}

CATEGORY_QUOTAS = [
    ('Супы', 13),
    ('Салаты', 26),
    ('Закуски', 30),
    ('Вторые блюда', 50),
    ('Выпечка', 35),
    ('Десерты', 25),
]

# Локальные иллюстративные фото из Wikimedia Commons. Они не выдаются за
# фотографию конкретного блюда, но дают стабильную картинку без зависимости
# от доступности vkuso.ru.
PHOTOS = {
    'salad': ('assets/images/recipes/wb_19131.jpg', 'Loyna / Off-shell, CC BY-SA 2.5'),
    'soup': ('assets/images/recipes/wb_4431.jpg', 'Pannet, CC BY-SA 4.0'),
    'meat': ('assets/images/recipes/wb_31772.jpg', 'Lesya Dolyk, CC BY-SA 2.0'),
    'fish': ('assets/images/recipes/wb_21607.jpg', 'User:Justinc, CC BY-SA 2.0'),
    'baking': ('assets/images/recipes/wb_27663.jpg', 'cara fealy choate, CC BY 2.0'),
    'bread': ('assets/images/recipes/wb_21684.jpg', 'Arnaud 25, CC BY-SA 4.0'),
    'dessert': ('assets/images/recipes/wb_23328.jpg', 'Conan, CC BY 2.0'),
    'breakfast': ('assets/images/recipes/wb_21678.jpg', 'Tamorlan, CC BY-SA 3.0'),
    'snack': ('assets/images/recipes/wb_21720.jpg', 'E4024, CC BY-SA 4.0'),
    'side': ('assets/images/recipes/wb_34929.jpg', 'Frank C. Müller, CC BY-SA 3.0'),
}


def photo_for(category: object, title: str) -> tuple[str, str]:
    c = normalize(category)
    t = normalize(title)
    if c == 'салаты':
        return PHOTOS['salad']
    if c == 'супы':
        return PHOTOS['soup']
    if c == 'десерты':
        return PHOTOS['dessert']
    if c == 'выпечка':
        if any(word in t for word in ('хлеб', 'булоч', 'батон', 'брецель')):
            return PHOTOS['bread']
        if any(word in t for word in ('печень', 'курабье', 'макарон')):
            return PHOTOS['snack']
        return PHOTOS['baking']
    if c == 'закуски':
        if any(word in t for word in ('рыб', 'сельд', 'лосос', 'треск')):
            return PHOTOS['fish']
        return PHOTOS['salad']
    if c == 'вторые блюда':
        if any(word in t for word in ('рыб', 'лосос', 'треск', 'сельд')):
            return PHOTOS['fish']
        if any(word in t for word in ('картоф', 'овощ', 'баклаж', 'кабач')):
            return PHOTOS['side']
        return PHOTOS['meat']
    if any(word in t for word in ('омлет', 'сырник', 'блин', 'олад', 'завтрак')):
        return PHOTOS['breakfast']
    return PHOTOS['meat']


def normalize(value: object) -> str:
    if value is None:
        return ''
    return re.sub(r'\s+', ' ', str(value).lower().replace('ё', 'е').strip())


class Mapper:
    def __init__(self) -> None:
        self.keys = []
        for ingredient_id, aliases in ALIASES.items():
            for alias in aliases:
                self.keys.append((normalize(alias), ingredient_id))
        for ingredient_id, data in EXTRA_INGREDIENTS.items():
            for alias in data['keys']:
                self.keys.append((normalize(alias), ingredient_id))
        self.keys.sort(key=lambda item: len(item[0]), reverse=True)

    def match(self, name: str) -> str | None:
        normalized = normalize(name)
        for alias, ingredient_id in self.keys:
            if alias in normalized:
                return ingredient_id
        return None


def parse_amount(item: dict, ingredient_id: str) -> float | None:
    value = item.get('value')
    unit = normalize(item.get('type'))
    amount = normalize(item.get('amount'))
    try:
        number = float(str(value).replace(',', '.')) if value not in (None, '') else None
    except ValueError:
        number = None
    if number is None:
        if 'по вкусу' in amount or 'щепот' in amount:
            return 0 if ingredient_id in SPICES else None
        match = re.search(r'(\d+(?:[.,]\d+)?)', amount)
        if match:
            number = float(match.group(1).replace(',', '.'))
        else:
            return 0 if ingredient_id in SPICES else None
    if unit in ('г', 'гр', 'грамм', 'g'):
        return number
    if unit in ('кг', 'kg'):
        return number * 1000
    if unit in ('мл', 'ml'):
        return number
    if unit in ('л', 'l'):
        return number * 1000
    if unit in ('шт.', 'шт', 'штук'):
        return number * UNIT_GRAMS.get(ingredient_id, 100)
    if unit in ('зубчик', 'зубчика', 'зубчиков', 'зуб.'):
        return number * 5
    if unit in ('ст.л.', 'ст.л', 'ст. ложка', 'ст.ложка', 'ст. ложки'):
        return number * UNIT_GRAMS.get(ingredient_id, 15)
    if unit in ('ч.л.', 'ч.л', 'ч. ложка', 'ч.ложка', 'ч. ложки'):
        return number * 5
    if unit in ('стакан', 'стакана', 'стаканов'):
        return number * 200
    if unit in ('пучок', 'пучка'):
        return number * 50
    if unit in ('щепотка', 'щепотки'):
        return number * 1
    return number


def parse_servings(groups: list[dict]) -> int:
    for group in groups:
        match = re.search(r'на\s+(\d+)\s+порц', normalize(group.get('name')), re.I)
        if match:
            return max(1, int(match.group(1)))
    return 2


def parse_minutes(value: object) -> int:
    text = normalize(value)
    match = re.search(r'(\d+)\s*час', text)
    if match:
        return int(match.group(1)) * 60
    match = re.search(r'(\d+)', text)
    return int(match.group(1)) if match else 30


def meal_types(category: object, title: str) -> list[str]:
    normalized = normalize(category)
    title_normalized = normalize(title)
    if any(token in title_normalized for token in ('омлет', 'сырник', 'блин', 'олад', 'каша', 'завтрак')):
        return ['breakfast']
    return CATEGORY_MEALS.get(normalized, ['lunch', 'dinner'])


def build_recipe(data: dict, mapper: Mapper) -> dict | None:
    groups = data.get('ingredients') or []
    instructions = data.get('instruction') or []
    if not groups or len(instructions) < 3:
        return None
    if not data.get('poster') or not data.get('cooktime'):
        return None
    category = data.get('category')
    if any(token in normalize(category) for token in ('соус', 'напит', 'заготов', 'консерв', 'маринад')):
        return None

    mapped_by_id = {}
    unknown = []
    total = 0.0
    for group in groups:
        for item in group.get('list', []):
            name = item.get('name')
            if not name:
                continue
            ingredient_id = mapper.match(name)
            if ingredient_id is None:
                unknown.append(name)
                continue
            grams = parse_amount(item, ingredient_id)
            if grams is None or grams <= 0:
                if ingredient_id not in SPICES:
                    unknown.append(name)
                continue
            if ingredient_id in SPICES:
                continue
            total += grams
            mapped_by_id[ingredient_id] = mapped_by_id.get(ingredient_id, 0) + grams
    if unknown:
        return None
    if total < 200 or len(mapped_by_id) < 4:
        return None
    mapped = [
        {'ingredientId': ingredient_id, 'grams': round(grams, 1)}
        for ingredient_id, grams in mapped_by_id.items()
    ]

    servings = parse_servings(groups)
    if total / servings < 70 or total / servings > 1200:
        return None

    steps = []
    for step in instructions:
        text = (step.get('text') or '').replace('\r', '\n').strip()
        text = re.sub(r'\n{2,}', '\n', text)
        if text:
            steps.append(text)
    if len(steps) < 3:
        return None

    title = (data.get('title') or '').strip()
    if not title:
        return None

    return {
        'title': title,
        'mealTypes': meal_types(category, title),
        'servings': servings,
        'minutes': parse_minutes(data.get('cooktime')),
        'ingredients': mapped,
        'steps': steps,
        'image': data.get('poster'),
        'source': (
            f"{data.get('source') or SOURCE_SITE}\n"
            f"Данные: Russian Recipes Parser ({SOURCE_SITE}); "
            "лицензия данных не указана."
        ),
        'category': category,
    }


def select_recipes(passed: list[dict]) -> list[dict]:
    grouped: dict[str, list[dict]] = {}
    for recipe in passed:
        grouped.setdefault(normalize(recipe.get('category')), []).append(recipe)
    selected = []
    for category, quota in CATEGORY_QUOTAS:
        selected.extend(grouped.get(normalize(category), [])[:quota])
    selected_ids = {recipe['id'] for recipe in selected}
    remaining = [recipe for recipe in passed if recipe['id'] not in selected_ids]
    remaining.sort(
        key=lambda recipe: (
            -len(recipe['ingredients']),
            recipe['category'] or '',
            recipe['title'],
        )
    )
    selected.extend(remaining[: max(0, 200 - len(selected))])
    return selected[:200]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--base-seed', type=Path, default=DEFAULT_BASE)
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument('--limit', type=int, default=200)
    args = parser.parse_args()

    base = json.loads(args.base_seed.read_text(encoding='utf-8'))
    base_ingredients = {item['id']: item for item in base['ingredients']}
    mapper = Mapper()

    passed = []
    rejected = Counter()
    files = glob.glob(str(args.source / '*' / '*.json'))
    for file in files:
        try:
            data = json.loads(Path(file).read_text(encoding='utf-8'))
        except Exception:
            rejected['bad json'] += 1
            continue
        recipe = build_recipe(data, mapper)
        if recipe is None:
            rejected['filtered'] += 1
            continue
        recipe['id'] = f"vk_{Path(file).stem}"
        if recipe['id'] in {item['id'] for item in passed}:
            continue
        passed.append(recipe)

    passed.sort(key=lambda recipe: (recipe['category'] or '', recipe['title']))
    selected = select_recipes(passed)[: args.limit]
    selected_ids = {recipe['id'] for recipe in selected}
    selected.sort(key=lambda recipe: (recipe['category'] or '', recipe['title']))

    existing = dict(base_ingredients)
    used_ids = {item['ingredientId'] for recipe in selected for item in recipe['ingredients']}
    new_ingredients = []
    for ingredient_id, data in EXTRA_INGREDIENTS.items():
        if ingredient_id not in used_ids:
            continue
        kcal, protein, fat, carbs = data['per100g']
        new_ingredients.append({
            'id': ingredient_id,
            'name': data['name'],
            'category': data['category'],
            'per100g': {
                'calories': kcal,
                'protein': protein,
                'fat': fat,
                'carbs': carbs,
            },
            'allergens': data['allergens'],
        })

    ingredients = list(base['ingredients']) + new_ingredients
    prices = {
        item['id']: item['pricePerKg']
        for item in base['ingredients']
        if 'pricePerKg' in item
    }
    for ingredient in ingredients:
        if ingredient['id'] in prices:
            ingredient['pricePerKg'] = prices[ingredient['id']]

    output = {
        'version': 20,
        'replaceAllRecipes': True,
        'ingredients': ingredients,
        'recipes': [
            {
                'id': recipe['id'],
                'title': recipe['title'],
                'mealTypes': recipe['mealTypes'],
                'servings': recipe['servings'],
                'minutes': recipe['minutes'],
                'ingredients': recipe['ingredients'],
                'steps': recipe['steps'],
                'image': None,
                'source': recipe['source'],
            }
            for recipe in selected
        ],
    }
    args.output.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    print(f'passed={len(passed)} selected={len(selected)} rejected={dict(rejected)}')
    print(Counter(recipe['category'] for recipe in selected).most_common())
    print(f'written: {args.output}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
