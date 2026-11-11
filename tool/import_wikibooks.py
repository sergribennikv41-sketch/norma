import html
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

API = "https://ru.wikibooks.org/w/api.php"
UA = "NormaRecipeImporter/1.0 (https://github.com/sergribennikv41-sketch/norma)"
SEED_PATH = "assets/data/seed.json"
IMAGE_DIR = "assets/images/recipes"
TARGET_RECIPES = 100
MAX_CANDIDATES = 420
MAX_PAGES = 1500

EXTRA = {
    "salt": ("Соль", "Бакалея", 0, 0, 0, 0, 15, []),
    "sugar": ("Сахар", "Бакалея", 400, 0, 0, 99.8, 80, []),
    "semolina": ("Манная крупа", "Крупы и макароны", 333, 10.3, 1.0, 70.6, 90, ["gluten"]),
    "flour": ("Мука пшеничная", "Бакалея", 342, 10.3, 1.1, 70.6, 80, ["gluten"]),
    "breadcrumbs": ("Сухари панировочные", "Бакалея", 395, 11.9, 5.1, 72.2, 200, ["gluten"]),
    "mayonnaise": ("Майонез", "Бакалея", 680, 2.4, 74.0, 2.6, 300, ["eggs"]),
    "green_peas": ("Горошек зелёный консервированный", "Бакалея", 55, 5.0, 0.2, 8.3, 250, []),
    "pickle": ("Огурцы солёные", "Овощи", 19, 0.8, 0.1, 4.4, 200, []),
    "sour_cream": ("Сметана 20%", "Молочные продукты", 206, 2.8, 20.0, 3.2, 350, ["lactose"]),
    "cream": ("Сливки 10%", "Молочные продукты", 119, 2.8, 10.0, 3.6, 400, ["lactose"]),
    "kefir": ("Кефир 2,5%", "Молочные продукты", 51, 3.0, 2.5, 4.0, 100, ["lactose"]),
    "garlic": ("Чеснок", "Овощи", 149, 6.4, 0.5, 33.0, 250, []),
    "beetroot": ("Свёкла", "Овощи", 43, 1.6, 0.2, 9.6, 80, []),
    "zucchini": ("Кабачок", "Овощи", 17, 0.6, 0.3, 4.6, 100, []),
    "eggplant": ("Баклажан", "Овощи", 25, 1.2, 0.1, 5.9, 150, []),
    "mushrooms": ("Шампиньоны", "Овощи", 27, 4.3, 1.0, 0.1, 250, []),
    "pork": ("Свинина", "Мясо и птица", 263, 18.0, 21.0, 0.0, 500, []),
    "lamb": ("Баранина", "Мясо и птица", 203, 18.0, 14.0, 0.0, 800, []),
    "herring": ("Сельдь", "Рыба и морепродукты", 161, 17.0, 9.0, 0.0, 500, ["fish"]),
    "millet": ("Пшено", "Крупы и макароны", 348, 11.5, 3.3, 69.3, 100, []),
    "pearl_barley": ("Перловка", "Крупы и макароны", 315, 9.3, 1.1, 73.7, 90, []),
    "peas_dry": ("Горох сушёный", "Крупы и макароны", 299, 20.5, 2.0, 53.3, 120, []),
    "olives": ("Маслины", "Бакалея", 115, 0.8, 10.7, 6.3, 900, []),
    "capers": ("Каперсы", "Бакалея", 23, 2.4, 0.9, 4.9, 1500, []),
    "yeast": ("Дрожжи", "Бакалея", 109, 12.7, 2.7, 36.4, 2000, []),
    "soda": ("Сода", "Бакалея", 0, 0, 0, 0, 100, []),
    "vinegar": ("Уксус", "Бакалея", 18, 0, 0, 0.9, 100, []),
    "wine": ("Вино", "Бакалея", 83, 0.1, 0.0, 2.6, 800, []),
    "jam": ("Варенье", "Бакалея", 250, 0.3, 0.0, 65.0, 400, []),
    "raisins": ("Изюм", "Фрукты и ягоды", 299, 2.5, 0.6, 79.0, 400, []),
    "prunes": ("Чернослив", "Фрукты и ягоды", 240, 2.3, 0.7, 57.5, 500, []),
    "dried_apricots": ("Курага", "Фрукты и ягоды", 241, 3.4, 0.5, 62.6, 600, []),
    "lemon": ("Лимон", "Фрукты и ягоды", 29, 1.1, 0.3, 9.3, 200, []),
    "strawberry": ("Клубника", "Фрукты и ягоды", 33, 0.8, 0.4, 7.5, 400, []),
    "cherry": ("Вишня", "Фрукты и ягоды", 52, 0.8, 0.2, 12.5, 300, []),
    "currant": ("Смородина", "Фрукты и ягоды", 56, 0.7, 0.2, 13.8, 400, []),
    "bread_white": ("Хлеб белый", "Хлеб", 265, 7.6, 3.2, 49.0, 150, ["gluten"]),
    "sunflower_oil": ("Масло подсолнечное", "Масла", 899, 0, 99.9, 0, 150, []),
    "sauerkraut": ("Капуста квашеная", "Овощи", 19, 1.8, 0.1, 4.4, 100, []),
    "greens": ("Зелень", "Овощи", 36, 3.7, 0.4, 8.0, 300, []),
    "liver": ("Печень", "Мясо и птица", 135, 19.0, 5.0, 0.0, 300, []),
    "bacon": ("Бекон", "Мясо и птица", 500, 20.0, 45.0, 0.0, 600, []),
    "starch": ("Крахмал", "Бакалея", 350, 0.3, 0.1, 85.0, 150, []),
    "turnip": ("Репа", "Овощи", 28, 1.1, 0.1, 6.2, 80, []),
    "pumpkin": ("Тыква", "Овощи", 26, 1.0, 0.1, 6.5, 80, []),
    "lettuce": ("Салат-латук", "Овощи", 15, 1.4, 0.2, 2.9, 300, []),
    "ground_beef": ("Фарш говяжий", "Мясо и птица", 250, 17.0, 20.0, 0.0, 600, []),
    "ham": ("Ветчина", "Мясо и птица", 145, 16.0, 8.0, 1.0, 600, []),
    "squid": ("Кальмары", "Рыба и морепродукты", 92, 15.6, 1.4, 2.5, 600, ["seafood"]),
    "mustard": ("Горчица", "Бакалея", 66, 4.0, 3.0, 4.0, 400, []),
    "tortilla": ("Тортилья", "Хлеб", 300, 8.0, 6.0, 50.0, 300, ["gluten"]),
    "chocolate": ("Шоколад", "Бакалея", 550, 5.0, 30.0, 60.0, 700, []),
    "cocoa": ("Какао-порошок", "Бакалея", 374, 20.0, 11.0, 32.0, 800, []),
    "sesame": ("Кунжут", "Орехи", 573, 17.7, 49.7, 12.2, 800, []),
    "poppy_seeds": ("Мак", "Бакалея", 525, 17.5, 41.8, 28.1, 900, []),
    "celery": ("Сельдерей", "Овощи", 13, 0.9, 0.1, 2.1, 250, []),
}

