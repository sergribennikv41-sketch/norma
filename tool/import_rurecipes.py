"""Import fully mapped recipes from the RuRecipes-93k parquet snapshot.

Download the parquet once:
https://huggingface.co/datasets/epishchik/RuRecipes-93k/resolve/main/data/train-00000-of-00001.parquet

Usage:
    py -3 tool/import_rurecipes.py --parquet C:\\path\\train.parquet

The importer keeps only recipes where every ingredient maps to the local
catalogue. This avoids inventing KBJU for unknown products.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import pyarrow.parquet as pq

sys.path.insert(0, str(Path(__file__).resolve().parent))
import import_vkuso as vkuso

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SEED = ROOT / 'assets/data/seed.json'
DEFAULT_IMAGES = ROOT / 'assets/images/recipes'


def normalize(value: object) -> str:
    return vkuso.normalize(value)


def grams_for(quantity: str, ingredient_id: str) -> float | None:
    text = normalize(quantity).replace(',', '.')
    match = re.search(
        r'(\d+(?:\.\d+)?)\s*(кг|г|мл|л|шт|ст\.?\s*л\.?|ч\.?\s*л\.?|зубч|стакан)',
        text,
    )
    if not match:
        return 0 if ingredient_id in vkuso.SPICES else None
    number = float(match.group(1))
    unit = match.group(2)
    if unit in ('кг', 'л'):
        return number * 1000
    if unit in ('мл', 'г'):
        return number
    if unit == 'шт':
        return number * vkuso.UNIT_GRAMS.get(ingredient_id, 100)
    if 'ст' in unit:
        return number * 15
    if 'ч' in unit:
        return number * 5
    if unit == 'зубч':
        return number * 5
    if unit == 'стакан':
        return number * 200
    return number


def parse_ingredients(raw: object, mapper: vkuso.Mapper, known: set[str]) -> list[dict] | None:
    if not isinstance(raw, list):
        return None
    mapped: dict[str, float] = {}
    total = 0.0
    for line in raw:
        if not isinstance(line, str) or ' - ' not in line:
            return None
        name, quantity = line.rsplit(' - ', 1)
        ingredient_id = mapper.match(name)
        if ingredient_id is None:
            return None
        if ingredient_id in vkuso.SPICES:
            continue
        if ingredient_id not in known:
            return None
        grams = grams_for(quantity, ingredient_id)
        if grams is None:
            return None
        if grams <= 0:
            continue
        total += grams
        mapped[ingredient_id] = mapped.get(ingredient_id, 0) + grams
    if total < 200 or len(mapped) < 4:
        return None
    return [
        {'ingredientId': ingredient_id, 'grams': round(grams, 1)}
        for ingredient_id, grams in mapped.items()
    ]


BREAKFAST_WORDS = (
    'омлет', 'яичниц', 'каша', 'овсяная каша', 'овсянка', 'овсяные хлопья',
    'гречнев', 'сырник', 'творожник', 'блин', 'оладь', 'тост', 'бутерброд',
    'сэндвич', 'завтрак', 'гранол', 'мюсли', 'шакшук', 'драник', 'вареник',
    'панкейк', 'вафл', 'круассан', 'творожная запеканка',
    'запеканка из творога', 'ленивые вареники',
)

DESSERT_WORDS = (
    'конфет', 'пирожн', 'торт', 'печенье', 'кекс', 'маффин', 'брауни',
    'бисквит', 'десерт', 'пудинг', 'желе', 'мусс', 'зефир', 'мармелад',
    'пирог', 'шарлотк', 'кулич', 'пахлав', 'эклер', 'рулет', 'тарт',
    'чизкейк', 'морожен', 'сгущ', 'карамел', 'безе', 'профитрол',
    'пончик', 'донат', 'суфле', 'сырки', 'пасха', 'трайфл', 'фондан',
    'крем', 'керд', 'курд', 'глясе', 'сорбет', 'запеченные яблоки', 'шоколадный соус',
)

SNACK_WORDS = (
    'йогурт', 'творог', 'фрукт', 'ягод', 'орех', 'гренк', 'коктейль',
    'шоколад',
)

SAVORY_ROLL_WORDS = ('рулет из сельди', 'баклажановые рулет')


def meal_types(title: str) -> list[str]:
    text = normalize(title)
    if 'тортилья' in text and 'омлет' in text:
        return ['breakfast', 'snack']
    if 'крем-суп' in text or 'суп' in text or 'салат' in text:
        return ['lunch', 'dinner']
    if any(word in text for word in SAVORY_ROLL_WORDS):
        return ['lunch', 'dinner']
    if 'запеканка из ветчины' in text or 'картофельная запеканка' in text:
        return ['lunch', 'dinner']
    if any(word in text for word in DESSERT_WORDS):
        return ['snack']
    if any(word in text for word in BREAKFAST_WORDS):
        return ['breakfast', 'snack']
    if 'запеканка' in text and any(
        word in text
        for word in ('творож', 'йогурт', 'банан', 'морков', 'рис', 'тыкв', 'макарон', 'сладк')
    ):
        return ['breakfast', 'snack']
    if any(word in text for word in SNACK_WORDS):
        return ['snack']
    return ['lunch', 'dinner']


def download_image(recipe_id: str, url: str, directory: Path) -> str | None:
    target = directory / f'{recipe_id}.jpg'
    if not url:
        return None
    normalized_url = url.replace('https://img1.russianfood.com', 'https://www.russianfood.com')
    try:
        request = urllib.request.Request(
            normalized_url,
            headers={'User-Agent': 'NormaRecipePilot/1.0 (local non-commercial prototype)'},
        )
        with urllib.request.urlopen(request, timeout=45) as response:
            target.write_bytes(response.read())
        return f'assets/images/recipes/{target.name}'
    except Exception as error:  # noqa: BLE001
        print(f'image error {recipe_id}: {error}')
        return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--parquet', type=Path, required=True)
    parser.add_argument('--seed', type=Path, default=DEFAULT_SEED)
    parser.add_argument('--limit', type=int, default=598)
    args = parser.parse_args()

    seed = json.loads(args.seed.read_text(encoding='utf-8'))
    known = {item['id'] for item in seed['ingredients']}
    mapper = vkuso.Mapper()
    rows = pq.read_table(args.parquet).to_pylist()

    candidates = []
    for row in rows:
        if not row.get('recipe'):
            continue
        ingredients = parse_ingredients(row.get('ingredients'), mapper, known)
        if ingredients is None:
            continue
        steps = [
            str(step).replace('\r', '\n').strip()
            for step in row['recipe']
            if str(step).strip()
        ]
        if not steps:
            continue
        candidates.append(
            {
                'title': str(row.get('title') or '').strip(),
                'link': str(row.get('link') or ''),
                'image_link': str(row.get('image_link') or ''),
                'ingredients': ingredients,
                'steps': steps,
                'mealTypes': meal_types(str(row.get('title') or '')),
            }
        )
    candidates.sort(key=lambda item: item['title'])
    selected = [item for item in candidates if item['title']][: args.limit]
    print(f'fully mapped with image: {len(candidates)}; selected: {len(selected)}')

    DEFAULT_IMAGES.mkdir(parents=True, exist_ok=True)
    recipes = []
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = [
            executor.submit(
                download_image,
                f'rf_{index}',
                item['image_link'],
                DEFAULT_IMAGES,
            )
            for index, item in enumerate(selected, 1)
        ]
        images = [future.result() for future in futures]

    for index, (item, image) in enumerate(zip(selected, images), 1):
        recipes.append(
            {
                'id': f'rf_{index}',
                'title': item['title'],
                'mealTypes': item['mealTypes'],
                'servings': 4,
                'minutes': 30,
                'ingredients': item['ingredients'],
                'steps': item['steps'],
                'image': image,
                'source': (
                    f"{item['link']}\n"
                    'Данные: RuRecipes-93k, CC BY-NC 4.0; '
                    'фото: russianfood.com.'
                ),
            }
        )

    seed['version'] = 22
    seed['replaceAllRecipes'] = True
    seed['recipes'] = recipes
    args.seed.write_text(
        json.dumps(seed, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    with_image = sum(1 for recipe in recipes if recipe['image'])
    print(f'written: {args.seed}; recipes={len(recipes)}; with_image={with_image}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
