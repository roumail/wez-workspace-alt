-- wez_workspace_alt.lua
local wezterm = require 'wezterm'
local M = {}

local fifo_cache = wezterm.plugin.require("https://github.com/roumail/fifo-cache")
local workspace_cache = fifo_cache.new(2)

local function track_workspace(name)
  if name and name ~= "" then
    workspace_cache.add_value(name)
  end
end

local function perform_tracked_switch(window, pane, name, spawn)
  if not name or name == "" then return end
  track_workspace(window:active_workspace())
  track_workspace(name)
  local action = { name = name }
  if spawn then action.spawn = spawn end
  window:perform_action(wezterm.action.SwitchToWorkspace(action), pane)
end

local function switch_to_alternate_workspace_action()
  return wezterm.action_callback(function(window, pane)
    track_workspace(window:active_workspace())
    if not workspace_cache.is_ready() then return end
    local history = workspace_cache.get_cache()
    local current = window:active_workspace()
    local target = history[1] == current and history[2] or history[1]
    if target and target ~= current then
      perform_tracked_switch(window, pane, target)
    end
  end)
end

function M.switch_workspace(callback)
  return wezterm.action_callback(function(window, pane, path, label)
    local function do_switch(name, spawn)
      perform_tracked_switch(window, pane, name, spawn)
    end
    callback(do_switch, path, label)
  end)
end

function M.apply_to_config(config)
  table.insert(config.keys, {
    key = "B",
    mods = "LEADER|SHIFT",
    action = switch_to_alternate_workspace_action(),
  })
end

return M
