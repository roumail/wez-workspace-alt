local wezterm = require 'wezterm'
local bindings = require("wez-project-spaces.bindings")
local ws_labels = require("wez-project-spaces.workspace_labels")
local modes = require("wez-project-spaces.modes")
local events = require("wez-project-spaces.events")
local workspace_cache = require("wez-project-spaces.workspace_cache")
local M = {}

-- local wez_new_ws = require("plugins.wez-new-workspace.plugin")
-- https://github.com/wezterm/wezterm/issues/2933
-- wsl expects this to be done sooner
wezterm.on('gui-startup', function()
  wezterm.plugin.require("https://github.com/roumail/wez-new-workspace").setup()
  events.register()
end)

local function resolve_action(modes, ctx)
  local handler = modes[ctx.mode]
   if not handler then return nil end
  return handler(ctx)
end

local function build_ctx(window, pane, mode, extra)
  return {
    window = window,
    pane = pane,
    mode = mode,
    current_workspace = window:active_workspace(),
    workspace_history = workspace_cache.get(),
    default_workspace = workspace_cache.default_workspace(),
    id = extra and extra.id,
    label = extra and extra.label,
    path = extra and extra.path,
  }
end

function M.project_selector(mode, opts)
  local title = opts.title or ("Select Project (" .. mode .. ")")
  local modes = mode.build_modes()
  -- source-selector layer
  return wezterm.action_callback(function(window, pane)
    if mode == "alternate_workspace" then
      local ctx = build_ctx(window, pane, mode)
      local action = resolve_action(modes, ctx)

      if action then
        window:perform_action(action, pane)
	  end
      return
    end
    local projects = wezterm.plugin.require("https://github.com/roumail/wez-projects-source").load_projects()
    local active_workspaces = wezterm.mux.get_workspace_names()
    local active_set = {}
    local choices = {}

    for _, name in ipairs(active_workspaces) do
      active_set[name] = true
      table.insert(choices, {
        label = ws_labels.format_item(name, true),
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
          local ctx = build_ctx(window, pane, mode, {
              id = id,
              label = label,
              path = path,
            })
          window:perform_action(resolve_action(modes, ctx), pane)
        end)
      },
      pane
    )
  end)
end

function M.apply_to_config(config, opts)
  bindings.apply(config, opts, function(mode)
    return M.project_selector(mode, opts)
  end)
end

return M
