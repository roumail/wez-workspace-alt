-- wez_workspace_alt.lua
local wezterm = require 'wezterm'
local M = {}

local fifo_cache = wezterm.plugin.require("https://github.com/roumail/fifo-cache")
local workspace_cache = fifo_cache.new(2)

local function resolve_action(ctx)
  local mode = ctx.mode
  local handler = M.modes[mode]
  if not handler then return nil end
  return handler(ctx)
end

M.modes = {
  workspace = function(ctx)
    workspace_cache.add_value(ctx.label)
    return wezterm.action.SwitchToWorkspace({
      name = ctx.label,
      spawn = { cwd = ctx.path },
    })
  end,

  alternate_workspace = function(ctx)
    local current = ctx.current_workspace
    workspace_cache.add_value(current)

    if not workspace_cache.is_ready() then return nil end

    local history = ctx.workspace_history
    local target = history[1] == current and history[2] or history[1]

    workspace_cache.add_value(target)
    return wezterm.action.SwitchToWorkspace({
      name = target,
    })
  end,

  tab = function(ctx)
    return wezterm.action.SpawnTab({
      cwd = ctx.path,
    })
  end,

  split_h = function(ctx)
    return wezterm.action.SplitHorizontal({
      domain = { DomainName = "currentPaneDomain" },
      cwd = ctx.path,
    })
  end,

  split_v = function(ctx)
    return wezterm.action.SplitVertical({
      domain = { DomainName = "currentPaneDomain" },
      cwd = ctx.path,
    })
  end,
}

function M.run_mode(mode)
  return wezterm.action_callback(function(window, pane)
    local ctx = {
      window = window,
      pane = pane,
      current_workspace = window:active_workspace(),
      workspace_history = workspace_cache.get_cache(),
      mode = mode,
    }

    local action = resolve_action(ctx)
    if action then
      window:perform_action(action, pane)
    end
  end)
end

function M.project_selector(opts)
  opts = opts or {}
  local mode = opts.mode or "workspace"

  local projects = opts.projects
  local title = opts.title or("Select Project (" .. mode .. ")")

  local choices = {}
  for _, p in ipairs(projects) do
    if type(p) == "table" and p.label and p.path then
      table.insert(choices, { label = p.label, id = p.path })
    end
  end

  return wezterm.action.InputSelector {
    title = title,
    choices = choices,
    fuzzy = true,
    action = wezterm.action_callback(function(window, pane, path, label)
    local ctx = {
      window = window,
      pane = pane,
      path = path,
      label = label,
      current_workspace = window:active_workspace(),
      workspace_history = workspace_cache.get_cache(),
      mode = mode,
    }
    -- passing args to action?
    local action = resolve_action(ctx)
    window:perform_action(action, pane)
  end)}
end

function M.apply_to_config(config)
  table.insert(config.keys, {
    key = "B",
    mods = "LEADER|SHIFT",
    action = M.run_mode("alternate_workspace"),
    })
end

return M
