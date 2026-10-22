# Keyboard, Mouse, Trackpad

Hyprland lets you configure all your inputs in great detail. You can change the keyboard repeat to be supersonically fast or make the trackpad use natural scrolling. You change all of it in `~/.config/hypr/input.lua`, which you can also reach via _Setup > Input_ in the Omarchy menu (`Super + Space`). Anything you set there replaces Omarchy's defaults.

Here's an example:

```lua
hl.config({
  input = {
    -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt
    kb_layout = "us,dk",
    kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",

    -- Change speed of keyboard repeat
    repeat_rate = 40,
    repeat_delay = 600,

    -- Increase sensitivity for mouse/trackpad (default: 0)
    sensitivity = 0.35,

    touchpad = {
      -- Use natural (inverse) scrolling
      natural_scroll = true,

      -- Use two-finger clicks for right-click instead of lower-right corner
      clickfinger_behavior = true,

      -- Control the speed of your scrolling
      scroll_factor = 0.3,
    },
  },
})

-- Scroll faster in the terminal
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
```

You can [see all the input options](https://wiki.hypr.land/Configuring/Basics/Variables/#input) on the Hyprland wiki for inputs.

> **Oaxaca: works differently.** Oaxaca's defaults take the keyboard model and options from `/etc/default/keyboard`, which the installer writes, so Caps Lock stays Caps Lock and no key is Compose. Omarchy sets `kb_options = "compose:caps,shift:both_capslock_cancel"`, which makes Caps Lock the Compose key and puts Caps Lock on both Shift keys pressed together. A `kb_options` line in `~/.config/hypr/input.lua` replaces the installer's options, so leave out `compose:caps,shift:both_capslock_cancel` from the example above to keep Caps Lock. (the distro's docs/6, choice 90)

> **Oaxaca: works differently.** Natural scrolling on touchpads is already on in Oaxaca's defaults (`touchpad.natural_scroll = true`; Omarchy: false), while mouse wheels keep the classic direction. (the distro's docs/6, choice 33)

### Trackpad gestures

You can also turn on [touchpad gestures](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/), like swiping with three fingers to change workspaces:

```lua
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
```

On Dell XPS laptops with a haptic touchpad, you can also set the click strength to low, mid, or high under _Trigger > Hardware > Touchpad Haptics_.

> **Oaxaca: works differently.** On Oaxaca the program behind _Touchpad Haptics_, `dell-xps-touchpad-haptics`, comes from a package built in the distro's own apt repository, installed when the hardware detection finds the haptic touchpad. (the distro's docs/6, choice 66)

### Typing in Chinese, Japanese, and other languages

Omarchy runs the [fcitx5](https://fcitx-im.org/) input method framework as part of every session — it's what powers the CapsLock compose sequences. That means the plumbing for non-Latin input is already in place: install an input engine like `fcitx5-mozc` (Japanese) or `fcitx5-chinese-addons` (Chinese) with `omarchy pkg add`, plus `fcitx5-configtool` to add the engine to your input methods and set the key that switches between them.

> **Oaxaca: works differently.** fcitx5 runs in every Oaxaca session too, but no CapsLock compose sequences come with it, because Caps Lock is not the Compose key on Oaxaca (the distro's docs/6, choice 90). `omarchy pkg add` installs Ubuntu packages with apt: `fcitx5-mozc` and `fcitx5-chinese-addons` keep their names in Ubuntu 26.10's universe component, and the configuration tool's package is `fcitx5-config-qt`, since `fcitx5-configtool` is only the source package's name there (checked with `rmadison` on 2026-10-21).

### Use ALT as SUPER

On some keyboards, it's not convenient to use the primary meta key (Windows/cmd key) as SUPER. You can change this to be ALT instead using this change:

```lua
hl.config({
  input = {
    kb_options = "compose:caps,shift:both_capslock_cancel,altwin:swap_alt_win",
  },
})
```

> **Oaxaca: works differently.** On Oaxaca, `kb_options = "altwin:swap_alt_win"` alone swaps Alt and Super and keeps Caps Lock as Caps Lock; the example's `compose:caps,shift:both_capslock_cancel` are Omarchy's defaults, which Oaxaca does not set. (the distro's docs/6, choice 90)
