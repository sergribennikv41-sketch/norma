import argparse
import json
import re
import sys
from typing import Any

from playwright.sync_api import (
    Page,
    TimeoutError as PlaywrightTimeoutError,
    sync_playwright,
)

PRICE_RE = re.compile(r"(\d[\d\s\u00a0]*[.,]\d{2}|\d[\d\s\u00a0]*)\s*₽")
SIZE_RE = re.compile(r"(\d+(?:[.,]\d+)?)\s*(кг|г|мл|л)", re.IGNORECASE)
SKIP_LINE_RE = re.compile(
    r"^(?:-\d+%|\+\d+%|по карте|только у нас|суперцена|товар недели|"
    r"финальная цена|разный дизайн|новинка|1 шт)$",
    re.IGNORECASE,
)

QUERY_ALIASES = {
    "яйцо куриное": "яйца куриные с1",
    "молоко 2.5%": "молоко 2.5",
    "рис бурый (сухой)": "рис бурый",
    "гречка": "гречка ядрица",
    "овсяные хлопья": "овсяные хлопья геркулес",
    "масло сливочное": "масло сливочное 82.5",
}

NEGATIVE_RE = re.compile(
    r"соус|копчен|варено|обжар|готов|запеч|консерв|маринован|солен",
    re.IGNORECASE,
)


def emit(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=False), flush=True)


def normalize(value: str) -> str:
    value = value.lower().replace("ё", "е")
    value = re.sub(r"\([^)]*\)", " ", value)
    value = value.replace(",", ".")
    return re.sub(r"\s+", " ", value).strip()


def tokens(value: str) -> set[str]:
    return {part for part in re.split(r"[^0-9a-zа-я]+", normalize(value)) if part}


def parse_price(value: str) -> float | None:
    match = PRICE_RE.search(value)
    if not match:
        return None
    raw = (
        match.group(1)
        .replace(" ", "")
        .replace("\u00a0", "")
        .replace(",", ".")
    )
    try:
        price = float(raw)
    except ValueError:
        return None
    return price if price > 0 else None


def parse_unit(title: str) -> str | None:
    match = SIZE_RE.search(title)
    return match.group(0).replace(",", ".") if match else None


def parse_cards(body: str) -> list[dict[str, Any]]:
    start = body.find("Найден")
    if start < 0:
        start = body.find("По запросу")
    if start < 0:
        return []
    end = body.find("Приложение Магнит", start)
    block = body[start : end if end > start else len(body)]
    cards: list[dict[str, Any]] = []
    for chunk in block.split("В корзину"):
        lines = [line.strip() for line in chunk.splitlines() if line.strip()]
        price_index = next(
            (index for index, line in enumerate(lines) if "₽" in line),
            None,
        )
        if price_index is None:
            continue
        price = parse_price(lines[price_index])
        if price is None:
            continue
        title = None
        for line in lines[price_index + 1 :]:
            if "₽" in line or line.startswith("·") or "отзыв" in line:
                continue
            if re.fullmatch(r"[\d.,]+", line) or SKIP_LINE_RE.match(line):
                continue
            title = line
            break
        if not title:
            continue
        unit = parse_unit(" ".join(lines[price_index + 1 :]))
        cards.append(
            {
                "title": title,
                "price": price,
                "unit": unit,
            }
        )
    return cards


def stem(token: str) -> str:
    return token[:5] if len(token) > 5 else token


def choose_card(query: str, cards: list[dict[str, Any]]) -> dict[str, Any] | None:
    if not cards:
        return None
    query_stems = {stem(token) for token in tokens(query)}
    best = None
    best_score = -1
    for index, card in enumerate(cards):
        title_tokens = tokens(card["title"])
        title_stems = {stem(token) for token in title_tokens}
        overlap = len(query_stems & title_stems)
        score = overlap * 20 - index
        if NEGATIVE_RE.search(card["title"]):
            score -= 50
        if score > best_score:
            best = card
            best_score = score
    if best_score <= 0:
        return cards[0]
    return best


def close_cookie_banner(page: Page) -> None:
    for label in ("Хорошо, закрыть", "Хорошо"):
        button = page.get_by_role("button", name=label)
        if button.count() and button.first.is_visible():
            button.first.click()
            page.wait_for_timeout(300)
            return


