# wez-project-spaces

A WezTerm plugin for quickly jumping between **projects, directories, and work contexts**—with support for workspaces, splits, and tabs.

### 4. Project spaces (mental model)

Instead of thinking in raw directories, you operate on **project spaces**:

* A project is a named path surfaced via the selector
* The same project can be opened in different contexts (workspace/tab/split)
* Discovery and navigation are centralized through the fuzzy finder

## Why “Project Spaces”?

The plugin started as a workspace toggle but evolved into a more general abstraction:

* Not just switching workspaces
* Not just opening directories
* But a unified way to **enter and manage working contexts quickly**

## Features

### 1. Fuzzy project selector

Launch a central selector to quickly jump to common locations:

* WezTerm config directory
* Home directory
* WezTerm runtime directory
* Custom user-defined project locations

Projects can be extended via a Lua file (see **Custom Projects** below), enabling a lightweight **harpoon-style navigation workflow**.

### 2. Open targets in different contexts

From the selector, you can choose how to open a project:

* Open in a **workspace**
* Open in a **new tab**
* Open in a **horizontal split**
* Open in a **vertical split**

This allows you to reuse the same entry point (the selector) while controlling how context is created.

### 3. Alternate workspace toggle

Quickly jump between your last two active workspaces:

* Tracks the last two **unique workspaces**
* Toggle key switches back and forth between them
* Backed by a simple FIFO cache

Behavior:

* If fewer than 2 workspaces exist → toggle is a no-op
* Re-selecting the same workspace does not duplicate it


## 📦 Installation

Add to your `wezterm.lua`:

```lua id="install_wez_project_spaces"
local wezterm = require("wezterm")
local config = wezterm.config_builder()

local project_spaces = wezterm.plugin.require(
  "https://github.com/roumail/wez-project-spaces"
)

project_spaces.apply_to_config(config, {
  -- optional configuration
  -- disable_default_keybindings = true,
  -- custom bindings or behavior overrides
})

return config
```
## ⌨️ Keybindings

Default bindings (see `bindings.lua`):

* `LEADER + SHIFT + B` → Toggle between last two workspaces

You can disable or override default bindings via the configuration options.

## Custom Projects

You can define your own project list via a Lua file by the name `local_projects.lua` that returns an array of project entries.

Each entry must have:
* label: display name in the selector
* path: directory used as cwd when creating/switching workspace

Example:
```lua
local root = "/home/rohail/projects"

return {
  { label = "configuration", path = root .. "/configuration" },
  { label = "everything.fzf", path = root .. "/everything.fzf" },
}
```
### File lookup order
The plugin loads `local_projects.lua` in this order:

1. HOME directory
2. WezTerm config directory

If neither exists or the file does not return a table, plugin issues a warning.

The fallback is to return `{ label = "default", path =  "~" }`

### WSL path guidance

If your active domain is WSL (for example WSL:Debian), use Linux paths like `/home/rohail/projects`.
That is true even if WezTerm GUI is launched from Windows, because spawn cwd is for the target WSL domain process.

Use Windows paths only when you are spawning in a Windows domain (for example default domain is not WSL).

This allows you to:
* Predefine frequently used repositories or directories
* Maintain a curated set of “jump points”
* Extend the selector with your own workflow

Example:

```lua id="custom_projects_example"
return {
  { name = "backend", path = "~/code/backend" },
  { name = "infra", path = "~/code/infra" },
}
```

These entries are automatically included in the fuzzy selector.

## ⚙️ Configuration

`apply_to_config(config, opts)` accepts options to customize behavior:

* Disable default keybindings
* Override or extend bindings
* Control which features are enabled

(See source for full option surface.)
