# Monitors

Omarchy assumes you're running on a 2x-capable retina-class display by default. This is what you need to get those nice, crisp programmer fonts. It's what almost all new premium laptops with high-resolution screens are optimized for. It's what you'd want to run on a 27" 5K [Apple Studio Display](https://www.apple.com/studio-display/)/[ProArt PA27JCV](https://www.asus.com/us/displays-desktops/monitors/proart/proart-display-5k-pa27jcv/)/[Samsung S9](https://www.samsung.com/us/computing/monitors/5k/27-viewfinity-s9-5k-monitor-with-thunderbolt-4-matte-display-and-smart-features-ls27c900panxza/)/[Kuycon G27P](https://kuycon.us/monitors/G27P/) or 32" 6K [Apple XDR](https://www.apple.com/pro-display-xdr/)/[ProArt PA32QCV](https://www.asus.com/displays-desktops/monitors/proart/proart-display-6k-pa32qcv/)/[Kuycon G32P](https://kuycon.us/monitors/G32P/).

But if you're not running a display with a PPI of 218 or above, you'll want to change the monitor settings. For example, if you have a 27" or 32" 4K, you can use fractional scaling by opening `~/.config/hypr/monitors.lua` (via _Setup > Monitors_ in the Omarchy menu) and switching to the recommendation for that combo:

```lua
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.6
```

If you're using a 1080p or 1440p display, you'll probably just want to use 1x scaling, so you can use:

```lua
local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1
```

> **Oaxaca: works differently.** In Oaxaca's `monitors.lua` the two settings are named `oaxaca_gdk_scale` and `oaxaca_monitor_scale`. `oaxaca_monitor_scale` is the scale of the catch-all rule, `hl.monitor({ output = "", ... })`, which Hyprland applies only to monitors that have no `hl.monitor` rule of their own: once `Super + /` or a scale button has saved a rule for a monitor, changing `oaxaca_monitor_scale` no longer changes that monitor.

Changes to `GDK_SCALE` apply to applications started after the change (and GTK only honors whole numbers, so keep it at the nearest integer of your monitor scale). So make sure you quit the windows that you have that are oversized after the change (or close all windows with `Ctrl + Alt + Del`!).

You can also quickly step through the major monitor scaling ratios (1x, 1.25x, 1.6x, 2x, 3x, 4x) using `Super + /` to go higher and `Super + Alt + /` to go lower, or with the Scale buttons in the bar's Display panel. Either one changes only the focused monitor, so a laptop screen and an external screen can each keep their own scale. If you have the default configuration, the change persists past reboot as an `hl.monitor` rule for that monitor in `~/.config/hypr/monitors.lua`, and the catch-all rule keeps applying to every other monitor.

> **Oaxaca: works differently.** The paragraph above describes Oaxaca. Omarchy applies the new scale to the focused monitor but saves the scale into the catch-all rule of `~/.config/hypr/monitors.lua` (`omarchy_monitor_scale`), and Hyprland reloads that file when the file changes, so every monitor without a rule of its own takes the new scale too. `GDK_SCALE` stays one setting on both, taken from the last scale chosen. When nwg-displays has saved a rule for the focused monitor in `~/.config/hypr/monitors-gui.lua`, Oaxaca's scale command also changes the `scale` line of that rule, because Hyprland applies the rule in `monitors-gui.lua` last.

### Making text bigger or smaller

Monitor scaling changes the size of everything. If all you want is bigger or smaller _text_, there's a single knob for that:

```
omarchy display text size 14
```

That takes a pixel size between 9 and 20, and moves the Omarchy shell, GTK applications, and your terminal together, so the whole desktop stays in proportion. Run it without an argument to see where you're at, and `omarchy display text size reset` to go back to the default. Foot is the one straggler: it has no way to reload its config, so running terminals keep their old size until you open a new one. Text size applies to all monitors at once, because GTK and the terminals each have a single font size; to make one monitor's text bigger than another's, change that monitor's scale instead.

> **Oaxaca: added.** The last sentence of the paragraph above is Oaxaca's; Omarchy's manual does not say that text size covers every monitor. On Oaxaca the Display panel's text size header reads "TEXT SIZE · ALL DISPLAYS" when more than one monitor is on, where Omarchy's reads "TEXT SIZE". "The Omarchy shell" in the paragraph above is the desktop shell, the program that draws the bar, its panels and the notifications (not bash). The text size command changes three settings, and each one applies to every monitor: the desktop shell's `base-size` under `[font]` in `~/.config/oaxaca/shell.toml` (`~/.config/omarchy` is a link to `~/.config/oaxaca`), GTK's `text-scaling-factor` (gsettings key `org.gnome.desktop.interface`), and the font size in `~/.config/foot/foot.ini`, `~/.config/alacritty/alacritty.toml`, `~/.config/kitty/kitty.conf` and `~/.config/ghostty/config`.

### Extending and mirroring laptop displays

When you connect an external screen to your laptop, the display is automatically extended. But you can change that to mirroring instead using _Trigger > Hardware_ in the Omarchy menu or `Super + Ctrl + Alt + Delete`. This is especially helpful if that external screen is a projector, and you want to show something while working.

When you're extending, closing the lid on the laptop will automatically turn off the internal screen. Opening the lid will turn it back on. You can also control this manually using _Trigger > Hardware_ in the Omarchy menu or `Super + Ctrl + Delete`.

### Arranging multiple screens

Hyprland works great with multiple screens. Read more about how to lay them out in [the Hyprland monitor documentation](https://wiki.hypr.land/Configuring/Basics/Monitors/). You can [bind specific workspaces to specific monitors](https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/) as well. In Omarchy, these rules go in `~/.config/hypr/monitors.lua` as `hl.monitor` entries — the file ships with commented examples for pinning a specific monitor to a resolution, position, and rotation.

You can also checkout [Hyprmon](https://github.com/erans/hyprmon/), if you'd like a TUI to help you with the positioning of multiple screens.

> **Oaxaca: added.** Oaxaca preinstalls nwg-displays 0.5.0, a graphical program that shows the connected monitors as boxes to drag around and writes their layout, resolution, scale and rotation to `~/.config/hypr/monitors-gui.lua`. The app launcher's _Displays Settings_ entry and _Setup > Arrange Monitors_ in the Oaxaca menu start nwg-displays; _Setup > Monitors_ opens `~/.config/hypr/monitors.lua` in the editor, as on Omarchy. `monitors.lua` loads `monitors-gui.lua` last, and Hyprland keeps the last rule for each monitor, so a layout saved in nwg-displays wins over a rule for the same monitor in `monitors.lua`; the scale buttons and `Super + /` change the scale in both files.

### Controlling brightness

Monitor brightness is controlled by the dedicated function keys for brightness up/down. If you hold down shift while pressing these, you'll go to maximum or minimum brightness. The keys control the display you're focused on, so external monitors that speak DDC/CI are adjusted the same way as the laptop screen.

### Apple Displays

If you're using an Apple display, the regular keyboard brightness keys will also automatically work, if you're focused on the Apple display. This is done through the `asdcontrol` command.

Note that if you're using an Apple 6K XDR display, you may see a phantom screen in your `hyprctl monitors` listing. You can turn this off with something like `hl.monitor({ output = "DP-2", disabled = true })` via _Setup > Monitors_.

On Intel machines, you should be connecting to Apple displays using a regular Thunderbolt cable. On other machines without Thunderbolt, you'll typically have to use a [DP + USB-A -> USB-C cable](https://www.amazon.com/dp/B0BNX7MS6N) to make it work.
