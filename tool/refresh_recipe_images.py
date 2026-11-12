"""Refresh low-resolution recipe previews from the original image links.

The source host blocks direct requests from this machine, so images are
fetched through the public images.weserv.nl resizing proxy and stored as
480x360 WebP files. Existing files are kept when the proxy fails.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import pyarrow.parquet as pq
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SEED = ROOT / 'assets/data/seed.json'
DEFAULT_IMAGES = ROOT / 'assets/images/recipes'


def normalize(value: object) -> str:
    return re.sub(r'\s+', ' ', str(value).lower().replace('ё', 'е')).strip()


def proxy_url(source: str) -> str:
    source = source.replace('https://', '').replace('http://', '')
    path = source.split('/', 1)[1] if '/' in source else source
    return (
        'https://www-russianfood-com.translate.goog/'
        f'{path}?_x_tr_sl=auto&_x_tr_tl=en&_x_tr_hl=en'
    )


def download(source: str) -> bytes | None:
    url = proxy_url(source)
    for attempt in range(2):
        try:
            request = urllib.request.Request(
                url,
                headers={'User-Agent': 'Mozilla/5.0'},
            )
            with urllib.request.urlopen(request, timeout=15) as response:
                raw = response.read()
            with Image.open(io.BytesIO(raw)) as image:
                image = image.convert('RGB')
                image.thumbnail((360, 270), Image.Resampling.LANCZOS)
                output = io.BytesIO()
                image.save(output, 'WEBP', quality=76, method=6)
            return output.getvalue()
        except Exception:  # noqa: BLE001
            time.sleep(1.0 + attempt)
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--parquet', type=Path, required=True)
    parser.add_argument('--seed', type=Path, default=DEFAULT_SEED)
    parser.add_argument('--images', type=Path, default=DEFAULT_IMAGES)
    parser.add_argument('--from-id', type=int, default=1)
    parser.add_argument('--to-id', type=int, default=5000)
    parser.add_argument('--workers', type=int, default=4)
    args = parser.parse_args()

    seed = json.loads(args.seed.read_text(encoding='utf-8'))
    rows = pq.read_table(args.parquet).to_pylist()
    by_title = {
        normalize(row.get('title')): str(row.get('image_link') or '')
        for row in rows
        if row.get('title') and row.get('image_link')
    }

    selected = []
    for recipe in seed['recipes']:
        match = re.fullmatch(r'rf_(\d+)', str(recipe.get('id', '')))
        if not match:
            continue
        number = int(match.group(1))
        if number < args.from_id or number > args.to_id:
            continue
        source = by_title.get(normalize(recipe.get('title')))
        if source:
            selected.append((number, source))

    print(f'selected: {len(selected)}')

    def refresh(item: tuple[int, str]) -> tuple[int, bool]:
        number, source = item
        target = args.images / f'rf_{number}.webp'
        if target.exists() and target.stat().st_size > 12 * 1024:
            return number, True
        data = download(source)
        if data is None:
            return number, False
        target.write_bytes(data)
        return number, True

    updated = 0
    with ThreadPoolExecutor(max_workers=max(1, args.workers)) as executor:
        for index, (number, ok) in enumerate(
            executor.map(refresh, selected),
            1,
        ):
            if ok:
                updated += 1
            if index % 50 == 0:
                print(f'progress: {index}/{len(selected)}; updated={updated}')

    if updated:
        seed['version'] = max(int(seed.get('version', 0)) + 1, 29)
        args.seed.write_text(
            json.dumps(seed, ensure_ascii=False, indent=2) + '\n',
            encoding='utf-8',
        )
    print(f'updated: {updated}/{len(selected)}; seed_version={seed.get("version")}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
