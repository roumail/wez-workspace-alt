-- wez_project_spaces.lua
local wezterm = require("wezterm")
local module_id = ...

-- find the root and add the contents of plugin to path
for _, plugin in ipairs(wezterm.plugin.list()) do
    if plugin.component == module_id then
        local sep = package.config:sub(1, 1)
        local base = plugin.plugin_dir .. sep .. "plugin" .. sep
        -- add root/plugin/?.lua and plugin/?/init.lua
        package.path = table.concat({
          package.path,
          base .. "?.lua",
          base .. "?" .. sep .. "init.lua",
        }, ";")
        break
    end
end

return require("wez-project-spaces")
