local wezterm = require 'wezterm'
local M = {}

local cache_settled = true
-- local fifo_cache = require("plugins.fifo-cache.plugin")
local workspace_cache = wezterm.plugin.require("https://github.com/roumail/fifo-cache").new(2)
local DEFAULT_WORKSPACE = "default"

function M.is_settled()
  return cache_settled
end

function M.get()
  return workspace_cache.get_cache()
end

function M.add(name)
  return workspace_cache.add_value(name)
end

function M.is_full()
  return workspace_cache.is_ready()
end

function M.default_workspace()
  return DEFAULT_WORKSPACE
end

local function rebalance_cache(current)
  local cache = workspace_cache.get_cache()

  local in_cache = {}
  for _, v in ipairs(cache) do
    in_cache[v] = true
  end

  if not in_cache[DEFAULT_WORKSPACE] then
    for _, v in ipairs(current) do
      if v == DEFAULT_WORKSPACE then
        workspace_cache.add_value(v)
        return
      end
    end
  end

  -- Otherwise pick the first sorted candidate not already in cache
  table.sort(current)

  for _, v in ipairs(current) do
    if not in_cache[v] then
      workspace_cache.add_value(v)
      return
    end
  end
end

function M.handle_workspace_removed(event)
  cache_settled = false
  -- Normalize cache first to prevent cache being out of sync
  -- with reality
  local current_set = {}
  for _, name in ipairs(event.current) do
    current_set[name] = true
  end

  local cache = workspace_cache.get_cache()
  for _, name in ipairs(cache) do
    if not current_set[name] then
      workspace_cache.evict_keys(name)
    end
  end
  -- rebalance in the case where a previously ready cache
  -- now needs a replacement
  local ready_prior = workspace_cache.is_ready()
  workspace_cache.evict_keys(event.removed)
  local ready_post = workspace_cache.is_ready()
  if ready_prior and not ready_post then
    rebalance_cache(event.current)
  end
  cache_settled = true
end

return M
