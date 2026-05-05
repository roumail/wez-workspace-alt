local wezterm = require 'wezterm'
local ws_cache = require("wez-project-spaces.workspace_cache")
local M = {}

function M.register()
  wezterm.on("workspace-removed", function(event)
    ws_cache.handle_workspace_removed(event)
  end)
end
return M
