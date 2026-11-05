echo "Move dictation to Alt + Space, keeping F9 and Super + Ctrl + X for existing dictation users"

bindings="$HOME/.config/hypr/bindings.lua"
if omarchy-default-dictation >/dev/null 2>&1 && [[ -f $bindings ]]; then
  legacy=""
  if ! grep -qF '"SUPER + CTRL + X"' "$bindings"; then
    legacy+=$'  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")\n'
  fi
  if ! grep -qF '"F9"' "$bindings"; then
    legacy+=$'  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")\n'
  fi

  if [[ -n $legacy ]]; then
    {
      printf '\n-- Dictation keys from before Alt + Space became the default.\n'
      printf -- '-- Remove these lines to give the keys back to applications.\n'
      printf 'if o.dictation_installed and o.dictation_installed() then\n'
      printf '%s' "$legacy"
      printf 'end\n'
    } >> "$bindings"
  fi
fi
