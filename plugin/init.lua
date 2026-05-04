-- wez_workspace_alt.lua
local wezterm = require 'wezterm'
local M = {}

-- local fifo_cache = require("plugins.fifo-cache.plugin")
local cache_settled = true
local fifo_cache = wezterm.plugin.require("https://github.com/roumail/fifo-cache")
local wez_new_ws = wezterm.plugin.require("https://github.com/roumail/wez-new-workspace")
-- local wez_new_ws = require("plugins.wez-new-workspace.plugin")
-- https://github.com/wezterm/wezterm/issues/2933
-- wsl expects this to be done sooner
wezterm.on('gui-startup', function()
  wez_new_ws.setup()
end)
local workspace_cache = fifo_cache.new(2)
local DEFAULT_WORKSPACE = "default"

local function get_projects()
  local wez_projects = wezterm.plugin.require("https://github.com/roumail/wez-projects-source")
  return wez_projects.load_projects()
end

local function resolve_action(ctx)
  local mode = ctx.mode
  local handler = M.modes[mode]
  if not handler then return nil end
  return handler(ctx)
end

local function rebalance_cache(current)
  local cache = workspace_cache.get_cache()

  local in_cache = {}
  for _, v in ipairs(cache) do
    in_cache[v] = true
  end

  if not in_cache[DEFAULT_WORKSPACE] then
    for _, v in ipairs(current) do
      if v == DEFAULT_WORKSPACE then
        workspace_cache.add_value(v)
        return
      end
    end
  end

  -- Otherwise pick the first sorted candidate not already in cache
  table.sort(current)

  for _, v in ipairs(current) do
    if not in_cache[v] then
      workspace_cache.add_value(v)
      return
    end
  end
end

wezterm.on('workspace-removed', function(event)
  cache_settled = false
  -- Normalize cache first to prevent cache being out of sync
  -- with reality
  local current_set = {}
  for _, name in ipairs(event.current) do
    current_set[name] = true
  end

  local cache = workspace_cache.get_cache()
  for _, name in ipairs(cache) do
    if not current_set[name] then
      workspace_cache.evict_keys(name)
    end
  end
  -- rebalance in the case where a previously ready cache
  -- now needs a replacement
  ready_prior = workspace_cache.is_ready()
  workspace_cache.evict_keys(event.removed)
  ready_post = workspace_cache.is_ready()
  if ready_prior and not ready_post then
    rebalance_cache(event.current)
  end
  cache_settled = true
end)

local function strip_format(text)
  if not text then return nil end

  -- 1. Strip ANSI escape codes.
  -- We MUST do this first because codes like '32m' look like words.
  local clean = text:gsub("\27[^%a]*[%a]", "")

  -- 2. Positive Extraction: Grab the workspace name!
  -- We look for 2+ characters consisting of alphanumeric, underscore, hyphen, or dot.
  -- This inherently ignores ZWS, bullets, whitespace, and stray single characters.
  local workspace_name = clean:match("[%w_%.%-][%w_%.%-]+")

  -- 3. Fallbacks
  -- If we can't find 2 chars, try to find 1 valid char.
  -- If that fails, just trim whatever is left.
  if not workspace_name then
    workspace_name = clean:match("[%w_%.%-]+") or clean:match("^%s*(.-)%s*$")
  end

  return workspace_name
end

local function format_item(label, is_active)
  local MARKER = "\u{200b}"

  -- IDEMPOTENCY CHECK:
  -- If the string already contains our marker, it's already formatted.
  -- We use plain = true to treat the marker as a literal string.
  if label:find(MARKER, 1, true) then
    return label
  end

  if is_active then
    return MARKER .. wezterm.format({
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { AnsiColor = "Green" } },
      { Text = " ● " .. label .. " " },
    })
  else
    return MARKER .. wezterm.format({
       { Foreground = { AnsiColor = "Silver" } },
       "ResetAttributes",
      { Text = "   " .. label .. " " },
    })
  end
