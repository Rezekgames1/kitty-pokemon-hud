# Kitty Pokémon HUD for macOS

Анимированный Pokémon, системная HUD-карточка и удобный Zsh prompt для
[Kitty](https://sw.kovidgoyal.net/kitty/) на macOS.

Проект устанавливает готовую конфигурацию, не заменяя целиком пользовательские
`.zshrc` и `kitty.conf`. Перед изменениями создаются резервные копии, а интеграция
добавляется отдельными управляемыми блоками.

## Что входит

- 30 анимированных Pokémon со случайным выбором при каждом новом окне;
- защита от появления одного и того же Pokémon два раза подряд;
- полноразмерные GIF-кадры без исчезающих частей и графических артефактов;
- полупрозрачная Catppuccin/Tokyo Night-подобная тема Kitty;
- компактная HUD-карточка `SYSTEM` и `NETWORK`;
- версия macOS, модель Mac, kernel, uptime, shell, Kitty и CPU;
- индикатор использования RAM;
- LAN IP от роутера и VPN IP интерфейса `utun`;
- цветной `ls` на базе `eza` с Nerd Font-иконками;
- двухстрочный Zsh prompt с Git-веткой и временем;
- восстановление Pokémon и HUD после `clear` и `Ctrl+L`;
- команды ручного выбора и переключения Pokémon.

## Требования

- macOS;
- Zsh;
- [Homebrew](https://brew.sh/);
- интернет во время первой установки для загрузки зависимостей и спрайтов.

Kitty, ImageMagick, `eza` и Meslo Nerd Font установщик доставит автоматически.

## Быстрая установка

```bash
git clone https://github.com/Rezekgames1/kitty-pokemon-hud.git
cd kitty-pokemon-hud
./install.sh
```

Затем откройте новое окно Kitty или выполните внутри Kitty:

```bash
exec zsh
```

Первичная сборка 30 анимаций может занять несколько минут. После неё все файлы
работают локально и сеть для запуска терминала не нужна.

### Что делает установщик

1. Проверяет macOS и Homebrew.
2. Устанавливает `kitty`, `imagemagick`, `eza` и Meslo Nerd Font, если их нет.
3. Копирует runtime в `~/.config/pokemon-terminal/`.
4. Создаёт `~/.config/kitty/pokemon-hud.conf`.
5. Добавляет один `include` в `~/.config/kitty/kitty.conf`.
6. Добавляет одну строку `source` в `~/.zshrc`.
7. Загружает 30 исходных GIF и локально собирает безопасные полноразмерные кадры.

Перед изменением конфигов создаётся каталог:

```text
~/.config/kitty-pokemon-hud-backups/YYYYMMDD-HHMMSS/
```

Установщик идемпотентный: его можно запускать повторно для обновления без
дублирования строк в `.zshrc` или `kitty.conf`.

## Доступные Pokémon

```text
gengar       pikachu      charmander   bulbasaur    squirtle
eevee        meowth       psyduck      snorlax      jigglypuff
growlithe    abra         cubone       machop       haunter
dragonite    mew          mewtwo       chikorita    cyndaquil
totodile     umbreon      espeon       mudkip       torchic
treecko      riolu        lucario      mimikyu      rowlet
```

## Управление

```bash
# Показать доступные имена
pokemon-list

# Выбрать конкретного персонажа
pokemon lucario
pokemon gengar

# Переключить на случайного без повтора предыдущего
pokemon-random

# Убрать изображение
pokemon-stop

# Вернуть изображение
pokemon-start

# Полностью перерисовать HUD
pokemon-dashboard

# Очистить экран и автоматически восстановить HUD
clear
```

`Ctrl+L` ведёт себя так же, как настроенный `clear`.

## Настройка

### Прозрачность и цвета

Файл:

```text
~/.config/kitty/pokemon-hud.conf
```

Основной параметр прозрачности:

```conf
background_opacity 0.88
```

Рекомендуемый диапазон — `0.82–0.94`. Blur намеренно отключён: на macOS он может
создавать заметный прямоугольник вокруг изображений Kitty graphics protocol.

После изменения конфига полностью откройте новое окно Kitty.

### Размер и положение Pokémon

Файл:

```text
~/.config/pokemon-terminal/config
```

```bash
POKEMON_WIDTH=20
POKEMON_HEIGHT=10
POKEMON_LEFT=1
POKEMON_TOP=1
DASHBOARD_INFO_LEFT=23
DASHBOARD_INFO_TOP=2
DASHBOARD_PROMPT_TOP=13
```

После изменения выполните `clear`.

### Цвета файлов

Переменная `EZA_COLORS` и aliases `ls`, `ll`, `la` находятся в:

```text
~/.config/pokemon-terminal/pokemon-terminal.zsh
```

Каталоги отображаются синим, executable-файлы зелёным, Python-файлы жёлтым,
архивы красным, конфиги бирюзовым, Markdown и PHP фиолетовым.

## Диагностика

```bash
~/.config/pokemon-terminal/doctor.sh
```

Если Pokémon не появился:

```bash
echo "$TERM"
echo "$KITTY_WINDOW_ID"
~/.config/pokemon-terminal/doctor.sh
clear
```

Ожидается `TERM=xterm-kitty` и непустой `KITTY_WINDOW_ID`.

Если VPN отключён, HUD показывает `VPN ● offline`. Для VPN выбирается первый
активный `utun` с IPv4-адресом.

## Обновление

```bash
cd kitty-pokemon-hud
git pull --ff-only
./install.sh
exec zsh
```

Для принудительной пересборки всех анимаций:

```bash
~/.config/pokemon-terminal/install-sprites.sh --force
```

## Удаление

Из каталога репозитория:

```bash
./uninstall.sh
```

Удаляются только managed-блоки и файлы Kitty Pokémon HUD. Homebrew-зависимости и
резервные копии сохраняются.

## Установка без автоматических действий

Если зависимости уже установлены:

```bash
./install.sh --skip-deps
```

Для тестовой установки без скачивания анимаций:

```bash
./install.sh --skip-deps --skip-assets
```

## Источники и права

- Терминал: [Kitty](https://sw.kovidgoyal.net/kitty/)
- Animated sprites: [Project Pokémon](https://projectpokemon.org/)
- Идея Pokémon в терминале: [acxz/pokeshell](https://github.com/acxz/pokeshell)
- Иконки: [Nerd Fonts](https://www.nerdfonts.com/)

Спрайты Pokémon не хранятся в этом репозитории. Они загружаются непосредственно
из Project Pokémon во время установки. Pokémon и связанные названия принадлежат
их соответствующим правообладателям. Код проекта распространяется по MIT License.
