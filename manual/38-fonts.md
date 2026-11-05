# Fonts

Omarchy uses JetBrainsMono Nerd Font as both the terminal and system font by default.

 ![fonts-jetbrainsmono](images/fonts-jetbrainsmono.webp)

You can change this through the _Appearance > Font_ menu in the Omarchy menu (`Super + Space`). That sets the monospace font everywhere: the terminal, the bar, and anything else that asks for it.

> **Oaxaca: works differently.** _Appearance > Font_ lists the monospace fonts installed on the system, which on Oaxaca's image (read from the root filesystem built 2026-10-16) are DejaVu Sans Mono, JetBrainsMono Nerd Font, Liberation Mono, Nimbus Mono PS, Noto Mono, Ubuntu Mono, Ubuntu Sans Mono and iA Writer Mono S; the list leaves out the icon fonts Material Icons and Font Awesome, which fontconfig reports as monospaced. With a font other than JetBrains Mono chosen, the prompt's and `eza`'s icons come from fontconfig's fallback to JetBrains Mono.

## Chinese, Japanese, and Korean

Chinese, Japanese, and Korean share many characters but draw some of them differently, so the same character looks right to one reader and foreign to another. Picking one of these languages under _Setup > Language_, or its input method, sets the matching forms. To choose them yourself, run `omarchy font cjk jp`, `kr`, `sc`, `tc` (Taiwan), or `hk` (Hong Kong) in a terminal; `omarchy font cjk default` goes back to the system's choice, which is Japanese forms. Text a web page or document marks with its own language, and the whole desktop while it is in one of these languages, keeps that language's forms.
