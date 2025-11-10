local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font('JetBrains Mono', { weight = 'Medium' })
config.font_size = 12.0

-- Color scheme
config.color_scheme = 'Nord'

-- Window
config.window_decorations = "RESIZE"
config.window_padding = { left = 2, right = 2, top = 2, bottom = 2 }

-- Tab bar
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Scrollback
config.scrollback_lines = 5000

-- Cursor
config.default_cursor_style = 'SteadyBar'

-- Performance
config.front_end = "WebGpu"
config.max_fps = 120

-- Default shell and starting directory
config.default_prog = { 'powershell.exe' }
config.default_cwd = 'C:\\GitHub'

-- Keys
config.keys = {
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab{ confirm = true } },
  { key = 'n', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnWindow },
}

return config
