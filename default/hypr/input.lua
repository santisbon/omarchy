-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

local function read_keyboard_file(path)
  local values = {}
  local file = io.open(path, "r")
  if not file then
    return values
  end

  for line in file:lines() do
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if key and value then
      value = value:gsub("%s+#.*$", "")
      value = value:gsub('^"(.*)"$', "%1")
      value = value:gsub("^'(.*)'$", "%1")
      values[key] = value
    end
  end

  file:close()
  return values
end

-- Layouts that can't type Latin letters. Omarchy's Arch build kept a second
-- copy of this list in its mkinitcpio hook config; this is the only copy here.
local non_latin_layouts =
  " af am ara bd bg by et ge gr il in iq ir kg kh kz la lk mk mm mn mv np rs ru sy th tj ua "

-- Arch keeps the layout in /etc/vconsole.conf; Ubuntu's installer and "localectl
-- set-x11-keymap" write it to /etc/default/keyboard (same KEY=value format) instead.
local vconsole = read_keyboard_file("/etc/vconsole.conf")
if not vconsole.XKBLAYOUT then
  vconsole = read_keyboard_file("/etc/default/keyboard")
end

local kb_layout = vconsole.XKBLAYOUT or "us"
local kb_variant = vconsole.XKBVARIANT or ""
-- Caps Lock is plain Caps Lock. Omarchy makes it the Compose key and moves Caps Lock to
-- both Shifts ("compose:caps,shift:both_capslock_cancel"); the distro's maintainer wants
-- the key itself back (docs/6, choice 90).
local kb_options = ""

-- Hyprland resolves keybindings against the first entry in kb_layout, not the
-- layout that's currently active, so Omarchy's Latin-keysym bindings (SUPER + W
-- and friends) only fire when a Latin layout leads. Installing with a non-Latin
-- one would otherwise leave the desktop unusable.
if non_latin_layouts:find(" " .. kb_layout:match("^[^,]*") .. " ", 1, true) then
  kb_layout = "us," .. kb_layout
  kb_variant = "," .. kb_variant
  -- Reach the original layout with Left Alt + Right Alt.
  kb_options = kb_options == "" and "grp:alts_toggle" or kb_options .. ",grp:alts_toggle"
end

hl.config({
  input = {
    kb_layout = kb_layout,
    kb_variant = kb_variant,
    kb_model = "",
    kb_options = kb_options,
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,

    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    -- Natural (content-follows-fingers) scrolling on touchpads, Oaxaca's default since
    -- 2026-10-15 (Omarchy: false); mouse wheels keep the classic direction through
    -- input.natural_scroll, which stays at Hyprland's default, false.
    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },

  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

-- Scroll nicely in the terminal.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })
