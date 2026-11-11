# Норма

Локальное приложение для Windows на Flutter: расчёт КБЖУ и подбор рациона на неделю с учётом цели, активности, аллергенов, времени готовки и бюджета.

## Возможности

- Расчёт BMR/TDEE по Миффлину-Сент-Джору и целевых КБЖУ.
- Меню на 7 дней с автоматическим масштабом порций под норму.
- Фильтры: аллергены, максимальное время готовки, дневной бюджет.
- Ручной выбор альтернатив блюда, лайки и блокировки.
- Каталог рецептов с поиском и фильтром по приёму пищи.
- Добавление блюда из каталога в выбранный день и приём пищи.
- Импорт рецептов из JSON: меню ⋮ → «Импортировать рецепты».
- Абстрактные иллюстрации для всех рецептов, поддержка локальных фото и assets-путей, заглушки по типу приёма пищи.
- Ручная правка порции в карточке блюда.
- Список покупок: агрегация, стоимость, чекбоксы и копирование в буфер.
- Локальное сохранение профиля и точного снимка плана.
- Своя иконка, заголовок окна «Норма» и запоминание размера/позиции.
- SQLite-база рецептов: 42 ингредиента и 93 рецепта.
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

## Сборка

Portable-версия:

```powershell
powershell -ExecutionPolicy Bypass -File tool\build_windows.ps1
```

Результат: `dist\norma-<версия>-windows-x64-portable.zip`.

Установщик:

```powershell
winget install --id JRSoftware.InnoSetup -e
powershell -ExecutionPolicy Bypass -File tool\build_installer.ps1
```

Результат: `dist\norma-<версия>-windows-x64-setup.exe`.

## Подпись установщика

Нужен сертификат code signing (OV/EV) в формате PFX:

```powershell
powershell -ExecutionPolicy Bypass -File tool\sign_installer.ps1 -PfxPath C:\path\cert.pfx
```

Пароль можно передать через переменную `NORMA_PFX_PASSWORD`. Без сертификата установщик не подписан, SmartScreen предупреждает.

## Данные

- Seed: `assets/data/seed.json` (ассет приложения).
- Иллюстрации: `assets/images/recipes/` (генерация: `tool/generate_illustrations.ps1`, привязка: `dart run tool/apply_illustrations.dart`).
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

Файл seed: `assets/data/seed.json`. Версия seed хранится в базе; при её росте данные обновляются через merge, поэтому пользовательские импорты сохраняются. Расширить набор: `dart run tool/generate_recipes.dart`.

Пример для ручного импорта: `examples/import_example.json` (меню ⋮ → «Импортировать рецепты»).

`SeedBundle.fromJson` принимает объект с ингредиентами, ценами и рецептами:

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
      "steps": ["Сварите хлопья."],
      "image": "C:/photos/oatmeal.jpg"
    }
  ]
}
```

`image` необязателен: локальный путь или assets-путь. При ошибке загрузки показывается заглушка по типу приёма пищи.

## Дальше

- Реальные фотографии рецептов (лицензированный контент).
- Подписанный релиз после получения сертификата.
