# Аудит цветов и единый источник палитры

Репозиторий: `Ark-by/arch` (локальная копия `D:\(D) Programs\Microsoft VS Code Projects\dotfiles`)

## 1. Что было

Сканирование всего дерева (кроме `.git`) по `#RGB`, `#RRGGBB`, `#RRGGBBAA`, `rgb()/rgba()`:

- **28 файлов** содержат цветовые литералы;
- **213 уникальных значений**;
- больше всего: тема Zed (179 литералов / 45 уникальных), `tmtheme.xml` для yazi (131 / 52),
  `flavor.toml` (88 / 14).

Топ-кластеры по числу файлов:

| Цвет | Файлов | Кто использует |
|---|---|---|
| `#bb9af7` `#f7768e` `#9ece6a` `#e0af68` `#7aa2f7` `#7dcfff` | 6 | kitty, quickshell, тема, yazi×2, zed |
| `#1a1b26` | 5 | kitty, quickshell, тема, yazi, zed |
| `#c0caf5` `#a9b1d6` | 4 | kitty, quickshell, тема, yazi |
| `#f38ba8` | 6 | **Catppuccin-остатки** в 5 QML + тема Catppuccin |

## 2. Классы файлов

| Класс | Файлы | Что значит |
|---|---|---|
| **Источник** | `config/themes/<name>.json` (9 тем) | единственное место, где задаются цвета |
| **Генерируется** | `kitty/theme.conf`, `quickshell/theme.json`, `hypr/colors.lua`, `yazi/flavors/*/flavor.toml`, `yazi/flavors/*/tmtheme.xml`, `zed/themes/ark-dynamic.json` | пишет `set-theme` из палитры |
| **ANSI-потребители** | `extras/.zshrc`, `extras/.oh-my-zsh/custom/themes/ark.zsh-theme`, `config/fastfetch/config.jsonc` | используют имена/номера ANSI (`%F{green}`, `"keyColor": "blue"`) — цвет берётся из терминала |
| **Хардкод** | `quickshell/*.qml` | было 7 мест, теперь 0 (см. п.4) |

Логика: **ANSI 0–15 — это и есть контракт**. kitty получает палитру из JSON, а zsh/fastfetch
обращаются к ANSI-именам → автоматически совпадают. Отдельная генерация им не нужна.

## 3. Найденные расхождения (до правки)

| Что | Было | Должно быть |
|---|---|---|
| `kitty/theme.conf` → `color8` | `#7e86a8` | `#414868` (как в палитре) |
| `quickshell/theme.json` → `ansi[8]` | `#7e86a8` | `#414868` |
| `quickshell/Theme.qml` дефолты | Catppuccin: `#1e1e2e`, `#313244`, `#cdd6f4`, `#89b4fa`, `#6c7086` | Tokyo Night |
| QML `hoverColor` (5 файлов) | `#f38ba8` (Catppuccin red) | `Theme.error` |
| `MetricRow.qml` | `#f38ba8` / `#f9e2af` | `Theme.error` / `Theme.warning` |
| `WallpaperPicker.qml` | `#555555` | `Theme.muted` |
| `fastfetch`: 13 модулей | `"color": "white"` — **невалидный ключ**, молча игнорировался | `"outputColor": "white"` |
| `fastfetch`: kernel | `"type": "   kernel"` — модуль не существовал, строка пропадала | `"type": "kernel"` |
| `fastfetch`: colors | `"colors": [...]` — у модуля нет такой опции | удалено |

## 4. Как устроено теперь

```
config/themes/tokyonight.json      ← ЕДИНСТВЕННЫЙ ИСТОЧНИК
        │
        ├── set-theme ──► kitty/theme.conf          (bg/fg/cursor/selection + 16 ANSI)
        │             ──► quickshell/theme.json     (копия палитры)
        │             ──► hypr/colors.lua           (рамки окон)
        │             ──► yazi/flavors/*/flavor.toml   (из шаблона)
        │             ──► yazi/flavors/*/tmtheme.xml  (из шаблона)
        │             ──► zed/themes/ark-dynamic.json (из шаблона)
        │
        ├── ANSI 0–15 ──► zsh / oh-my-zsh          (%F{green} и т.п.)
        │             ──► fastfetch                ("keyColor": "blue")
        │             ──► yazi (часть UI)
        │
        └── Theme.qml (читает theme.json) ──► все QML панели
```

`Theme.qml` теперь отдаёт не 5 свойств, а 13: `bg, surface, fg, accent, muted, error, warning,
success, info, border, muted2, elevated, bg2`. Семантика (`error/warning/success/info/border`)
выводится из `ansi[1..8]`, поэтому работает с любой темой, даже если у неё нет явных ключей.

## 5. Маппинг слотов

| Слот | Tokyo Night | ANSI | Потребители |
|---|---|---|---|
| `bg` | `#1a1b26` | — | kitty bg, Zed background, QML фон |
| `surface` | `#292e42` | — | yazi tabs, QML плашки |
| `fg` | `#c0caf5` | 15 | kitty fg, Zed text, QML текст |
| `accent` | `#7aa2f7` | 4 | курсор, выделение, акцент панели |
| `muted` | `#565f89` | 8 | комментарии, неактивное |
| `error` | `#f7768e` | 1 | hover-крестики, ошибки, диск |
| `warning` | `#e0af68` | 3 | предупреждения, нагрузка |
| `success` | `#9ece6a` | 2 | успех, git clean |
| `info` | `#7dcfff` | 6 | инфо, ссылки |
| `border` | `#414868` | 8 | рамки yazi, line numbers |
| `orange` | `#ff9e64` | 11 | числа/константы в Zed |
| `teal` | `#73daca` | 6 | типы, preproc |
| `type` | `#2ac3de` | — | enum, поддержка |
| `operator` | `#89ddff` | — | операторы, пунктуация |

## 6. Как пользоваться

```bash
# сменить тему во всём сразу
~/.local/bin/set-theme tokyonight

# проверить, не завёлся ли где-то хардкод
~/.local/bin/colors-audit

# после правки QML/шаблонов
pkill -x qs; qs &
```

`set-theme` пишет `ZED_ALPHA` (по умолчанию `cc` = 80 %) и `YAZI_FLAVOR` (по умолчанию
`tokyo-night`).

## 7. Ограничения

- **zsh и fastfetch** используют ANSI: в терминале без палитры kitty (tty, Zed-терминал) цвета
  будут другими. Это не баг, а следствие «ANSI как контракт».
- **yazi**: TUI-часть берёт ANSI, но `flavor.toml` задаёт точные hex → при смене темы
  перегенерируется через `set-theme`.
- **`tmtheme.xml`** (подсветка превью в yazi): в шаблоне параметризованы ~40 основных цветов,
  около 20 редких оттенков Tokyo Night остались статичными (глубокие JSON-скоупы, inline-raw).
- **Темы в `config/themes/*.json`** (dracula, nord, gruvbox и т.д.) — это альтернативные палитры,
  их значения не унифицируются: они и есть источник при переключении.
- **Все цвета картинок-логотипов** (PNG в `config/fastfetch/assets`) не анализируются — это не CSS.