# Terminal

[Foot](https://codeberg.org/dnkl/foot) is the default terminal for Omarchy. It's fast, lightweight, and compatible with even old computers. It does not, however, support native tabs or splits.

If you use Tmux, you may not mind, but if not, we fully support _Alacritty_, _Ghostty_, and _Kitty_ as options as well. Pick your preference under _Install > Terminal_ in the Omarchy menu.

> **Oaxaca: works differently.** Foot is preinstalled from Ubuntu's archive, and _Install > Terminal_ installs Alacritty, Foot, Ghostty and Kitty from Ubuntu's archive with apt instead of pacman.

You start a new terminal using `Super + Return`. (This binding will automatically point to whichever Terminal you've installed via _Install > Terminal_, and you can switch between installed terminals under _Setup > Defaults > Terminal_.)

You can also install [Wave](https://www.waveterm.dev/) under _Install > Terminal_, but Wave can't be the default terminal: the menu opens many of its tools by asking the default terminal to run a command, and Wave doesn't run a command it's given at launch. Open Wave from the app launcher; _Setup > Defaults > Terminal > Wave_ explains this instead of switching.

> **Oaxaca: added.** The Wave paragraph above describes Oaxaca only: Omarchy's menu has no Wave entry. Oaxaca's _Install > Terminal > Wave_ installs the `waveterm` snap from the Snap Store with classic confinement, and _Setup > Defaults > Terminal > Wave_, shown once Wave is installed, sends a notification saying why Wave cannot be the default terminal.

## Tmux

Tmux provides a consistent, programmable interface for panes, windows (aka tabs), and resumable sessions regardless of your terminal. It even works on remote hosts, so when you're SSH'ing into a server, you can use the same approach.

You start a new Tmux session in a fresh terminal using `Super + Alt + Return`, and because Tmux is a persistent process, you can resume your session even if you close that terminal. Just hit `Ctrl + Space` (called the prefix key) then `s` to see all your active sessions.

> **Oaxaca: works differently.** Tmux is preinstalled from Ubuntu's archive (the main component) with Omarchy's configuration. Oaxaca's `~/.config/tmux/tmux.conf` turns on tmux's extended keys for every terminal that reports an `xterm*` type (Foot, Alacritty, Ghostty and Kitty), where Omarchy's `tmux.conf` turns extended keys on only for Kitty, so `Shift + Enter` reaches programs such as Claude Code inside tmux.

Omarchy ships with an ergonomically-optimized Tmux configuration, which has a lot of keybindings to learn, so keep [the cheatsheet handy](07-hotkeys.md#tmux).

## Tmux layout functions

Because Tmux is programmable, we can use functions to create layouts. Omarchy ships with four different functions for common developer layouts.

`tdl [agent]` starts a three-way split IDE-like interface with the `$EDITOR` on the left, your chosen AI agent on the right (like `c` for opencode or `cx` for Claude or `codex` for OpenAI), and then a terminal at the bottom.

So `tdl c` would start this (or just `ic`):

 ![tmux-tdl](images/tmux-tdl.webp)

You can also start a second agent with `tdl c cx` (opencode + claude) (or just `icx`):

 ![tmux-tdl2](images/tmux-tdl2.webp)

There's also `tds`, which starts a four-way square with the editor top left, a live diff watcher top right, a terminal bottom left, and opencode bottom right.

You can also start this layout configuration for every subdirectory in the current directory using `tdlm [agent]`, then navigate using `alt + 1/2/3/4/5/...`:

 ![tmux-tdlm](images/tmux-tdlm.webp)

Finally, you can start a swarm of agents using `tsl [panes] [command]`. So `tsl 4 c` will give you a four-way grid of opencode agents:

 ![tmux-tsl](images/tmux-tsl.webp)
