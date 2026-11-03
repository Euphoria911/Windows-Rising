-- WezTerm config for Lo. Ricing-grade: acrylic, wallpaper-matched colors,
-- JetBrains Mono Nerd Font, no tab bar when single tab, keyboard-first.

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ────────────────────────────────────────────────────────────────────────────
-- Fonts
-- ────────────────────────────────────────────────────────────────────────────
config.font = wezterm.font_with_fallback({
  { family = 'JetBrainsMono Nerd Font', weight = 'Regular' },
  { family = 'JetBrains Mono' },
  { family = 'Cascadia Code' },
})
config.font_size = 11.5
config.line_height = 1.05
config.cell_width = 1.0

-- ────────────────────────────────────────────────────────────────────────────
-- Colors — olive/moss palette matched to the wallpaper. Standard ANSI slots
-- so every TUI still renders naturally; only the shell BG tint
-- is olive-black and the fg is cream.
-- ────────────────────────────────────────────────────────────────────────────
config.colors = {
  background    = '#151A14',
  foreground    = '#E2E6D8',
  cursor_bg     = '#93A586',
  cursor_border = '#93A586',
  cursor_fg     = '#151A14',
  selection_bg  = '#30392C',
  selection_fg  = '#E2E6D8',
  split         = '#45513F',
  ansi = {
    '#20271D', -- black
    '#866e6e', -- red     (dusty rose)
    '#93A586', -- green   (sage)
    '#c7b89a', -- yellow  (khaki)
    '#486048', -- blue    (muted moss, intentionally not blue)
    '#866e6e', -- magenta (rose)
    '#93A586', -- cyan    (sage)
    '#d4d0c0', -- white
  },
  brights = {
    '#45513F',
    '#a89090',
    '#B6C3A6',
    '#dcd0b4',
    '#5a7a5a',
    '#a89090',
    '#B6C3A6',
    '#f0ece0',
  },
  tab_bar = {
    background = '#151A14',
    active_tab         = { bg_color = '#30392C', fg_color = '#E2E6D8' },
    inactive_tab       = { bg_color = '#20271D', fg_color = '#A9B4A0' },
    inactive_tab_hover = { bg_color = '#45513F', fg_color = '#E2E6D8', italic = false },
    new_tab            = { bg_color = '#20271D', fg_color = '#A9B4A0' },
    new_tab_hover      = { bg_color = '#45513F', fg_color = '#E2E6D8', italic = false },
  },
}

-- ────────────────────────────────────────────────────────────────────────────
-- Window chrome
-- ────────────────────────────────────────────────────────────────────────────
config.win32_system_backdrop = 'Acrylic'   -- frosted glass behind the translucent background
config.window_background_opacity = 0.80
config.text_background_opacity = 0.6
config.window_decorations = 'TITLE|RESIZE'
config.window_padding = { left = 16, right = 16, top = 12, bottom = 10 }
config.initial_cols = 108   -- fits the 38-col logo + 63-col worst-case info line, 4 cols spare
config.initial_rows = 21    -- 16 rows of startup info + 2-line prompt + breathing room (was 32)
config.enable_scroll_bar = false
config.audible_bell = 'Disabled'

-- Tab bar: hide when there's one tab, slim when more
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.tab_max_width = 32

-- ────────────────────────────────────────────────────────────────────────────
-- Shell — PowerShell 7 if present, otherwise Windows PowerShell
-- ────────────────────────────────────────────────────────────────────────────
local function first_existing(paths)
  for _, p in ipairs(paths) do
    local f = io.open(p, 'r')
    if f then f:close(); return p end
  end
  return paths[#paths]
end

-- Prefer a real PowerShell 7 install if present; otherwise Windows PowerShell
-- 5.1 which is always on disk. The WindowsApps aliases are intentionally
-- skipped because they are 0-byte reparse points that often fail.
config.default_prog = {
  first_existing({
    'C:/Program Files/PowerShell/7/pwsh.exe',
    'C:/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe',
  }),
  '-NoLogo',
}

-- ────────────────────────────────────────────────────────────────────────────
-- Keybindings — i3-style splits, Alt-based nav
-- ────────────────────────────────────────────────────────────────────────────
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1200 }
config.keys = {
  -- Pane splits
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER',       action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },

  -- Pane nav (vim-like)
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- Pane resize
  { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },

  -- Close pane
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

  -- Tabs
  { key = 't', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'LEADER', action = act.CloseCurrentTab { confirm = true } },

  -- Toggle fullscreen
  { key = 'F11', mods = '', action = act.ToggleFullScreen },

  -- Copy / paste (Ctrl+Shift+C / V)
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },

  -- Ctrl+V -> Alt+V: some TUIs paste clipboard images/text on Alt+V; plain
  -- Ctrl+V would otherwise reach the app as a raw control character.
  { key = 'v', mods = 'CTRL', action = act.SendKey { key = 'v', mods = 'ALT' } },
}

-- ────────────────────────────────────────────────────────────────────────────
-- Nicer tab labels (process name + pwd)
-- ────────────────────────────────────────────────────────────────────────────
wezterm.on('format-tab-title', function(tab)
  local pane = tab.active_pane
  local title = pane.title or ''
  local cwd = tostring(pane.current_working_dir or '')
  cwd = cwd:gsub('.*/', '') -- basename
  if cwd == '' then cwd = title end
  return ' ' .. (tab.tab_index + 1) .. ' · ' .. cwd .. ' '
end)

return config
