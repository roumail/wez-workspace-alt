local wezterm = require 'wezterm'
local ws_labels = require("project-spaces.workspace_labels")
local ws_cache = require("project-spaces.workspace_cache")
local project_store = require("project-spaces.projects")

local M = {}


function M.build_modes()
  return {
        new_workspace = function(ctx)
          ctx.window:perform_action(
            wezterm.action.PromptInputLine {
              description = "Enter workspace name:",
              action = wezterm.action_callback(function(window, pane, line)
              if not line or line == "" then return end

              if not ws_cache.is_settled() then
                return
              end

              if not project_store.exists(line) then
                project_store.add({
                  label = line,
                  path = wezterm.home_dir,
                })
              end
              ws_cache.add(line)
              window:perform_action(
                wezterm.action.SwitchToWorkspace({
                  name = line,
                  spawn = { cwd = wezterm.home_dir },
                }),
                pane
              )
            end),
          },
         ctx.pane)
        end,

        workspace = function(ctx)
          if not ws_cache.is_settled() then return nil end
          ws_cache.add(ctx.workspace_name)
          return wezterm.action.SwitchToWorkspace({
            name = ctx.workspace_name,
            -- when user picks an already running workspace, you switch by name
            spawn = ctx.is_active
            and nil or { cwd = ctx.path },
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

          ws_cache.reorder()
          return wezterm.action.SwitchToWorkspace({
            name = target,
          })
        end,

        tab = function(ctx)
          return wezterm.action.SpawnCommandInNewTab({
            domain="CurrentPaneDomain",
            cwd = ctx.path,
          })
        end,

        split_v  = function(ctx)
          return wezterm.action.SplitHorizontal({
            domain = "CurrentPaneDomain" ,
            cwd = ctx.path,
          })
        end,

        split_h= function(ctx)
          return wezterm.action.SplitVertical({
            domain = "CurrentPaneDomain" ,
            cwd = ctx.path,
          })
        end,
      }
end

return M
