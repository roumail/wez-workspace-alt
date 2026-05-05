local M = {}

local default_bindings = {
  workspace = { key = "w", mods = "LEADER" },
  alternate_workspace = function(config)
    return {
      key = string.upper(config.leader.key),
      mods = "LEADER|SHIFT",
    }
  end,
  tab = { key = "t", mods = "LEADER" },
  split_v = { key = "V", mods = "LEADER|SHIFT" },
  split_h = { key = "H", mods = "LEADER|SHIFT" },
}

local function resolve_binding(name, config, user_bindings)
  local override = user_bindings and user_bindings[name]

  if override == false then return nil end

  if override then
    return override
  end

  local default = default_bindings[name]
  if type(default) == "function" then
    return default(config)
  end

  return default
end

-- opts.bindings = {
-- workspace = { key = "p", mods = "LEADER" },
-- split_v = false,  -- disable this binding
-- }
function M.apply(config, opts, action_factory)
  opts = opts or {}
  local user = opts.bindings or {}

  local capabilities = {
    "workspace",
    "alternate_workspace",
    "tab",
    "split_v",
    "split_h",
  }
  for _, cap in ipairs(capabilities) do
    local binding = resolve_binding(cap, config, user)
    if binding then
      table.insert(config.keys, {
        key = binding.key,
        mods = binding.mods,
        action = action_factory(cap, opts),
      })
    end
  end
end

return M
