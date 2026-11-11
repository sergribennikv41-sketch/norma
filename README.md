# Норма

Локальное приложение для Windows на Flutter: расчёт КБЖУ и подбор рациона на неделю с учётом цели, активности, аллергенов, времени готовки и бюджета.

## Возможности

- Расчёт BMR/TDEE по Миффлину-Сент-Джору и целевых КБЖУ.
- Меню на 7 дней с автоматическим масштабом порций под норму.
- Фильтры: аллергены, максимальное время готовки, дневной бюджет.
- Ручной выбор альтернатив блюда, лайки и блокировки.
- Каталог рецептов с поиском и фильтром по приёму пищи.
- Ручная правка порции в карточке блюда.
- Список покупок: агрегация, стоимость, чекбоксы и копирование в буфер.
- Локальное сохранение профиля и точного снимка плана.
- SQLite-база рецептов: 42 ингредиента и 33 рецепта на старте.
- Seed-файл `assets/data/seed.json` — канонический источник, при первом запуске импортируется в SQLite.
- Импорт/экспорт seed-данных через JSON-структуру.

## Стек

- Flutter 3.47.9, Dart 3.13.7, Material 3.
- SQLite: `sqflite_common_ffi` на Windows, `sqflite` на мобильных.
- `shared_preferences` для профиля и плана.

## Запуск

```powershell
flutter pub get
flutter run -d windows
```

Release-сборка:

```powershell
flutter build windows --release
```

Exe: `build\windows\x64\runner\Release\norma.exe`.

## Проверки

```powershell
flutter analyze
flutter test
```

## Данные

- Seed: `assets/data/seed.json` (ассет приложения).
- Рецепты, ингредиенты и цены: SQLite `%APPDATA%\ru.norma\norma\norma.db`.
- Профиль и снимок рациона: `shared_preferences`.
- Сервер не используется, всё хранится локально.

## Структура

```
lib/core/models       — доменные модели и JSON-сериализация
lib/core/data         — репозитории, SQLite, seed-данные, сессия
lib/core/nutrition    — расчёт нормы КБЖУ
lib/core/planner      — генератор меню, альтернативы, покупки, восстановление плана
lib/features          — онбординг и экран рациона
test                  — тесты расчётов, генератора, БД и хранения
```

## Формат импорта

Файл seed: `assets/data/seed.json`. `SeedBundle.fromJson` принимает объект с ингредиентами, ценами и рецептами:

```json
{
  "version": 1,
  "ingredients": [
    {
      "id": "oats",
      "name": "Овсяные хлопья",
      "category": "Крупы и макароны",
      "per100g": {"calories": 352, "protein": 12.3, "fat": 6.1, "carbs": 61.8},
      "allergens": [],
      "pricePerKg": 120
    }
  ],
  "recipes": [
    {
      "id": "oatmeal",
      "title": "Овсянка",
      "mealTypes": ["breakfast"],
      "servings": 1,
      "minutes": 10,
      "ingredients": [{"ingredientId": "oats", "grams": 60}],
      "steps": ["Сварите хлопья."]
    }
  ]
}
```

## Дальше

- Расширение библиотеки рецептов и импорт из JSON-файлов.
- Добавление блюд из каталога прямо в рацион.
- Установщик Windows и иконка приложения.
