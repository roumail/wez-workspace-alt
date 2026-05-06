local wezterm = require 'wezterm'
local ws_labels = require("project-spaces.workspace_labels")
local ws_cache = require("project-spaces.workspace_cache")

local M = {}


function M.build_modes()
  return {
        workspace = function(ctx)
          if not ws_cache.is_settled() then return nil end
          -- local workspace_name = ws_labels.strip_format(ctx.label)
          ws_cache.add(ctx.workspace_name)
          return wezterm.action.SwitchToWorkspace({
            name = ctx.workspace_name,
            -- when user picks an already running workspace, you switch by name
            spawn = ctx.cwd and { cwd = ctx.cwd } or nil,
            -- name = workspace_name,
            -- spawn = { cwd = ctx.id },
          })
        end,

        alternate_workspace = function(ctx)
          -- these come from history, they should be clean already
          if not ws_cache.is_settled() then return nil end
          local current = ctx.current_workspace
          ws_cache.add(current)
          local target
          local default_ws = ws_cache.default_workspace()
          -- first trigger
          if not ws_cache.is_full() then
            if current == default_ws then return nil end
            target = default_ws
          else
            local history = ctx.workspace_history
            target = history[1] == current and history[2] or history[1]
          end

          ws_cache.add(target)
          return wezterm.action.SwitchToWorkspace({
            name = target,
          })
        end,

        tab = function(ctx)
          return wezterm.action.SpawnCommandInNewTab({
            domain="CurrentPaneDomain",
            cwd = ctx.cwd,
          })
        end,

        split_h = function(ctx)
          return wezterm.action.SplitHorizontal({
            domain = "CurrentPaneDomain" ,
            cwd = ctx.cwd,
          })
        end,

        split_v = function(ctx)
          return wezterm.action.SplitVertical({
            domain = "CurrentPaneDomain" ,
            cwd = ctx.cwd,
          })
        end,
      }
end

return M
