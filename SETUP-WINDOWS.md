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

## 4. Проект

```powershell
git clone https://github.com/sergribennikv41-sketch/norma.git C:\dev\norma
cd C:\dev\norma
flutter pub get
flutter doctor
```

## 5. Запуск

```powershell
flutter run -d windows
```

Release-сборка:

```powershell
flutter build windows --release
```

Готовый exe: `build\windows\x64\runner\Release\`.

## 6. Проверки

```powershell
flutter analyze
flutter test
```

Тестов сейчас 31.

## 7. Данные

- Рецепты, ингредиенты и цены: SQLite `%APPDATA%\ru.norma\norma\norma.db` (создаётся и заполняется при первом запуске).
- Профиль и снимок рациона: shared_preferences (Windows: AppData/реестр).
- Сервер не используется, всё локально.

## 8. Если изменений нет в репозитории

Последние доработки могут быть ещё не запушены. На рабочей машине выполнить:

```powershell
cd E:\OpenCode\norma
git add .
git commit -m "Ручной выбор блюд"
git push
```
