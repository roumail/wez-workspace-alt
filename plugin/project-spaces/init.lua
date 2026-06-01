local wezterm = require 'wezterm'
local bindings = require("project-spaces.bindings")
local mode_registry = require("project-spaces.modes")
local selector_builder = require("project-spaces.selector_builder")
local events = require("project-spaces.events")
local ws_cache = require("project-spaces.workspace_cache")
local ws_new = require("project-spaces.new_workspace")
local initialized_cache = false
local M = {}
-- TODO: take work, as a label, if I rename that, currently active workspace
-- I'd have expected it to appear as another entry in my active projects under the new name
-- and continue to see the old work workspace as a separate entry
-- That's however not the case
-- local wez_new_ws = require("plugins.wez-new-workspace.plugin")
-- https://github.com/wezterm/wezterm/issues/2933
-- wsl expects this to be done sooner
wezterm.on('gui-startup', function()
  ws_new.setup()
  events.register()
end)

local function resolve_action(modes, ctx)
  local handler = modes[ctx.mode]
   if not handler then return nil end
  return handler(ctx)
end

local function build_ctx(window, pane, mode, ws)
  return {
    window = window,
    pane = pane,
    mode = mode,
    current_workspace = window:active_workspace(),
    workspace_history = ws_cache.get(),
    default_workspace = ws_cache.default_workspace(),
    workspace_name = ws and ws.workspace_name,
    path = ws and ws.path,
    is_active = ws and ws.is_active,
    formatted_label = ws and ws.formatted_label,}
end

local function project_selector(capability, opts)
  local opts = opts or {}
  local title = opts.title or ("Select Project (" .. capability .. ")")
  local handlers = mode_registry.build_modes()
  -- source-selector layer
  return wezterm.action_callback(function(window, pane)
    if capability == "alternate_workspace" then
      local ctx = build_ctx(window, pane, capability)
      local action = resolve_action(handlers, ctx)

      if action then
        window:perform_action(action, pane)
	  end
      return
    end
    local selector_model = selector_builder.build()
    window:perform_action(
      wezterm.action.InputSelector {
        title = title,
        fuzzy=true,
        --- use wezformat.format on active and display them above
        choices = selector_model.choices,
        description = 'choose active or new workspace',
        -- switcher layer
        action = wezterm.action_callback(function(window, pane, id, label)
          if not id and not label then return end
          if id == "___NEW___" then
            local ctx = build_ctx(window, pane, "new_workspace")
            local next_action = resolve_action(handlers, ctx)
            if next_action then
              window:perform_action(next_action, pane)
            end
            return
          end
          local ws = selector_model.workspaces[id]
          if not ws then
            return
          end
          local ctx = build_ctx(window, pane, capability, ws)
          local next_action = resolve_action(handlers, ctx)
          if next_action then
            window:perform_action(next_action, pane)
          end
        end)
      },
      pane
    )
  end)
end

function M.apply_to_config(config, opts)
  -- This check ensures we add default workspace to cache only runs once per WezTerm GUI session
  if not initialized_cache then
        ws_cache.add(ws_cache.default_workspace())
    initialized_cache = true
  end
  bindings.apply(config, opts, function(mode)
    return project_selector(mode, opts)
  end)
end

return M
