# Onyx UI Library

UI library with an animated intro, themes, and built-in **Settings** (hide key, themes, unload).

```lua
local Onyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/nuj5/onyx/main/onyx.lua"))()
```

## Window

`Onyx:CreateWindow(opts)` returns a `Window`.

| Option | Default | Notes |
|---|---|---|
| `Id` | `"Onyx"` | Re-running a script with the same Id destroys the old window |
| `Title` / `Subtitle` / `Logo` | `"Onyx Hub"` / `""` / `"O"` | Sidebar branding (Logo is one character) |
| `Splash` | Title | Star-splash text, `false` skips the splash |
| `Intro` | `true` | `false` shows the window immediately |
| `ToggleKey` | `RightAlt` | Hide / show key, rebindable in Settings |
| `Theme` | `"winter"` | `winter light dark mono autumn sakura forest` |
| `Credits` | `{}` | `{ Name, Version, Title, Label, Logo }` |
| `LoadedNotice` | `true` | Toast after the intro |
| `OnUnload` | none | Called once from `Window:Destroy()` |

Window methods: `AddTab(name)`, `Notify(title, body, seconds)`, `SetStatus(text, color)`, `SetTheme(name)`, `GetTheme()`, `SetToggleKey(keyCode)`, `Toggle()`, `SelectTab(tab)`, `Destroy()`. `Window.Flags` holds the current value of every control created with a `Flag`. `Window.Alive` is `false` after destroy. Your tabs appear first in the sidebar, then Settings, then Credits.

## Tabs and cards

`Tab:AddCard({ Title, Subtitle, Column })` with `Column` = `"Left"`, `"Right"` or `"Wide"` (omit it to use the shorter column). Cards size themselves to their rows, and the page scrolls when it overflows.

## Controls (all on a card)

| Call | Returns |
|---|---|
| `AddToggle({ Label, Default, Flag, Callback(value) })` | `{ Get(), Set(value, silent) }` |
| `AddNumber({ Label, Default, Min, Max, Integer, Flag, Callback(value) })` | `{ Get(), Set(value, silent) }` |
| `AddButton({ Label, Danger, Callback() })` | the `TextButton` |
| `AddLabel({ Text, Height })` | `{ SetText(text) }` |
| `AddKeybind({ Label, Default, Pressed(), Changed(keyCode) })` | `{ Get(), Set(keyCode, silent) }` |
| `AddCustom(height, build(frame))` | a blank row to build anything in |

`Default` never fires `Callback`. Callbacks run under `pcall`, so an error in one only prints a warning.

## Custom themes

```lua
Onyx.RegisterTheme("mytheme", "My Theme", { ... })  -- must define every token, copy an entry from Onyx.Themes
```
Register before `CreateWindow` so it shows in the picker.
