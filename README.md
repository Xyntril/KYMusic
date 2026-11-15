<div align="center">

# 🎧 KYMusic

**Нативный клиент Яндекс Музыки для среды рабочего стола KDE Plasma и Plasma Mobile**

Построен на C++20 · Qt 6 · KDE Frameworks 6 (Kirigami, KColorScheme, KXmlGui, KStatusNotifierItem, KIconThemes) · Linux / Plasma

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/Xyntril/KYMusic)](https://github.com/Xyntril/KYMusic/releases)

</div>

---

## О проекте

**KYMusic** — это современный, быстрый и полностью нативный клиент Яндекс Музыки, разработанный специально для экосистемы **KDE Plasma 6** и мобильной оболочки **KDE Plasma Mobile**. В отличие от веб-обёрток на Electron, KYMusic написан на нативном C++20 с использованием **KDE Frameworks 6** и Qt Quick, потребляет минимум оперативной памяти, мгновенно запускается и идеально гармонирует с системным окружением KDE.

---

## Возможности KYMusic v1.0.0

### 🎨 100% нативная интеграция с KDE Plasma 6
* **KDE Application Style**: полная поддержка системных тем оформления (`Breeze`, `Breeze Dark`, `Oxygen`, `Fusion`, `Union`). Приложение автоматически подхватывает системные шрифты, скругления, иконки и эффекты KDE.
* **KColorScheme**: автоматическое следование системным цветовым палитрам рабочего стола — как светлым, так и тёмным.
* **Системный трей `KStatusNotifierItem`**: нативный значок в трее с полным контекстным меню, управлением воспроизведением, регулировкой громкости и отображением статуса.
* **Global Menu и `KHamburgerMenu`**: интеграция с глобальным меню KDE Plasma по D-Bus (`appmenu`), поддержка верхней строки меню `MenuBar` (`Ctrl+M`) и адаптивного гамбургер-меню для компактных панелей.
* **Системные диалоги `KF6::XmlGui`**: нативные системные окна «О программе KYMusic» (`KAboutData`) и «О среде KDE».

### 📻 Двусторонний MPRIS2 D-Bus
* **Виджет KDE Plasma в панели задач**: полнофункциональное управление из системного апплета «Проигрыватель» по стандарту `org.mpris.MediaPlayer2.Player`.
* **Двусторонняя синхронизация**: мгновенное обновление статуса воспроизведения (`PlaybackStatus`), режимов повтора (`LoopStatus`), случайного порядка (`Shuffle`), позиции трека и метаданных с обложками.
* **Надёжная перемотка и кроссфейд**: исключены ложные переходы в статус `Stopped` при повторе одного трека (`RepeatOne`) или кроссфейде аудио-слотов; корректная отправка сигнала `Seeked(0)`.
* **Уникальный сервис**: поддержка нескольких запущенных экземпляров с фолбэком на PID (`org.mpris.MediaPlayer2.kymusic.instance<PID>`).

### 📱 Конвергентный режим KDE Plasma Mobile
* **Адаптивная компоновка**: автоматический переход интерфейса между десктопным и мобильным режимами в зависимости от ширины экрана и окружения.
* **Мобильные карточки**: центрированные вертикальные шапки на страницах Альбомов, Исполнителей и Плейлистов с крупными обложками 150×150 и переносящимися кнопками действий без обрезания.
* **Сенсорная навигация**: нижняя панель табов `NavigationTabBar`, всплывающие разделы меню и кнопка «Назад» в шапках страниц.
* **Мобильный мини-бар**: компактный плеер 56px с индикатором прогресса и вызовом полноэкранного режима в один тап.

### 🌌 Визуальные эффекты и удобство
* **Атмосферная подсветка `Ambient Glow`**: динамическое фоновое свечение, плавно подстраивающееся под цветовую палитру обложки текущего трека.
* **Перетаскиваемый мини-плеер**: компактное плавающее окно поверх всех окон для удобного фонового прослушивания, полностью совместимое с Wayland.
* **Развёрнутый плеер**: полноэкранный режим с синхронизированными текстами песен (LRC / LRCLIB), текущей очередью и похожими треками.
* **Управление качеством**: поддержка аудиопотоков от низкого до FLAC Lossless с индикацией кодека и битрейта.
* **Плавный переход (Crossfade)**: затухание от 0 до 15 секунд между треками.

### 🎵 Каталог и функции Яндекс Музыки
* **«Моя волна»**: персональный бесконечный поток музыки с мгновенной реакцией на лайки и пропуски.
* **Полнотекстовый поиск**: умный живой ввод с подсказками, историей недавних запросов и нативной заглушкой.
* **Медиатека**: создание, редактирование и удаление собственных плейлистов; списки «Мне нравится» для треков, альбомов и артистов.
* **Каталог**: разделы «Новые релизы», «Жанры», «Станции» (радио ротора), «Подкасты» и персональные подборки лендинга.
* **Статистика**: персональная сводка прослушиваний за последние 30 дней с графиком «Минуты по дням», топами треков и артистов.
* **Скачивание треков**: сохранение музыки в «Загрузки» с заполнением ID3v2-тегов и встраиванием обложки через библиотеку TagLib.
* **Фильтрация контента**: выявление сгенерированных ИИ треков (база Slopless) с автодизлайком/пропуском и подмена цензурированных треков (база FckCensorData).

---

## Установка

Готовые релизные пакеты доступны на странице [Releases](https://github.com/Xyntril/KYMusic/releases):

* **Linux x86_64 (AppImage)**: самодостаточный пакет со всеми библиотеками. Для запуска достаточно сделать файл исполняемым:
  ```bash
  chmod +x KYMusic-1.0.0-x86_64.AppImage
  ./KYMusic-1.0.0-x86_64.AppImage
  ```
* **Linux x86_64 (tar.gz)**: готовый архив для распаковки в систему.

---

## Сборка из исходников

### Зависимости

Для сборки KYMusic требуются: компилятор с поддержкой **C++20**, **CMake 3.21+**, **Ninja**, **Qt 6.6+** (Quick, Gui, Network, Multimedia, DBus), **KDE Frameworks 6** и **TagLib**.

#### Arch Linux / Manjaro:
```bash
sudo pacman -S --needed base-devel cmake ninja \
    qt6-base qt6-declarative qt6-multimedia taglib \
    extra-cmake-modules kirigami kcolorscheme kxmlgui \
    kstatusnotifieritem kiconthemes qqc2-desktop-style
```

#### Ubuntu 24.04+ / Debian 13+:
```bash
sudo apt update
sudo apt install -y build-essential cmake ninja-build \
    qt6-base-dev qt6-declarative-dev qt6-multimedia-dev libtag1-dev \
    extra-cmake-modules libkf6coreaddons-dev libkf6colorscheme-dev \
    libkf6xmlgui-dev libkf6statusnotifieritem-dev libkf6iconthemes-dev \
    qml6-module-org-kde-kirigami qml6-module-org-kde-qqc2desktopstyle
```

#### Fedora 40+:
```bash
sudo dnf install -y gcc-c++ cmake ninja-build \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtmultimedia-devel taglib-devel \
    extra-cmake-modules kf6-kcoreaddons-devel kf6-kcolorscheme-devel \
    kf6-kxmlgui-devel kf6-kstatusnotifieritem-devel kf6-kiconthemes-devel \
    kf6-kirigami-devel kf6-qqc2-desktop-style
```

### Сборка и запуск

```bash
git clone https://github.com/Xyntril/KYMusic.git
cd KYMusic
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
```

Запуск скомпилированного клиента:
```bash
./build/kymusic
```

Установка в систему:
```bash
sudo cmake --install build
```

---

## Архитектура

```text
QML (Kirigami / KDE Desktop)
         ↓
C++ Controllers (AppController, KdeTrayController, KdeMenuManager, MediaControlsMPRIS)
         ↓
Services & Models (PlaybackController, PlayerService, QueueService, Yandex API)
         ↓
Qt 6 Multimedia (FFmpeg) & Linux D-Bus (MPRIS2 / StatusNotifierItem)
```

- **Интерфейс**: QML с компонентами Kirigami и стилем `org.kde.desktop`.
- **Интеграция KDE**: `KAboutData`, `KXmlGui`, `KStatusNotifierItem`, системный трей и Global Menu.
- **Воспроизведение**: Qt Multimedia с бэкендом FFmpeg и поддержкой плавного кроссфейда.
- **D-Bus**: полнофункциональный MPRIS2-контроллер для интеграции с виджетами KDE Plasma.

---

## Авторизация

1. При первом запуске нажмите «Войти через Яндекс ID».
2. В браузере откроется официальная страница авторизации Яндекса.
3. Разрешите доступ, скопируйте итоговый URL из адресной строки и вставьте в окно KYMusic.
4. Токен безопасно сохраняется в системной конфигурации и используется для последующих запусков.

---

## Roadmap

Планы по развитию проекта и список реализованных возможностей подробно описаны в [ROADMAP.md](ROADMAP.md).

---

## Безопасность

Политика сообщений об уязвимостях и рекомендации по защите токенов описаны в [SECURITY.md](SECURITY.md).

---

## Disclaimer

KYMusic — независимый проект с открытым исходным кодом, не связанный с компанией Яндекс. Все товарные знаки принадлежат их законным владельцам.

---

## Авторы и лицензия

- **Автор и ведущий разработчик KYMusic:** [Xyntril](https://github.com/Xyntril) (polina_leyne@proton.me) — системная архитектура, интеграция с KDE Frameworks 6, Kirigami, Plasma Mobile и MPRIS2.
- **Базовый проект:** Anders Friden ([YaMusic](https://github.com/andfriden/YaMusic)) — автор оригинального клиента.

Проект распространяется под лицензией **GNU General Public License v3.0** (GPL-3.0-or-later).
Текст лицензии доступен в файлах [LICENSE](LICENSE) и [COPYING](COPYING).