PIECE_WEIGHTS = {
    "egg": 55, "onion": 80, "carrot": 80, "potato": 150, "tomato": 100,
    "cucumber": 100, "apple": 150, "banana": 120, "orange": 150, "lemon": 100,
    "beetroot": 150, "bell_pepper": 120, "zucchini": 200, "eggplant": 200,
    "garlic": 5, "bread_rye": 30, "bread_white": 30, "pickle": 50,
    "mushrooms": 20, "herring": 150, "cod": 150, "salmon": 150,
    "chicken_breast": 150, "avocado": 150,
}

SPOON_WEIGHTS = {
    "sugar": 25, "flour": 10, "semolina": 20, "mayonnaise": 20, "honey": 20,
    "sour_cream": 20, "jam": 20, "olive_oil": 14, "sunflower_oil": 14,
    "butter": 20, "tomato_paste": 20,
}

CUP_WEIGHTS = {"flour": 130, "sugar": 200, "semolina": 160, "brown_rice": 190, "buckwheat": 170}

SYNONYMS = {
    "куриная грудка": "chicken_breast", "куриное филе": "chicken_breast",
    "курица": "chicken_breast", "куриное мясо": "chicken_breast",
    "индейка": "turkey_fillet", "филе индейки": "turkey_fillet",
    "говядина": "beef_chuck", "телятина": "beef_chuck",
    "свинина": "pork", "баранина": "lamb",
    "яйцо": "egg", "яйца": "egg", "яиц": "egg",
    "творог": "cottage_5", "творожный сыр": "cottage_5",
    "сметана": "sour_cream", "сливки": "cream", "кефир": "kefir",
    "йогурт": "greek_yogurt", "молоко": "milk_25",
    "сыр фета": "feta", "брынза": "feta", "фета": "feta",
    "сыр": "hard_cheese", "твердый сыр": "hard_cheese",
    "масло сливочное": "butter", "сливочное масло": "butter",
    "масло растительное": "sunflower_oil", "растительное масло": "sunflower_oil",
    "подсолнечное масло": "sunflower_oil", "оливковое масло": "olive_oil",
    "майонез": "mayonnaise", "соль": "salt",
    "сахар": "sugar", "сахарный песок": "sugar",
    "мука": "flour", "мука пшеничная": "flour",
    "манка": "semolina", "манная крупа": "semolina",
    "сухари": "breadcrumbs", "панировочные сухари": "breadcrumbs",
    "горошек": "green_peas", "зеленый горошек": "green_peas",
    "соленые огурцы": "pickle", "огурцы соленые": "pickle", "корнишоны": "pickle",
    "огурцы": "cucumber", "огурец": "cucumber",
    "помидор": "tomato", "помидоры": "tomato", "томат": "tomato",
    "перец болгарский": "bell_pepper", "сладкий перец": "bell_pepper",
    "капуста квашеная": "sauerkraut", "квашеная капуста": "sauerkraut",
    "капуста": "cabbage",
    "свекла": "beetroot", "свёкла": "beetroot",
    "морковь": "carrot", "морковка": "carrot",
    "лук": "onion", "луковица": "onion", "репчатый лук": "onion",
    "чеснок": "garlic", "кабачок": "zucchini", "кабачки": "zucchini",
    "баклажан": "eggplant", "баклажаны": "eggplant",
    "грибы": "mushrooms", "шампиньоны": "mushrooms",
    "шпинат": "spinach", "брокколи": "broccoli",
    "зелень": "greens", "петрушка": "greens", "укроп": "greens",
    "картофель": "potato", "картошка": "potato",
    "рис": "brown_rice", "рис бурый": "brown_rice",
    "гречка": "buckwheat", "гречневая крупа": "buckwheat",
    "пшено": "millet", "перловка": "pearl_barley", "перловая крупа": "pearl_barley",
    "макароны": "pasta", "вермишель": "pasta", "паста": "pasta",
    "хлеб": "bread_white", "батон": "bread_white", "белый хлеб": "bread_white",
    "горох": "peas_dry", "фасоль": "canned_beans",
    "томатная паста": "tomato_paste",
    "маслины": "olives", "оливки": "olives", "каперсы": "capers",
    "дрожжи": "yeast", "сода": "soda", "уксус": "vinegar", "вино": "wine",
    "варенье": "jam", "джем": "jam",
    "изюм": "raisins", "чернослив": "prunes", "курага": "dried_apricots",
    "орехи": "walnuts", "грецкие орехи": "walnuts", "миндаль": "almonds",
    "мед": "honey", "мёд": "honey",
    "яблоко": "apple", "яблоки": "apple", "банан": "banana",
    "апельсин": "orange", "лимон": "lemon", "черника": "blueberry",
    "клубника": "strawberry", "вишня": "cherry", "смородина": "currant",
    "лосось": "salmon", "семга": "salmon", "треска": "cod",
    "судак": "cod", "рыба": "cod", "сельдь": "herring",
    "креветки": "shrimp", "тунец": "tuna_canned",
    "фасоль консервированная": "canned_beans",
    "картофел": "potato", "морков": "carrot", "сметан": "sour_cream",
    "капуст": "cabbage", "курин": "chicken_breast", "говядин": "beef_chuck",
    "свинин": "pork", "баранин": "lamb", "рыб": "cod", "треск": "cod",
    "сельд": "herring", "лука": "onion", "чеснока": "garlic",
    "кабач": "zucchini", "гриб": "mushrooms", "мук": "flour", "сол": "salt",
    "яблок": "apple", "свекл": "beetroot", "фасол": "canned_beans",
    "горош": "green_peas", "макарон": "pasta", "вермишел": "pasta",
    "гречк": "buckwheat", "молок": "milk_25", "майонез": "mayonnaise",
    "печень": "liver", "печенк": "liver", "бекон": "bacon",
    "крахмал": "starch", "растительн": "sunflower_oil",
    "сливочн": "butter", "топлен": "butter", "огурц": "cucumber",
    "зелен": "greens", "корень петрушки": "greens",
    "куриное яйцо": "egg", "куриные яйца": "egg", "куриных яиц": "egg",
    "яйцо куриное": "egg", "яйца куриные": "egg",
    "перепелиное яйцо": "egg", "перепелиные яйца": "egg",
    "куриц": "chicken_breast", "оливков": "olive_oil",
    "подсолнечн": "sunflower_oil", "томатн": "tomato_paste",
    "фета": "feta", "феты": "feta", "фету": "feta", "фете": "feta",
    "брынз": "feta", "орех": "walnuts", "кураг": "dried_apricots",
    "дрожж": "yeast", "печени": "liver", "болгарск": "bell_pepper",
    "сладкий перец": "bell_pepper", "курят": "chicken_breast",
    "желток": "egg", "желтк": "egg", "фарш": "ground_beef",
    "ветчин": "ham", "кальмар": "squid", "репа": "turnip",
    "репы": "turnip", "репу": "turnip", "репе": "turnip",
    "тыкв": "pumpkin", "латук": "lettuce", "салат-латук": "lettuce",
    "горчиц": "mustard", "тортиль": "tortilla", "шоколад": "chocolate",
    "какао": "cocoa", "кунжут": "sesame", "мак": "poppy_seeds",
    "сельдерей": "celery", "сельдерея": "celery", "сельдерее": "celery",
}

