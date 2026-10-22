# Fonts

Omarchy uses JetBrainsMono Nerd Font as both the terminal and system font by default.

 ![fonts-jetbrainsmono](images/fonts-jetbrainsmono.webp)

You can change this through the _Style > Font_ menu in the Omarchy menu (`Super + Space`). That sets the monospace font everywhere: the terminal, the bar, and anything else that asks for it.

You can install other popular programming fonts via _Install > Style > Font_ in the Omarchy menu: Cascadia Mono, Meslo LG Mono, Fira Code, Victor Code, Bitstream Vera Mono, and Iosevka are all one click away, in their Nerd Font versions so the glyphs in the bar and terminal keep working. After installing one, pick it under _Style > Font_.

> **Oaxaca: removed.** Oaxaca has no _Install > Style > Font_ submenu and no `omarchy-install-font`: nothing in the desktop uses those six fonts by name, and JetBrainsMono Nerd Font already carries the icon glyphs. (the distro's docs/6, choice 72)

> **Oaxaca: works differently.** _Style > Font_ lists the monospace fonts installed on the system, which on Oaxaca's image (read from the root filesystem built 2026-10-16) are DejaVu Sans Mono, JetBrainsMono Nerd Font, Liberation Mono, Nimbus Mono PS, Noto Mono, Ubuntu Mono, Ubuntu Sans Mono and iA Writer Mono S; the list leaves out the icon fonts Material Icons and Font Awesome, which fontconfig reports as monospaced. With a font other than JetBrains Mono chosen, the prompt's and `eza`'s icons come from fontconfig's fallback to JetBrains Mono. (the distro's docs/6, choices 72 and 81)
