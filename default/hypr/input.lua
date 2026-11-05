-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

local keyboard = require("default.hypr.keyboard")

-- Layouts that can't type Latin letters. Omarchy's Arch build kept a second
-- copy of this list in its mkinitcpio hook config; this is the only copy here.
local non_latin_layouts =
  " af am ara bd bg by et ge gr il in iq ir kg kh kz la lk mk mm mn mv np rs ru sy th tj ua "
-- us variants that can't type Latin letters either: Russian phonetic and Cherokee.
local non_latin_us_variants = " chr rus "

local vconsole = keyboard.selected()

local kb_layout = vconsole.XKBLAYOUT or "us"
local kb_variant = vconsole.XKBVARIANT or ""
-- The keyboard works as on any other system: the model and options the installer wrote
-- (usually pc105 and none), so Caps Lock is Caps Lock and AltGr stays AltGr. Omarchy sets no
-- model and adds its Shift + Caps Lock compose key; the distro's maintainer wants the keys
-- exactly as chosen at installation (docs/6, choice 90). Setup > Keyboard saves layouts and
-- variants only, so these two come from the system's file whatever the selection is.
local installed = keyboard.installed()
local kb_model = installed.XKBMODEL or ""
local kb_options = installed.XKBOPTIONS or ""

-- Hyprland resolves keybindings against the first entry in kb_layout, not the
-- layout that's currently active, so Omarchy's Latin-keysym bindings (SUPER + W
-- and friends) only fire when a Latin layout leads. Installing with a non-Latin
-- one would otherwise leave the desktop unusable.
if non_latin_layouts:find(" " .. kb_layout:match("^[^,]*") .. " ", 1, true) then
  -- Variants pair with layouts by position. A list that already names us (as in
  -- "ru,us") moves that entry and its variant to the front rather than gaining a
  -- second us, which would make the toggle cycle through a duplicate.
  local layouts, variants = {}, {}
  for layout in (kb_layout .. ","):gmatch("([^,]*),") do
    layouts[#layouts + 1] = layout
  end
  for variant in (kb_variant .. ","):gmatch("([^,]*),") do
    variants[#variants + 1] = variant
  end

  local us_variant = ""
  for i, layout in ipairs(layouts) do
    if layout == "us" and not non_latin_us_variants:find(" " .. (variants[i] or "") .. " ", 1, true) then
      us_variant = variants[i] or ""
      table.remove(layouts, i)
      if variants[i] then table.remove(variants, i) end
      break
    end
  end

  table.insert(layouts, 1, "us")
  table.insert(variants, 1, us_variant)
  kb_layout = table.concat(layouts, ",")
  kb_variant = table.concat(variants, ",")
  -- Reach the original layout with Left Alt + Right Alt, unless the installer's options
  -- already name a switching key.
  if not kb_options:find("grp:", 1, true) then
    kb_options = kb_options == "" and "grp:alts_toggle" or kb_options .. ",grp:alts_toggle"
  end
end

-- Saved selections already include their Latin-leading layout. Keep the
-- installer's layout-switching shortcut when a non-Latin layout remains.
if not kb_options:find("grp:", 1, true) then
  for layout in kb_layout:gmatch("[^,]+") do
    if non_latin_layouts:find(" " .. layout .. " ", 1, true) then
      kb_options = kb_options == "" and "grp:alts_toggle" or kb_options .. ",grp:alts_toggle"
      break
    end
  end
end

hl.config({
  input = {
    kb_layout = kb_layout,
    kb_variant = kb_variant,
    kb_model = kb_model,
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

-- Scroll nicely in the terminal. TUIs launched under their own app-id
-- (org.omarchy.agent in the console, org.omarchy.btop, TUI.float, ...) no longer
-- carry the terminal's class, but their initial title is still the terminal's
-- name, so they are matched by that to scroll at the same rate.
local function terminal_scroll(class, title, factor)
  o.window(class, { scroll_touchpad = factor })
  o.window({ class = "(org\\.omarchy\\..*|TUI\\..*)", initial_title = title }, { scroll_touchpad = factor })
end

terminal_scroll("(Alacritty|kitty)", "(Alacritty|kitty)", 1.5)
-- foot only applies its scrollback multiplier to wheel clicks, not precise touchpad scrolling.
terminal_scroll("foot", "foot", 2.0)
terminal_scroll("com.mitchellh.ghostty", "Ghostty", 0.2)
