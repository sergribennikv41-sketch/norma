# Установка на iPhone без App Store

Приложение можно собрать и установить на свой iPhone бесплатно, без публикации
в App Store и без платного Apple Developer Program. Подпись бесплатного Apple ID
действует **7 дней**, затем приложение нужно переустановить. Данные при этом
сохраняются.

## Что нужно

- Mac с macOS и установленным **Xcode** (App Store → Xcode).
- Бесплатный **Apple ID**, добавленный в Xcode (для прямого запуска) или
  введённый в Sideloadly.
- iPhone с iOS 15+ и кабелем.
- На iPhone включён **Режим разработчика**: Настройки → Конфиденциальность и
  безопасность → Режим разработчика.

CocoaPods не обязателен: проект собирается через Swift Package Manager.
Если SPM выключен, включите его:

```bash
flutter config --enable-swift-package-manager
```

CocoaPods нужен только как запасной вариант, если SPM почему-то недоступен.

## 1. Подготовка Mac

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

Откройте Xcode один раз и дождитесь установки компонентов. Затем добавьте
Apple ID: Xcode → Settings → Accounts → «+» → Apple ID.

CocoaPods (запасной вариант):

```bash
sudo gem install cocoapods
pod --version
```

Если `gem` не может установить CocoaPods, подойдёт Homebrew:

```bash
brew install cocoapods
```

Проверка окружения:

```bash
flutter doctor -v
```

В разделе Xcode не должно быть ошибок.

## 2. Сборка неподписанного IPA

Из корня проекта:

```bash
flutter pub get
bash tool/build_ios_unsigned.sh
```

Результат: `build/ios/norma-unsigned.ipa`. Проверено на Xcode 27.2 и
Flutter 3.47.9: сборка идёт через Swift Package Manager, CocoaPods не требуется.

Скрипт выполняет `flutter build ios --release --no-codesign` и упаковывает
`Runner.app` в `Payload/` — такой IPA подписывает Sideloadly или AltStore.

## 3. Установка через Sideloadly (проще всего)

1. Скачайте Sideloadly с https://sideloadly.io и запустите.
2. Подключите iPhone кабелем, разблокируйте и нажмите «Доверять».
3. Перетащите `build/ios/norma-unsigned.ipa` в окно Sideloadly.
4. Введите свой Apple ID. Пароль вводится в приложение и не сохраняется в проекте.
5. Нажмите **Start**.
6. На iPhone: Настройки → Основные → VPN и управление устройством →
   «Разработчик приложения» → Доверять.
7. Запустите «Норма» с домашнего экрана.

Через 7 дней Sideloadly нужно запустить снова и повторить установку — данные
приложения сохранятся.

## 4. Установка через AltStore (автопродление)

AltStore умеет переподписывать приложение по Wi-Fi, пока Mac и iPhone в одной
сети.

1. Установите **AltServer** с https://altstore.io на Mac.
2. Подключите iPhone, установите AltStore на телефон через AltServer.
3. На iPhone: Настройки → Основные → VPN и управление устройством → доверять
   AltStore.
4. В AltStore: My Apps → «+» → выберите `norma-unsigned.ipa`.
5. Введите Apple ID и установите приложение.

AltStore будет обновлять подпись автоматически, пока работает AltServer.
Резервный вариант — вручную раз в 7 дней.

## 5. Ограничения бесплатного Apple ID

- подпись действует 7 дней;
- одновременно не больше 3 приложений на устройстве;
- не больше 10 App ID в неделю;
- недоступны push-уведомления, CloudKit, In-App Purchase и часть entitlements.

Для «Нормы» этого достаточно: приложение локальное, без сервера и push.

## 6. Запуск из Xcode (для отладки)

1. Откройте `ios/Runner.xcworkspace`.
2. Выберите target **Runner** → Signing & Capabilities.
3. Team — ваш Apple ID (Personal Team).
4. Bundle Identifier должен быть уникальным. Если `ru.norma.norma` занят,
   замените, например, на `ru.norma.norma.<ваше-имя>`.
5. Подключите iPhone и нажмите Run.

Или из терминала:

```bash
flutter run --release -d <device-id>
```

Список устройств: `flutter devices`.

## 7. Если что-то не работает

- **«Unable to Verify App»** — не доверен профиль разработчика. Настройки →
  Основные → VPN и управление устройством.
- **«Developer Mode disabled»** — включите режим разработчика и перезагрузите
  iPhone.
- **Bundle identifier уже используется** — смените bundle id в Xcode и повторите
  сборку.
- **`pod install` не находит CocoaPods** — проверьте `pod --version` и
  `flutter doctor -v`.
- **Сборка падает на подписи** — для Sideloadly используйте
  `tool/build_ios_unsigned.sh`, он собирает без подписи.
- **Долгий первый запуск** — при первом старте приложение импортирует 5000
  рецептов из `seed.json` в SQLite. Это может занять несколько секунд.

## Примечания

- Цены магазинов на iOS не работают: обработчик цен — Python-скрипт для Windows.
- Профиль, меню и покупки хранятся локально на устройстве.
- Приложение не отправляет данные на сервер.