def select_magnit_store(page: Page, city: str) -> None:
    page.goto("https://magnit.ru/", timeout=60000, wait_until="domcontentloaded")
    page.wait_for_timeout(1800)
    close_cookie_banner(page)

    header_button = page.get_by_role("button", name="Выбрать").first
    if header_button.count() and header_button.is_visible():
        header_button.click()
        page.wait_for_timeout(600)

    segments = page.locator(".pl-segment__field")
    if segments.count() >= 3:
        segments.nth(2).check(force=True)
        page.wait_for_timeout(600)

    choose = page.get_by_role("button", name="Выберите магазин").last
    if choose.count() and choose.is_visible():
        choose.click()
        page.wait_for_timeout(900)

    address = page.locator('input[placeholder="Адрес магазина"]')
    address.wait_for(state="visible", timeout=15000)
    address.fill(city)
    page.wait_for_timeout(2600)

    cards = page.locator(".pl-shop-select-shop-list-item")
    candidates = []
    for index in range(cards.count()):
        text = cards.nth(index).inner_text()
        if "Магнит у дома" in text:
            candidates.append((index, text))
    if not candidates:
        for index in range(cards.count()):
            text = cards.nth(index).inner_text()
            if "Ростов" in text or city.split("-")[0] in text:
                candidates.append((index, text))
    if not candidates:
        raise RuntimeError("Не удалось найти магазин в выбранном городе")

    preferred = next(
        (item for item in candidates if "Толстого" in item[1]),
        candidates[0],
    )
    cards.nth(preferred[0]).get_by_role("button", name="Выбрать").click()
    page.wait_for_timeout(2200)
    close_cookie_banner(page)


def search_magnit(page: Page, query: str) -> dict[str, Any] | None:
    effective = QUERY_ALIASES.get(query, query)
    search_input = page.locator("input").first
    search_input.fill(effective)
    search_input.press("Enter")
    try:
        page.wait_for_function(
            "(q) => {"
            " const text = document.body.innerText.toLowerCase();"
            " return text.includes('по запросу «' + q.toLowerCase() + '»')"
            "   || text.includes('не нашлось');"
            "}",
            arg=effective,
            timeout=15000,
        )
    except PlaywrightTimeoutError:
        page.wait_for_timeout(3000)
    page.wait_for_timeout(700)
    body = page.locator("body").inner_text()
    if "не нашлось товаров" in body.lower():
        return None
    cards = parse_cards(body)
    if not cards:
        page.wait_for_timeout(3000)
        body = page.locator("body").inner_text()
        cards = parse_cards(body)
    return choose_card(query, cards)


def run_magnit(page: Page, city: str, items: list[dict[str, str]]) -> None:
    try:
        select_magnit_store(page, city)
    except Exception as error:  # noqa: BLE001
        for item in items:
            emit(
                {
                    "id": item["id"],
                    "status": "failed",
                    "message": f"Не удалось выбрать магазин: {error}",
                }
            )
        return

    for item in items:
        query = normalize(item.get("name", ""))
        try:
            card = search_magnit(page, query)
        except PlaywrightTimeoutError:
            emit(
                {
                    "id": item["id"],
                    "status": "failed",
                    "message": "Магазин не ответил",
                }
            )
            continue
        except Exception as error:  # noqa: BLE001
            emit(
                {
                    "id": item["id"],
                    "status": "failed",
                    "message": str(error),
                }
            )
            continue
        if not card:
            emit({"id": item["id"], "status": "not_found"})
            continue
        emit(
            {
                "id": item["id"],
                "status": "found",
                "price": card["price"],
                "title": card["title"],
                "unit": card["unit"],
            }
        )


def main() -> int:
    sys.stdin.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser()
    parser.add_argument("--store", required=True)
    parser.add_argument("--city", required=True)
    args = parser.parse_args()

    raw = sys.stdin.read()
    payload = json.loads(raw) if raw.strip() else {}
    items = payload.get("items", [])
    if not isinstance(items, list) or not items:
        return 0

    if args.store != "magnit":
        for item in items:
            emit(
                {
                    "id": item["id"],
                    "status": "failed",
                    "message": "Этот магазин пока не подключён",
                }
            )
        return 0

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        page = browser.new_page(locale="ru-RU")
        try:
            run_magnit(page, args.city, items)
        finally:
            browser.close()
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(main())
