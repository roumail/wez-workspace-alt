-- wez_workspace_alt.lua
local wezterm = require 'wezterm'
local M = {}

local fifo_cache = wezterm.plugin.require("https://github.com/roumail/fifo-cache")
local workspace_cache = fifo_cache.new(2)

local function perform_tracked_switch(window, pane, target, spawn)
  workspace_cache.add_value(target)
  local action = { name = target }
  if spawn then action.spawn = spawn end
  window:perform_action(wezterm.action.SwitchToWorkspace(action), pane)
end

local function switch_to_alternate_workspace_action()
  return wezterm.action_callback(function(window, pane)
    local current = window:active_workspace()
    workspace_cache.add_value(current)
    if not workspace_cache.is_ready() then return end
    local history = workspace_cache.get_cache()
    local target = history[1] == current and history[2] or history[1]
    perform_tracked_switch(window, pane, target)
  end)
end

local function make_switcher(window, pane)
  return function(name, spawn)
    perform_tracked_switch(window, pane, name, spawn)
  end
end

function M.switch_workspace(callback)
  local function handle_selector(window, pane, path, label)
    local do_switch =  make_switcher(window, pane)
    callback(do_switch, path, label)
  end
  return wezterm.action_callback(handle_selector)
end

function M.apply_to_config(config)
  table.insert(config.keys, {
    key = "B",
    mods = "LEADER|SHIFT",
    action = switch_to_alternate_workspace_action(),
  })
end

return M
