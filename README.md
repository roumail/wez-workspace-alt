# wez-workspace-alt

A WezTerm plugin that tracks recently visited workspaces and provides an alternate-workspace toggle binding.

It uses [fifo-cache](https://github.com/roumail/fifo-cache) internally to remember the last two workspaces visited. Once two workspaces have been seen, pressing the toggle key switches back and forth between them.

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

## Usage with a project selector
The plugin needs to keep track of your workspaces and it does this by exporting an instrumented version of `wezterm.action.SwitchToWorkspace`: `switch_workspace`
If you switch workspaces via an `InputSelector` or similar action, wrap your callback with `switch_workspace` so the plugin can track the transition:

```lua
wezterm.action.InputSelector {
  -- ...
  action = wez_ws_alt.switch_workspace(function(do_switch, path, label)
    if not path then return end
    do_switch(label, { cwd = path })
  end),
}
```

## API

### `apply_to_config(config)`

Registers the `LEADER+SHIFT+B` keybinding that toggles between the last two visited workspaces. Has no effect until at least two distinct workspaces have been visited.

### `switch_workspace(callback)`

Returns an instrumented `action_callback` that tracks workspace transitions before delegating to your callback.

The callback receives:
- `do_switch(name, spawn)` — call this to perform the tracked workspace switch
- `path` — the value passed as `id` in the selector choice
- `label` — the display label of the selected choice