UNIT_PATTERNS = [
    ("kg", r"кг"),
    ("g", r"г(?:р|рамм[а-я]*)?"),
    ("l", r"л"),
    ("ml", r"мл"),
    ("pcs", r"шт(?:ук[а-я]*)?"),
    ("tbsp", r"ст\.?\s*л\.?|столов[а-я]*\s*лож[а-я]*"),
    ("tsp", r"ч\.?\s*л\.?|чай[а-я]*\s*лож[а-я]*"),
    ("cup", r"стакан[а-я]*"),
    ("clove", r"зубчик[а-я]*"),
    ("pinch", r"щепотк[а-я]*"),
    ("bunch", r"пучок|пучка"),
]

SEASONINGS = ("соль", "перец", "специ", "приправ", "вода", "лавровый лист", "сода")
SKIP_NAMES = (
    "вод", "соль", "соли", "солью", "специ", "приправ", "лавров",
    "гвоздик", "кориц", "букет гарни", "тимьян", "мускат", "ванил",
    "разрыхлит", "сода", "соды", "соду", "уксус", "уксуса", "жир",
    "сало", "смалец", "бульон", "майоран", "тмин", "фенхел", "мята",
    "куркум", "сумах", "кервел", "паприк", "соус", "кипяток",
    "коньяк", "демиглас",
)

