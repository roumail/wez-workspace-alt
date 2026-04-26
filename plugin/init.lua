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

--
-- InputSelector UI gives us path, label
function M.switch_workspace(selector)
  return wezterm.action_callback(function(window, pane, path, label)
    local ctx = {
        window = window,
        pane = pane,
        path = path,
        label = label,
        current_workspace = window:active_workspace(),
        workspace_history = workspace_cache.get_cache(),
    }
    local result = selector(ctx)
    if not result then return end
    perform_tracked_switch(
      window,
      pane,
      result.name,
      result.spawn
    )
  end)
end

--
-- State driven selection
local function switch_to_alternate_workspace_action()
  return M.switch_workspace(function(ctx)
    local current = ctx.current_workspace
    workspace_cache.add_value(current)
    if not workspace_cache.is_ready() then return end
    local history = ctx.workspace_history
    local target = history[1] == current and history[2] or history[1]
    return {
      name = target
    }
  end)
end


function M.project_selector(opts)
  opts = opts or {}

  local projects = opts.projects
  local title = opts.title or "Select Project"

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
    action = M.switch_workspace(function(ctx)
      return {
        name = ctx.label,
        spawn = { cwd = ctx.path }
      }
    end),
  }
end

function M.apply_to_config(config)
  table.insert(config.keys, {
    key = "B",
    mods = "LEADER|SHIFT",
    action = switch_to_alternate_workspace_action(),
  })
end

return M
