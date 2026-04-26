# wez-workspace-alt

A WezTerm plugin that provides:

1. Convenience methods for switching between directories by checking them out into either 1) workspaces or 2) split in current workspace (Coming soon)
2. Tracking changes in workspace such that (`LEADER|SHIFT+B`) can be used to go to alternate workspace.

It tracks the last two unique workspaces using [fifo-cache](https://github.com/roumail/fifo-cache) and switches between them. Once two workspaces have been seen, pressing the toggle key switches back and forth between them.

- If history is not ready (fewer than 2), alternate switch does nothing.
- If selector is cancelled (`path == nil`), caller callback should no-op.

## Installation

Add to your `wezterm.lua` configuration file:

```lua
local wezterm = require("wezterm")
local config = wezterm.config_builder()

local wez_ws_alt = wezterm.plugin.require("https://github.com/roumail/wez-workspace-alt")

-- Registers LEADER+SHIFT+B to toggle between the two most recent workspaces
wez_ws_alt.apply_to_config(config)

return config
```
