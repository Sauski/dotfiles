local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 11.0

-- Color scheme
config.color_scheme = 'Tokyo Night'

-- Window
config.window_background_opacity = 0.95
config.window_padding = { left = 2, right = 2, top = 2, bottom = 2 }

-- Tab bar
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Scrollback
config.scrollback_lines = 10000

-- Cursor
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

-- Automatically reload config
config.automatically_reload_config = true

-- Keys
config.keys = {
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab{ confirm = true } },
  { key = 'n', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnWindow },
}

return config
