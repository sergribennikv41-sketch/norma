"""Enrich recipe time and servings from russianfood.com metadata.

The parquet snapshot has no time/servings columns. The source page meta
description usually contains values like "20 мин., на 2 порции". We use
those values where possible and a conservative fallback otherwise.

Usage:
    py -3 tool/enrich_rurecipes.py --limit 50
    py -3 tool/enrich_rurecipes.py
"""

from __future__ import annotations

import argparse
import gzip
import html
import json
import os
import re
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SEED = ROOT / 'assets/data/seed.json'
DEFAULT_CACHE = Path(os.environ.get('TEMP', '.')) / 'norma_recipe_meta.json'

USER_AGENT = (
    'NormaRecipePilot/1.0 '
    '(local non-commercial prototype; metadata enrichment)'
)


def page_text(url: str) -> str:
    request = urllib.request.Request(
        url,
        headers={'User-Agent': USER_AGENT, 'Accept-Encoding': 'gzip'},
    )
    with urllib.request.urlopen(request, timeout=35) as response:
        raw = response.read()
        if response.headers.get('Content-Encoding') == 'gzip':
            raw = gzip.decompress(raw)
    for encoding in ('cp1251', 'utf-8'):
        try:
            return raw.decode(encoding)
        except UnicodeDecodeError:
            continue
    return raw.decode('cp1251', 'replace')


def parse_meta(text: str) -> tuple[int | None, int | None]:
    description = ''
    match = re.search(
        r'<META\s+name="description"\s+content="(.*?)">',
        text,
        re.I | re.S,
    )
    if match:
        description = html.unescape(match.group(1))

    servings = None
    minutes = None
    if description:
        found = re.search(r'(\d+)\s*порц', description, re.I)
        if found:
            servings = int(found.group(1))
        found = re.search(r'(\d+)\s*мин', description, re.I)
        if found:
            minutes = int(found.group(1))

    if servings is None or minutes is None:
        header = re.search(
            r'(\d+)\s+порц\w*\s+(\d+)\s+мин',
            text,
            re.I,
        )
        if header:
            servings = servings or int(header.group(1))
            minutes = minutes or int(header.group(2))
    return servings, minutes


def fetch_meta(url: str) -> dict:
    try:
        text = page_text(url)
        servings, minutes = parse_meta(text)
        return {
            'servings': servings,
            'minutes': minutes,
            'status': 'ok',
            'fetched_at': int(time.time()),
        }
    except Exception as error:  # noqa: BLE001
        return {
            'servings': None,
            'minutes': None,
            'status': f'error: {error}',
            'fetched_at': int(time.time()),
        }


def total_grams(recipe: dict) -> float:
    return sum(float(item.get('grams', 0)) for item in recipe['ingredients'])


def fallback_servings(recipe: dict) -> int:
    total = total_grams(recipe)
    types = set(recipe.get('mealTypes', []))
    if types == {'snack'}:
        portion = 180.0
    elif 'breakfast' in types and 'lunch' not in types:
        portion = 250.0
    else:
        portion = 350.0
    return max(1, min(12, round(total / portion)))


def fallback_minutes(recipe: dict) -> int:
    steps = ' '.join(recipe.get('steps', [])).lower()
    minutes = 10 + 4 * len(recipe.get('steps', []))
    if any(word in steps for word in ('запека', 'варить', 'тушить', 'жарить')):
        minutes += 15
    if any(word in steps for word in ('маринова', 'охлажда', 'настаива')):
        minutes += 20
    return max(10, min(180, minutes))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--seed', type=Path, default=DEFAULT_SEED)
    parser.add_argument('--cache', type=Path, default=DEFAULT_CACHE)
    parser.add_argument('--limit', type=int, default=0)
    parser.add_argument('--workers', type=int, default=8)
    args = parser.parse_args()

    seed = json.loads(args.seed.read_text(encoding='utf-8'))
    recipes = seed['recipes']
    if args.limit:
        recipes = recipes[: args.limit]

    cache: dict[str, dict] = {}
    if args.cache.exists():
        try:
            raw = json.loads(args.cache.read_text(encoding='utf-8'))
            if isinstance(raw, dict):
                cache = raw
        except Exception:
            cache = {}

    urls = []
    for recipe in recipes:
        source = str(recipe.get('source') or '')
        url = source.split('\n', 1)[0].strip()
        if url.startswith('http'):
            urls.append((recipe['id'], url))

    pending = [(recipe_id, url) for recipe_id, url in urls if url not in cache]
    print(f'recipes: {len(recipes)}; urls: {len(urls)}; cached: {len(urls) - len(pending)}')

    if pending:
        with ThreadPoolExecutor(max_workers=max(1, args.workers)) as executor:
            results = list(
                executor.map(lambda pair: (pair[1], fetch_meta(pair[1])), pending)
            )
        for url, result in results:
            cache[url] = result
        args.cache.write_text(
            json.dumps(cache, ensure_ascii=False, indent=2) + '\n',
            encoding='utf-8',
        )

    updated_time = 0
    updated_servings = 0
    for recipe in recipes:
        url = str(recipe.get('source') or '').split('\n', 1)[0].strip()
        meta = cache.get(url, {})
        minutes = meta.get('minutes')
        servings = meta.get('servings')
        if isinstance(minutes, int) and 1 <= minutes <= 600:
            recipe['minutes'] = minutes
            updated_time += 1
        else:
            recipe['minutes'] = fallback_minutes(recipe)
        if isinstance(servings, int) and 1 <= servings <= 30:
            recipe['servings'] = servings
            updated_servings += 1
        else:
            recipe['servings'] = fallback_servings(recipe)

    if not args.limit:
        seed['version'] = max(int(seed.get('version', 0)) + 1, 27)
        args.seed.write_text(
            json.dumps(seed, ensure_ascii=False, indent=2) + '\n',
            encoding='utf-8',
        )
    print(
        f'updated time={updated_time}; updated servings={updated_servings}; '
        f'total={len(recipes)}; seed_version={seed.get("version")}'
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
