# Установка и запуск на Windows

Проект: локальное приложение для подбора рациона и расчёта КБЖУ.
Репозиторий: https://github.com/sergribennikv41-sketch/norma

## 1. Flutter

1. Скачать Flutter 3.47.9 (stable, Windows):
   https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.9-stable.zip
2. Распаковать в `C:\dev\flutter`.
3. Добавить `C:\dev\flutter\bin` в переменную среды PATH (пользовательскую).
4. Проверить в новом терминале:
   ```powershell
   flutter --version
   ```

## 2. C++ toolchain

Установить Visual Studio 2022 Build Tools с workload «Desktop development with C++»:

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

Альтернатива: Visual Studio 2022 Community, в установщике выбрать workload «Desktop development with C++».

## 3. Developer Mode

Параметры → Обновление и безопасность → Для разработчиков → включить «Режим разработчика».

Нужен Flutter для symlink-поддержки плагинов (shared_preferences) при сборке под Windows.

## 4. Python и Playwright для цен

Цены в списке покупок ищутся локальным обработчиком через браузер:

```powershell
py -3 -m pip install playwright
py -3 -m playwright install chromium
```

Проверка:

```powershell
py -3 -c "import playwright; print('ok')"
```

Сейчас подключён Магнит. Для остальных сетей нужны отдельные адаптеры в `tool/price_lookup.py`. Цены не сохраняются на диск; кэш живёт только до закрытия приложения.

## 5. Проект

```powershell
git clone https://github.com/sergribennikv41-sketch/norma.git C:\dev\norma
cd C:\dev\norma
flutter pub get
flutter doctor
```

## 6. Запуск

```powershell
flutter run -d windows
```

Release-сборка:

```powershell
flutter build windows --release
```

Готовый exe: `build\windows\x64\runner\Release\`.

Portable-архив и установщик:

```powershell
powershell -ExecutionPolicy Bypass -File tool\build_windows.ps1
winget install --id JRSoftware.InnoSetup -e
powershell -ExecutionPolicy Bypass -File tool\build_installer.ps1
```

Результаты в `dist\`.

## 7. Проверки

```powershell
flutter analyze
flutter test
```

Тестов сейчас 66.

## 8. Данные

- Рецепты и ингредиенты: SQLite `%APPDATA%\ru.norma\norma\norma.db` (создаётся и заполняется при первом запуске).
- Профиль, город, магазин и снимок рациона: shared_preferences (Windows: AppData/реестр).
- Live-цены не сохраняются: кэш только в памяти до закрытия приложения.
- Сервер приложения не используется; для цен нужен интернет и сайт магазина.

## 9. Если изменений нет в репозитории

Последние доработки могут быть ещё не запушены. На рабочей машине выполнить:

```powershell
cd E:\OpenCode\norma
git add .
git commit -m "Ручной выбор блюд"
git push
```
