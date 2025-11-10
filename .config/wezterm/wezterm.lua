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
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

-- Scrollback
config.scrollback_lines = 10000

-- Cursor
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

-- Performance
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 144
config.animation_fps = 60

-- Default shell and starting directory
config.default_prog = { 'powershell.exe' }
config.default_cwd = 'C:\\GitHub'

-- Clipboard
config.use_dead_keys = false
config.scrollback_lines = 10000

-- Keys
config.keys = {
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
  { key = 'c', mods = 'CTRL', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL', action = wezterm.action.PasteFrom 'Clipboard' },
  { key = 'Insert', mods = 'SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
  { key = 'Insert', mods = 'CTRL', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 't', mods = 'CTRL', action = wezterm.action.SpawnTab{ domain = 'CurrentPaneDomain', cwd = 'C:\\GitHub' } },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab{ confirm = true } },
  { key = 'n', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnWindow },
  { key = ']', mods = 'ALT', action = wezterm.action.ActivateTabRelative(1) },
  { key = '[', mods = 'ALT', action = wezterm.action.ActivateTabRelative(-1) },
}

-- Mouse
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'NONE', action = wezterm.action.CompleteSelection 'ClipboardAndPrimarySelection' },
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = wezterm.action.OpenLinkAtMouseCursor },
  { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE', action = wezterm.action.PasteFrom 'Clipboard' },
}

return config
