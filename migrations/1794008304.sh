echo "Stop a personal Super + Shift + S screenshot binding from taking two screenshots"

# Super + Shift + S takes a screenshot by default now. An uncommented copy of the old example in
# bindings.lua would add a second binding, and the two would race each other's picker.
bindings="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/bindings.lua"
if [[ -f $bindings ]]; then
  sed -i -E 's/^(o\.bind\("SUPER \+ SHIFT \+ S", nil, "(omarchy|oaxaca)-capture-screenshot"\))/-- \1/' "$bindings"
fi