end

M.modes = {
  workspace = function(ctx)
    if not cache_settled then return nil end
    workspace_name = strip_format(ctx.label)
    workspace_cache.add_value(workspace_name)
    return wezterm.action.SwitchToWorkspace({
      name = workspace_name,
      spawn = { cwd = ctx.id },
    })
  end,

  alternate_workspace = function(ctx)
    -- these come from history, thye should be clean already
    if not cache_settled then return nil end
    local current = ctx.current_workspace
    workspace_cache.add_value(current)
    local target
    -- first trigger
    if not workspace_cache.is_ready() then
      if current == DEFAULT_WORKSPACE then return nil end
      target = DEFAULT_WORKSPACE
    else
      local history = ctx.workspace_history
      target = history[1] == current and history[2] or history[1]
    end

    workspace_cache.add_value(target)
    return wezterm.action.SwitchToWorkspace({
      name = target,
    })
  end,

  tab = function(ctx)
    return wezterm.action.SpawnCommandInNewTab({
      domain="CurrentPaneDomain",
      cwd = ctx.id,
    })
  end,

  split_h = function(ctx)
    return wezterm.action.SplitHorizontal({
      domain = "CurrentPaneDomain" ,
      cwd = ctx.id,
    })
  end,

  split_v = function(ctx)
    return wezterm.action.SplitVertical({
      domain = "CurrentPaneDomain" ,
      cwd = ctx.id,
    })
  end,
}

function M.project_selector(mode, opts)
  local title = opts.title or ("Select Project (" .. mode .. ")")
  -- source-selector layer
  return wezterm.action_callback(function(window, pane)
    if mode == "alternate_workspace" then
      local action = resolve_action({
        window = window,
        pane = pane,
        current_workspace = window:active_workspace(),
        workspace_history = workspace_cache.get_cache(),
        mode = mode,
      })

      if action then
        window:perform_action(action, pane)
	  end
      return
    end
    local projects = get_projects()
    local active_workspaces = wezterm.mux.get_workspace_names()
    local active_set = {}
    local choices = {}

    for _, name in ipairs(active_workspaces) do
      active_set[name] = true
      table.insert(choices, {
        label = format_item(name, true),
        id = name,
      })
    end

    for _, p in ipairs(projects) do
      if type(p) == "table" and p.label and p.path then
        if not active_set[p.label] then
          table.insert(choices, {
            label = format_item(p.label, false),
            id = p.path,
          })
        end
      end
    end

    -- input selector
    window:perform_action(
      wezterm.action.InputSelector {
        title = title,
        fuzzy=true,
        --- use wezformat.format on active and display them above
        choices = choices,
        description = 'choose active or new workspace',
        -- switcher layer
        action = wezterm.action_callback(function(window, pane, id, label)
          if not id and not label then return end
          window:perform_action(resolve_action({
            window = window,
            id = id,
            path = path,
            label = label,
            current_workspace = window:active_workspace(),
            workspace_history = workspace_cache.get_cache(),
            mode = mode,
          }), pane)
        end)
      },
      pane
    )
  end)
end

function M.apply_to_config(config, opts)
  local leader_key = string.upper(config.leader.key)
  opts = opts or {}
  my_keys = {
    {
      key = "w",
      mods = "LEADER",
      action = M.project_selector("workspace", opts),
    },
    {
      key = leader_key,
      mods = "LEADER|SHIFT",
      action = M.project_selector("alternate_workspace", opts),
    },
    {
      key    = "t",
      mods   = "LEADER",
      action = M.project_selector("tab", opts),
    },
    {
      key    = "V",
      mods   = "LEADER|SHIFT",
      action = M.project_selector("split_v", opts),
    },
    {
      key    = "H",
      mods   = "LEADER|SHIFT",
      action = M.project_selector("split_h", opts),
    }
  }
  for _, key in ipairs(my_keys) do
    table.insert(config.keys, key)
  end
end

  return M
