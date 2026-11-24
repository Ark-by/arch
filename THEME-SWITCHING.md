# Переключение темы: что обновляется и как

`ThemePicker` (Super+T) вызывает `~/.local/bin/set-theme <имя>`.
Единственный источник цветов — `~/.config/themes/<имя>.json`.

## Что происходит при переключении

| Компонент | Как получает цвета | Обновление |
|---|---|---|
| **Quickshell** (бар, меню) | `~/.config/quickshell/theme.json` ← копия палитры | **live**: `Theme.qml` следит за файлом |
| **kitty** | `~/.config/kitty/theme.conf` ← генерация | **live**: `pkill -USR1 kitty` |
| **Hyprland** (рамки) | `~/.config/hypr/colors.lua` ← генерация | **live**: `hyprctl reload` + `dofile` (без кэша Lua) |
| **Zed** | `~/.config/zed/themes/ark-<палитра>.json` + `"theme"` в `settings.json` | **live**: имя темы меняется, Zed перечитывает |
| **yazi** | `~/.config/yazi/flavors/ark.yazi/` + `dark = "ark"` в `theme.toml` | **перезапуск yazi** |
| **zsh / oh-my-zsh** | ANSI-имена (`%F{green}`, `%F{blue}`) | **live**: терминал перекрашивается kitty |
| **fastfetch** | ANSI-имена (`"keyColor": "blue"`, `"outputColor": "white"`) | **live** при следующем запуске |

## Почему Hyprland требовал правки

`hyprland.lua` делал `require("colors")` — Lua кэширует модуль, и `hyprctl reload`
возвращал старые цвета. Теперь:

```lua
local colors = dofile(os.getenv("HOME") .. "/.config/hypr/colors.lua")
```

`dofile` читает файл каждый раз → рамки меняются сразу.

## Почему Zed видит смену темы

`set-theme` генерирует файл **для каждой палитры** сразу:
`ark-tokyonight.json`, `ark-catppuccin.json`, … и прописывает `"theme": "Ark <Name>"`.
Переключение = смена имени в `settings.json`, а не подмена содержимого одного файла —
Zed гарантированно загружает нужную тему.

## Почему zsh и fastfetch не надо генерировать

Они используют **ANSI 0–15**, а эти 16 цветов задаёт kitty, который генерится из палитры.
То есть в `.zshrc`, `ark.zsh-theme` и `config.jsonc` hex-литералов нет вообще —
цепочка «палитра → kitty → ANSI → zsh/fastfetch» уже замкнута.

## Если что-то не перекрасилось

```bash
~/.local/bin/colors-audit      # ищет хардкод и расхождения theme.json ↔ kitty
hyprctl getoption general:col.active_border
cat ~/.config/quickshell/theme.json | jq -r .name
grep '"theme"' ~/.config/zed/settings.json
```

- yazi — перезапустить;
- Zed — если тема не появилась, `zed` надо перезапустить (он сканирует `themes/` при старте,
  дальше переключение идёт по имени);
- kitty — новые окна/вкладки подхватят точно, старые обычно тоже.

## Ограничения

- В терминале без палитры kitty (tty) zsh/fastfetch будут в стандартных ANSI-цветах.
- `tmtheme.xml` для превью yazi: ~40 цветов параметризованы, ~20 редких — статичны.
- Темы-палитры (`dracula`, `nord`, …) — самостоятельные источники; правишь их — меняется всё.