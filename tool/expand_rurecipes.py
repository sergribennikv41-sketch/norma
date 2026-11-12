"""Append fully mapped RuRecipes recipes to the existing seed.

Existing recipes and their local image ids are preserved. New recipes get
sequential rf_* ids and small local JPEG previews, so the APK does not grow
by hundreds of megabytes.

Usage:
    py -3 tool/expand_rurecipes.py --parquet %TEMP%\\rurecipes.parquet --target 1000
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import pyarrow.parquet as pq
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import import_rurecipes as rr
import import_vkuso as vk

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SEED = ROOT / 'assets/data/seed.json'
DEFAULT_IMAGES = ROOT / 'assets/images/recipes'


def normalize(value: object) -> str:
    return rr.normalize(value)


def image_url(url: str) -> str:
    return url.replace('https://img1.russianfood.com', 'https://www.russianfood.com')


def download_thumbnail(recipe_id: str, url: str, directory: Path) -> str | None:
    if not url:
        return None
    target = directory / f'{recipe_id}.jpg'
    if target.exists() and target.stat().st_size > 2000:
        return f'assets/images/recipes/{target.name}'
    try:
        request = urllib.request.Request(
            image_url(url),
            headers={
                'User-Agent': (
                    'NormaRecipePilot/1.0 '
                    '(local non-commercial prototype)'
                )
            },
        )
        with urllib.request.urlopen(request, timeout=45) as response:
            raw = response.read()
        with Image.open(io.BytesIO(raw)) as image:
            image = image.convert('RGB')
            image.thumbnail((480, 360), Image.Resampling.LANCZOS)
            image.save(target, 'JPEG', quality=80, optimize=True)
        return f'assets/images/recipes/{target.name}'
    except Exception as error:  # noqa: BLE001
        print(f'image error {recipe_id}: {error}')
        target.unlink(missing_ok=True)
        return None


def load_candidates(parquet: Path, seed: dict, known: set[str]) -> list[dict]:
    mapper = vk.Mapper()
    rows = pq.read_table(parquet).to_pylist()
    existing_titles = {normalize(item.get('title')) for item in seed['recipes']}
    best: dict[str, dict] = {}
    for row in rows:
        title = str(row.get('title') or '').strip()
        if not title:
            continue
        key = normalize(title)
        if key in existing_titles:
            continue
        steps = [
            str(step).replace('\r', '\n').strip()
            for step in (row.get('recipe') or [])
            if str(step).strip()
        ]
        if not steps:
            continue
        ingredients = rr.parse_ingredients(row.get('ingredients'), mapper, known)
        if ingredients is None:
            continue
        image = str(row.get('image_link') or '').strip()
        if not image:
            continue
        total = sum(item['grams'] for item in ingredients)
        candidate = {
            'title': title,
            'link': str(row.get('link') or ''),
            'image_link': image,
            'ingredients': ingredients,
            'steps': steps,
            'mealTypes': rr.meal_types(title),
            'score': (len(ingredients), len(steps), total),
        }
        previous = best.get(key)
        if previous is None or candidate['score'] > previous['score']:
            best[key] = candidate
    return sorted(
        best.values(),
        key=lambda item: (-item['score'][0], -item['score'][1], -item['score'][2], item['title']),
    )


def make_recipe(recipe_id: str, item: dict, image: str) -> dict:
    return {
        'id': recipe_id,
        'title': item['title'],
        'mealTypes': item['mealTypes'],
        'servings': 4,
        'minutes': 30,
        'ingredients': item['ingredients'],
        'steps': item['steps'],
        'image': image,
        'source': (
            f"{item['link']}\n"
            'Источник: RuRecipes-93k, CC BY-NC 4.0; '
            'фото: russianfood.com.'
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--parquet', type=Path, required=True)
    parser.add_argument('--seed', type=Path, default=DEFAULT_SEED)
    parser.add_argument('--images', type=Path, default=DEFAULT_IMAGES)
    parser.add_argument('--target', type=int, default=1000)
    parser.add_argument('--workers', type=int, default=6)
    args = parser.parse_args()

    seed = json.loads(args.seed.read_text(encoding='utf-8'))
    known = {item['id'] for item in seed['ingredients']}
    existing = seed['recipes']
    need = max(0, args.target - len(existing))
    if need == 0:
        print(f'seed already has {len(existing)} recipes')
        return 0

    candidates = load_candidates(args.parquet, seed, known)
    print(f'existing: {len(existing)}; candidates: {len(candidates)}; need: {need}')
    if not candidates:
        return 1

    args.images.mkdir(parents=True, exist_ok=True)
    max_id = 0
    for recipe in existing:
        match = re.fullmatch(r'rf_(\d+)', str(recipe.get('id', '')))
        if match:
            max_id = max(max_id, int(match.group(1)))

    selected: list[dict] = []
    used_images: set[str] = set()
    cursor = 0
    next_id = max_id + 1
    while len(selected) < need and cursor < len(candidates):
        batch_size = min(need - len(selected) + 8, len(candidates) - cursor)
        batch = candidates[cursor : cursor + batch_size]
        cursor += batch_size
        items = []
        for item in batch:
            items.append((f'rf_{next_id}', item))
            next_id += 1
        with ThreadPoolExecutor(max_workers=max(1, args.workers)) as executor:
            images = list(
                executor.map(
                    lambda pair: download_thumbnail(
                        pair[0], pair[1]['image_link'], args.images
                    ),
                    items,
                )
            )
        for (recipe_id, item), image in zip(items, images):
            if image is None or len(selected) >= need:
                continue
            selected.append(make_recipe(recipe_id, item, image))
            used_images.add(image)
        print(f'progress: {len(selected)}/{need}')

    if len(selected) < need:
        print(f'warning: only {len(selected)} of {need} recipes selected')

    seed['recipes'].extend(selected)
    seed['version'] = max(int(seed.get('version', 0)) + 1, 24)
    seed['replaceAllRecipes'] = True
    args.seed.write_text(
        json.dumps(seed, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )

    for path in args.images.glob('rf_*.jpg'):
        asset = f'assets/images/recipes/{path.name}'
        if asset not in used_images and int(path.stem.split('_')[1]) > max_id:
            path.unlink(missing_ok=True)

    print(
        f'written: {args.seed}; recipes={len(seed["recipes"])}; '
        f'new={len(selected)}; seed_version={seed["version"]}'
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
