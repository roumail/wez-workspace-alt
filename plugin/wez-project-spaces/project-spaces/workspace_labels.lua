local wezterm = require 'wezterm'
local M = {}

function M.strip_format(text)
  if not text then return nil end

  -- 1. Strip ANSI escape codes.
  -- We MUST do this first because codes like '32m' look like words.
  local clean = text:gsub("\27[^%a]*[%a]", "")

  -- 2. Positive Extraction: Grab the workspace name!
  -- We look for 2+ characters consisting of alphanumeric, underscore, hyphen, or dot.
  -- This inherently ignores ZWS, bullets, whitespace, and stray single characters.
  local workspace_name = clean:match("[%w_%.%-][%w_%.%-]+")

  -- 3. Fallbacks
  -- If we can't find 2 chars, try to find 1 valid char.
  -- If that fails, just trim whatever is left.
  if not workspace_name then
    workspace_name = clean:match("[%w_%.%-]+") or clean:match("^%s*(.-)%s*$")
  end

  return workspace_name
end

function M.format_item(label, is_active)
  local MARKER = "\u{200b}"

  -- IDEMPOTENCY CHECK:
  -- If the string already contains our marker, it's already formatted.
  -- We use plain = true to treat the marker as a literal string.
  if label:find(MARKER, 1, true) then
    return label
  end

  if is_active then
    return MARKER .. wezterm.format({
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { AnsiColor = "Green" } },
      { Text = " ● " .. label .. " " },
    })
  else
    return MARKER .. wezterm.format({
       { Foreground = { AnsiColor = "Silver" } },
       "ResetAttributes",
      { Text = "   " .. label .. " " },
    })
  end
end

return M
