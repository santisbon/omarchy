-- Dictation keys are bound only once the chosen backend's own program is
-- installed (Omarchy ships every adapter), so a selected backend that was
-- removed doesn't hold Alt + Space for nothing.
-- Personal bindings.lua dictation keys use the same check.
function o.dictation_installed()
  local pipe = io.popen("omarchy-default-dictation 2>/dev/null", "r")
  local backend = pipe and pipe:read("*l")
  if pipe then
    pipe:close()
  end
  return backend ~= nil and backend:match("^[%w%-]+$") ~= nil and not o.cmd_missing(backend)
end

if o.dictation_installed() then
  o.bind("ALT + SPACE", "Toggle dictation", "omarchy-dictation toggle")
end