SKIP_EXACT = {"масло", "масла", "мясо", "мясной", "мясной фарш"}

PROTEIN_IDS = {
    "chicken_breast", "turkey_fillet", "beef_chuck", "pork", "lamb",
    "salmon", "cod", "herring", "shrimp", "tuna_canned", "egg",
    "lentils", "canned_beans", "liver", "bacon",
}

MEAT_FISH_IDS = {
    "chicken_breast", "turkey_fillet", "beef_chuck", "pork", "lamb",
    "salmon", "cod", "herring", "shrimp", "tuna_canned", "liver", "bacon",
}

UNKNOWN_COUNTS = {}
FAILURES = []


def api(params):
    params = {**params, "format": "json", "formatversion": "2"}
    url = API + "?" + urllib.parse.urlencode(params)
    request = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(request, timeout=40) as response:
        return json.load(response)


def category_members(limit=MAX_PAGES):
    members = []
    continuation = {}
    while len(members) < limit:
        data = api({
            "action": "query",
            "list": "categorymembers",
            "cmtitle": "Категория:Рецепты",
            "cmtype": "page",
            "cmlimit": "500",
            **continuation,
        })
        members.extend(data.get("query", {}).get("categorymembers", []))
        continuation = data.get("continue", {})
        if not continuation:
            break
        time.sleep(0.2)
    return members[:limit]


def fetch_pages(titles):
    pages = {}
    for start in range(0, len(titles), 50):
        batch = titles[start:start + 50]
        data = api({
            "action": "query",
            "prop": "revisions",
            "rvprop": "content",
            "rvslots": "main",
            "titles": "|".join(batch),
        })
        for page in data.get("query", {}).get("pages", []):
            revisions = page.get("revisions") or []
            if revisions:
                pages[page["title"]] = revisions[0]["slots"]["main"]["content"]
        time.sleep(0.2)
    return pages


