local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

-- ========================================
-- Color Scheme
-- ========================================
config.color_scheme = 'GruvboxLight'

-- ========================================
-- Font
-- ========================================
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  config.font = wezterm.font('Consolas')
  config.font_size = 13.0
elseif wezterm.target_triple:find('darwin') then
  config.font = wezterm.font('Menlo')
  config.font_size = 14.0
else
  config.font = wezterm.font('DejaVu Sans Mono')
  config.font_size = 14.0
end

-- ========================================
-- UI Tweaks
-- ========================================
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false

-- ========================================
-- MRU Tab Tracking
-- ========================================
local mru_tabs = {}
local mru_counter = 0

wezterm.on('update-status', function(window, pane)
  local tab = window:active_tab()
  if tab then
    mru_counter = mru_counter + 1
    mru_tabs[tab:tab_id()] = mru_counter
  end
end)

local function get_mru_sorted_tabs(window)
  local tabs = window:tabs()
  local tab_scores = {}
  for _, tab in ipairs(tabs) do
    table.insert(tab_scores, {
      tab = tab,
      score = mru_tabs[tab:tab_id()] or 0
    })
  end
  table.sort(tab_scores, function(a, b)
    return a.score > b.score
  end)
  local result = {}
  for _, entry in ipairs(tab_scores) do
    table.insert(result, entry.tab)
  end
  return result
end

local function focus_mru_tab(window, pane, n)
  local mru_sorted = get_mru_sorted_tabs(window)
  if #mru_sorted >= n then
    mru_sorted[n]:activate()
  end
end

-- ========================================
-- Keybindings
-- ========================================
config.keys = {
  -- Pane Navigation (Alt+[ and Alt+])
  { key = ']', mods = 'ALT', action = act.ActivatePaneDirection 'Next' },
  { key = '[', mods = 'ALT', action = act.ActivatePaneDirection 'Prev' },

  -- Pane Navigation (Ctrl+Shift+h/j/k/l for directional)
  { key = 'h', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },

  -- Splits (Ctrl+Shift+s for horizontal, Ctrl+Shift+v for vertical)
  { key = 's', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },

  -- New tab (Ctrl+Shift+t)
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },

  -- Close current pane
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },

  -- Close current tab (Alt+Shift+0, which is Alt+))
  { key = '0', mods = 'ALT|SHIFT', action = act.CloseCurrentTab { confirm = true } },

  -- Tab launcher (Shift+S)
  { key = 'S', mods = 'SHIFT', action = act.ShowLauncher },

  -- MRU Tab Navigation
  { key = 'PageUp', mods = 'ALT|CTRL', action = wezterm.action_callback(function(window, pane)
    focus_mru_tab(window, pane, 1)
  end) },
  { key = 'PageDown', mods = 'ALT|CTRL', action = wezterm.action_callback(function(window, pane)
    focus_mru_tab(window, pane, 2)
  end) },
  { key = '{', mods = 'ALT', action = wezterm.action_callback(function(window, pane)
    focus_mru_tab(window, pane, 3)
  end) },
  { key = '}', mods = 'ALT', action = wezterm.action_callback(function(window, pane)
    focus_mru_tab(window, pane, 4)
  end) },

  -- Scrolling (Ctrl+d and Ctrl+u)
  { key = 'd', mods = 'CTRL', action = act.ScrollByPage(0.5) },
  { key = 'u', mods = 'CTRL', action = act.ScrollByPage(-0.5) },

  -- Equalize pane sizes (like Ctrl+w+=)
  { key = '=', mods = 'CTRL|SHIFT', action = act.PaneSelect { mode = 'SwapWithActive' } },
}

-- ========================================
-- Tab Bar Formatting
-- ========================================
local function get_tab_title(tab)
  local title = tab.tab_title
  if title and #title > 0 then
    return title
  end

  local pane = tab.active_pane
  local pane_title = pane.title

  -- Extract command from title if it's a terminal
  if pane_title:match('^Administrator:') then
    local cmd = pane_title:match('^Administrator:%s*(.*)$')
    if cmd and #cmd > 0 then
      return cmd
    end
  end

  local foreground = pane.foreground_process_name
  if foreground then
    local cmd = foreground:match('([^/\\]+)$')
    if cmd then
      return cmd
    end
  end

  return pane_title
end

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local title = get_tab_title(tab)

  -- Show positional number for first 4 tabs
  local prefix = ''
  for i, t in ipairs(tabs) do
    if t.tab_id == tab.tab_id and i <= 4 then
      prefix = tostring(i) .. '. '
      break
    end
  end

  local formatted = prefix .. title .. ' '

  if tab.is_active then
    return {
      { Foreground = { Color = '#282828' } },
      { Background = { Color = '#ebdbb2' } },
      { Text = formatted },
    }
  else
    return {
      { Foreground = { Color = '#7c6f64' } },
      { Background = { Color = '#f9f5d7' } },
      { Text = formatted },
    }
  end
end)

-- ========================================
-- Pane Title (Window Title Bar)
-- ========================================
wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
  local cwd = pane.current_working_dir
  if cwd then
    local path = cwd.file_path or cwd
    local basename = path:match('([^/\\]+)$')
    if basename then
      return basename
    end
  end
  return get_tab_title(tab)
end)

return config