def clean(text):
    if not text:
        return ""
    text = re.sub(r"<ref[^>]*/>", "", text)
    text = re.sub(r"<ref.*?</ref>", "", text, flags=re.S)
    text = re.sub(r"\{\{[^{}]*\}\}", "", text)
    text = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", text)
    text = re.sub(r"'{2,}", "", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = html.unescape(text)
    return re.sub(r"\s+", " ", text).strip(" \t\n\r.;")


def normalize_heading(value):
    return value.strip().strip(":").lower().replace("ё", "е")


def template_field(text, name):
    match = re.search(
        r"\|\s*" + re.escape(name) + r"\s*=\s*([^\n|}]*)",
        text,
        flags=re.I,
    )
    return clean(match.group(1)) if match else ""


def section(text, names):
    lines = text.splitlines()
    start = None
    heading = re.compile(r"^(==+)\s*([^=]+?)\s*\1\s*$")
    for index, line in enumerate(lines):
        match = heading.match(line.strip())
        if match and normalize_heading(match.group(2)) in names:
            start = index + 1
            break
    if start is None:
        return ""
    result = []
    for line in lines[start:]:
        if heading.match(line.strip()):
            break
        result.append(line)
    return "\n".join(result)


def parse_number(text):
    text = text.strip().replace(",", ".")
    text = text.replace("½", "0.5").replace("¼", "0.25").replace("¾", "0.75")
    if "-" in text or "–" in text:
        parts = re.split(r"[-–]", text)
        numbers = [parse_number(part) for part in parts]
        numbers = [number for number in numbers if number]
        return sum(numbers) / len(numbers) if numbers else None
    if "/" in text:
        left, right = text.split("/", 1)
        try:
            return float(left) / float(right)
        except ValueError:
            return None
    try:
        return float(text)
    except ValueError:
        return None


def split_unit(rest):
    for unit_name, pattern in UNIT_PATTERNS:
        unit_match = re.match(
            r"^(" + pattern + r")\.?(?:\s+|$)\s*(.*)$",
            rest,
            flags=re.I,
        )
        if unit_match:
            return unit_name, unit_match.group(2).strip()
    return None, rest.strip()


def unit_from_text(text):
    value = text.lower().strip()
    if not value:
        return None
    for unit_name, pattern in UNIT_PATTERNS:
        if re.fullmatch(pattern + r"\.?", value, flags=re.I):
            return unit_name
    return None


def parse_ingredient_line(line, meta):
    text = clean(line)
    text = re.sub(r"^[*#]+\s*", "", text)
    text = re.sub(r"^\d+[.)]\s*", "", text)
    if not text:
        return None
    lowered = text.lower().replace("ё", "е")
    if any(season in lowered for season in SEASONINGS) and not re.search(r"\d", text):
        return None

    quantity = None
    unit = None
    name = ""
    match = re.match(r"^(\d[\d\s.,/–-]*|½|¼|¾)\s*(.*)$", text)
    if match:
        quantity = parse_number(match.group(1))
        rest = match.group(2).strip()
        unit, name = split_unit(rest)
    else:
        match = re.search(
            r"(\d[\d\s.,/–-]*|½|¼|¾)\s*([а-яa-z.]*)\s*$",
            text,
            flags=re.I,
        )
        if not match:
            return None
        quantity = parse_number(match.group(1))
        unit = unit_from_text(match.group(2))
        name = text[: match.start()].strip(" -—–:,")
    if not quantity or quantity <= 0:
        return None

    name = name.lower().replace("ё", "е")
    name = re.sub(r"\(.*?\)", "", name)
    name = re.sub(r"\s+", " ", name).strip(" ,.-")
    if not name:
        return None
    if name in SKIP_EXACT:
        return None
    if ("перец" in name or "перц" in name) and "болгар" not in name and "сладк" not in name:
        return None
    if any(word in name for word in SKIP_NAMES):
        return None

    ingredient_id = None
    for synonym in sorted(SYNONYMS, key=len, reverse=True):
        if synonym in name:
            ingredient_id = SYNONYMS[synonym]
            break
    if ingredient_id is None:
        UNKNOWN_COUNTS[name] = UNKNOWN_COUNTS.get(name, 0) + 1
        return ("unknown", name)
    if ingredient_id not in meta:
        UNKNOWN_COUNTS[ingredient_id] = UNKNOWN_COUNTS.get(ingredient_id, 0) + 1
        return ("unknown", ingredient_id)

    if unit == "kg":
        grams = quantity * 1000
    elif unit == "g":
        grams = quantity
    elif unit in ("l", "ml"):
        grams = quantity * (1000 if unit == "l" else 1)
    elif unit == "pcs":
        grams = quantity * PIECE_WEIGHTS.get(ingredient_id, 0)
    elif unit == "tbsp":
        grams = quantity * SPOON_WEIGHTS.get(ingredient_id, 15)
    elif unit == "tsp":
        grams = quantity * 5
    elif unit == "cup":
        grams = quantity * CUP_WEIGHTS.get(ingredient_id, 200)
    elif unit == "clove":
        grams = quantity * 5
    elif unit == "pinch":
        grams = quantity * 1
    elif unit == "bunch":
        grams = quantity * 30
    else:
        if ingredient_id in PIECE_WEIGHTS:
            grams = quantity * PIECE_WEIGHTS[ingredient_id]
        else:
            grams = quantity

    if not grams or grams <= 0 or grams > 2000:
        return None
    return (ingredient_id, round(grams, 1))


def meal_types(category):
    value = category.lower().replace("ё", "е")
    if "напит" in value or "соус" in value:
        return None
    if "салат" in value or "суп" in value:
        return ["lunch"]
    if "закуск" in value:
        return ["snack"]
    if "десерт" in value or "выпеч" in value or "слад" in value:
        return ["snack"]
    if "завтрак" in value or "каш" in value:
        return ["breakfast"]
    if "втор" in value or "мяс" in value or "рыб" in value or "птиц" in value or "овощ" in value:
        return ["lunch", "dinner"]
    return ["lunch", "dinner"]


def fallback_ingredient_lines(text):
    head = re.split(
        r"^==+\s*(?:приготовление|способ приготовления|процесс|рецепт)\s*==+\s*$",
        text,
        flags=re.I | re.M,
    )[0]
    return [
        line
        for line in head.splitlines()
        if re.match(r"^\s*(?:\*|#|\d+[.)])\s*\S", line)
        and "http" not in line
        and not line.strip().startswith("|")
    ]


def fallback_steps(text):
    verbs = (
        "смешайте", "обжарьте", "варите", "варить", "запеките", "нарежьте",
        "готовьте", "тушите", "добавьте", "взбейте", "посолите", "доведите",
        "отварите", "прогрейте", "потушите",
    )
    for line in text.splitlines():
        cleaned = clean(line)
        if len(cleaned) < 60:
            continue
        if any(verb in cleaned.lower() for verb in verbs):
            return cleaned
    return ""


def parse_recipe(title, text, meta):
    category = template_field(text, "Категория")
    types = meal_types(category)
    if not types:
        return None, "category"
    title_lower = title.split(":", 1)[-1].lower().replace("ё", "е")
    if "винегрет" in title_lower or "суп" in title_lower:
        types = ["lunch"]
    elif "салат" in title_lower and types == ["snack"]:
        types = ["lunch"]

    image_name = template_field(text, "Изображение")
    if not image_name:
        image_match = re.search(r"\[\[\s*(?:Файл|File):([^|\]]+)", text, flags=re.I)
        image_name = image_match.group(1).strip() if image_match else ""
    if not image_name:
        return None, "no_image"

    ingredients_text = section(
        text,
        {"состав", "ингредиенты", "продукты", "компоненты"},
    )
    lines = [
        line
        for line in ingredients_text.splitlines()
        if re.match(r"^\s*(?:\*|#|\d+[.)])\s*\S", line)
    ]
    if not ingredients_text or len(lines) < 2:
        lines = fallback_ingredient_lines(text)
    if len(lines) < 2:
        return None, "no_ingredient_list"

    ingredients = {}
    unknown = 0
    for line in lines:
        parsed = parse_ingredient_line(line, meta)
        if parsed is None:
            continue
        if parsed[0] == "unknown":
            unknown += 1
            continue
        ingredient_id, grams = parsed
        ingredients[ingredient_id] = ingredients.get(ingredient_id, 0) + grams
    ingredients.pop("salt", None)
    if unknown > 0 or len(ingredients) < 3:
        return None, "unknown_or_few"
    if any(grams < 3 for grams in ingredients.values()):
        return None, "tiny_ingredient"
    steps_text = section(
        text,
        {"приготовление", "способ приготовления", "процесс", "рецепт"},
    )
    if not steps_text:
        steps_text = fallback_steps(text)
    if not steps_text:
        return None, "no_steps"
    steps = []
    for line in steps_text.splitlines():
        line = clean(line)
        line = re.sub(r"^[#*]+\s*", "", line)
        line = re.sub(r"^\d+[.)]\s*", "", line)
        if (
            not line
            or line.startswith("|")
            or line.startswith("!")
            or "==" in line
        ):
            continue
        if line.lower().startswith(("количество", "примечание", "источник", "см. также")):
            continue
        if line.startswith("(") and "количество" in line.lower():
            continue
        for sentence in re.split(r"(?<=[.!?])\s+", line):
            sentence = sentence.strip()
            if len(sentence) > 3:
                steps.append(sentence)
    if not steps:
        return None, "no_steps"

    servings_text = template_field(text, "Порций")
    servings = int(re.search(r"\d+", servings_text).group(0)) if re.search(r"\d+", servings_text) else 4
    servings = max(1, min(servings, 20))

    total_grams = sum(ingredients.values())
    if total_grams / servings < 40 or total_grams / servings > 1500:
        return None, "weight_outlier"
    if max(ingredients.values()) > 1500:
        return None, "ingredient_outlier"
    value = category.lower().replace("ё", "е")
    if (
        any(word in value for word in ("втор", "мяс", "рыб", "птиц"))
        and not set(ingredients) & PROTEIN_IDS
    ):
        return None, "no_main"
    if (
        any(word in value for word in ("выпеч", "десерт", "слад", "торт", "печенье"))
        and set(ingredients) & MEAT_FISH_IDS
    ):
        return None, "meat_in_baking"
    title_value = title.lower().replace("ё", "е")
    if (
        any(
            word in title_value
            for word in (
                "беф", "бёф", "мяс", "говядин", "свинин", "курин", "куриц",
                "индейк", "рыб", "треск", "лосос", "печен", "баранин",
            )
        )
        and not set(ingredients) & MEAT_FISH_IDS
    ):
        return None, "no_main_title"
    basic_baking = {"flour", "breadcrumbs", "sugar", "butter", "egg", "milk_25", "yeast"}
    if set(ingredients) <= basic_baking and not any(
        word in value for word in ("выпеч", "десерт", "слад", "торт", "печенье")
    ):
        return None, "no_main_ingredient"

    time_text = template_field(text, "Время")
    time_match = re.search(r"\d+", time_text)
    minutes = int(time_match.group(0)) if time_match else 30
    minutes = max(5, min(minutes, 240))
    if minutes < 10 and len(steps) >= 4:
        minutes = 30

    title = clean(title.split(":", 1)[-1])
    if not title:
        return None, "no_title"
    return {
        "title": title,
        "category": category,
        "types": types,
        "image_name": image_name,
        "ingredients": ingredients,
        "steps": steps[:12],
        "servings": servings,
        "minutes": minutes,
    }, ""


def image_info(names):
    result = {}
    unique = list(dict.fromkeys(names))
    for start in range(0, len(unique), 50):
        batch = unique[start:start + 50]
        titles = "|".join("File:" + name for name in batch)
        data = api({
            "action": "query",
            "prop": "imageinfo",
            "iiprop": "url|extmetadata",
            "iiurlwidth": "800",
            "titles": titles,
        })
        for page in data.get("query", {}).get("pages", []):
            info = (page.get("imageinfo") or [None])[0]
            if not info:
                continue
            metadata = info.get("extmetadata", {})
            license_name = clean(metadata.get("LicenseShortName", {}).get("value", ""))
            artist = clean(metadata.get("Artist", {}).get("value", ""))
            url = info.get("thumburl") or info.get("url")
            if url and license_name and "fair" not in license_name.lower():
                result[page["title"][5:]] = {
                    "url": url,
                    "license": license_name,
                    "artist": artist,
                }
        time.sleep(0.2)
    return result


def download_image(url, path):
    request = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(request, timeout=60) as response:
        data = response.read()
    if len(data) < 5000:
        return False
    with open(path, "wb") as handle:
        handle.write(data)
    return True


def page_url(title):
    return "https://ru.wikibooks.org/wiki/" + title.replace(" ", "_")


def main():
    with open(SEED_PATH, "r", encoding="utf-8") as handle:
        seed = json.load(handle)
    os.makedirs(IMAGE_DIR, exist_ok=True)

    meta = {}
    for ingredient in seed["ingredients"]:
        meta[ingredient["id"]] = {
            "name": ingredient["name"],
            "category": ingredient["category"],
            "nutrients": ingredient["per100g"],
            "allergens": ingredient.get("allergens", []),
            "price": ingredient.get("pricePerKg", 0),
        }
    for ingredient_id, values in EXTRA.items():
        name, category, kcal, protein, fat, carbs, price, allergens = values
        meta[ingredient_id] = {
            "name": name,
            "category": category,
            "nutrients": {"calories": kcal, "protein": protein, "fat": fat, "carbs": carbs},
            "allergens": allergens,
            "price": price,
        }

    existing_titles = {recipe["title"].lower() for recipe in seed["recipes"] if not recipe["id"].startswith("wb_")}
    existing_signatures = {
        "|".join(sorted(item["ingredientId"] for item in recipe["ingredients"]))
        for recipe in seed["recipes"]
        if not recipe["id"].startswith("wb_")
    }
    seed["recipes"] = [recipe for recipe in seed["recipes"] if not recipe["id"].startswith("wb_")]

    os.makedirs("build", exist_ok=True)
    members_cache = "build/wikibooks_members.json"
    pages_cache = "build/wikibooks_pages.json"
    if os.path.exists(members_cache):
        with open(members_cache, encoding="utf-8") as handle:
            members = json.load(handle)
    else:
        members = category_members()
        with open(members_cache, "w", encoding="utf-8") as handle:
            json.dump(members, handle, ensure_ascii=False)
    print(f"category members: {len(members)}", flush=True)
    titles = [member["title"] for member in members]
    if os.path.exists(pages_cache):
        with open(pages_cache, encoding="utf-8") as handle:
            pages = json.load(handle)
    else:
        pages = fetch_pages(titles)
        with open(pages_cache, "w", encoding="utf-8") as handle:
            json.dump(pages, handle, ensure_ascii=False)
    print(f"pages fetched: {len(pages)}", flush=True)

    parsed = []
    stats = {}
    for title in titles:
        text = pages.get(title)
        if not text or "{{Рецепт" not in text:
            stats["skip_template"] = stats.get("skip_template", 0) + 1
            continue
        recipe, reason = parse_recipe(title, text, meta)
        if not recipe:
            stats[reason] = stats.get(reason, 0) + 1
            FAILURES.append({"title": title, "reason": reason})
            continue
        signature = "|".join(sorted(recipe["ingredients"]))
        if recipe["title"].lower() in existing_titles or signature in existing_signatures:
            stats["duplicate"] = stats.get("duplicate", 0) + 1
            continue
        recipe["page_title"] = title
        recipe["page_url"] = page_url(title)
        parsed.append(recipe)
        if len(parsed) >= MAX_CANDIDATES:
            break
    print(f"parsed candidates: {len(parsed)}", flush=True)
    print(f"skip stats: {stats}", flush=True)

    infos = image_info([recipe["image_name"] for recipe in parsed])
    print(f"image infos: {len(infos)}", flush=True)

    imported = []
    deferred = []
    used_ingredients = set()

    def build(recipe, page_id, image_path, info):
        attribution = f"{recipe['page_url']}, CC BY-SA 4.0"
        if info:
            if info.get("artist"):
                attribution += f"; фото: {info['artist']}, {info['license']}"
            elif info.get("license"):
                attribution += f"; фото: {info['license']}"
        return {
            "id": f"wb_{page_id}",
            "title": recipe["title"],
            "mealTypes": recipe["types"],
            "servings": recipe["servings"],
            "minutes": recipe["minutes"],
            "ingredients": [
                {"ingredientId": ingredient_id, "grams": grams}
                for ingredient_id, grams in sorted(recipe["ingredients"].items())
            ],
            "steps": recipe["steps"],
            "image": image_path,
            "source": attribution,
        }

    for recipe in parsed:
        page_id = None
        for member in members:
            if member["title"] == recipe["page_title"]:
                page_id = member["pageid"]
                break
        if page_id is None:
            continue

        total = {"calories": 0.0, "protein": 0.0, "fat": 0.0, "carbs": 0.0}
        for ingredient_id, grams in recipe["ingredients"].items():
            nutrients = meta[ingredient_id]["nutrients"]
            factor = grams / 100
            for key in total:
                total[key] += nutrients[key] * factor
        per_serving_calories = total["calories"] / recipe["servings"]
        if per_serving_calories < 30 or per_serving_calories > 1200:
            stats["calories_outlier"] = stats.get("calories_outlier", 0) + 1
            continue

        info = infos.get(recipe["image_name"])
        if not info:
            stats["image_missing"] = stats.get("image_missing", 0) + 1
            deferred.append((recipe, page_id))
            continue
        extension = ".png" if info["url"].lower().endswith(".png") else ".jpg"
        image_path = os.path.join(IMAGE_DIR, f"wb_{page_id}{extension}")
        try:
            if not download_image(info["url"], image_path):
                stats["image_download"] = stats.get("image_download", 0) + 1
                deferred.append((recipe, page_id))
                continue
        except Exception:
            stats["image_download"] = stats.get("image_download", 0) + 1
            deferred.append((recipe, page_id))
            continue

        for ingredient_id in recipe["ingredients"]:
            used_ingredients.add(ingredient_id)
        imported.append(
            build(
                recipe,
                page_id,
                f"assets/images/recipes/wb_{page_id}{extension}",
                info,
            )
        )
        if len(imported) >= TARGET_RECIPES:
            break

    if len(imported) < TARGET_RECIPES:
        for recipe, page_id in deferred:
            if len(imported) >= TARGET_RECIPES:
                break
            for ingredient_id in recipe["ingredients"]:
                used_ingredients.add(ingredient_id)
            imported.append(build(recipe, page_id, None, None))

    print(f"imported after images: {len(imported)}", flush=True)
    print(f"final skip stats: {stats}", flush=True)
    if not imported:
        print("nothing imported", flush=True)
        return 1

    for ingredient_id in sorted(used_ingredients):
        if ingredient_id not in {item["id"] for item in seed["ingredients"]}:
            item = meta[ingredient_id]
            seed["ingredients"].append({
                "id": ingredient_id,
                "name": item["name"],
                "category": item["category"],
                "per100g": item["nutrients"],
                "allergens": item["allergens"],
                "pricePerKg": item["price"],
            })

    seed["recipes"].extend(imported)
    seed["version"] = int(seed.get("version", 1)) + 1
    with open(SEED_PATH, "w", encoding="utf-8") as handle:
        json.dump(seed, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print(f"seed version: {seed['version']}, recipes: {len(seed['recipes'])}", flush=True)
    os.makedirs("build", exist_ok=True)
    with open("build/wikibooks_unknowns.json", "w", encoding="utf-8") as handle:
        json.dump(
            sorted(UNKNOWN_COUNTS.items(), key=lambda item: -item[1]),
            handle,
            ensure_ascii=False,
            indent=2,
        )
        handle.write("\n")
    with open("build/wikibooks_failures.json", "w", encoding="utf-8") as handle:
        json.dump(FAILURES, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
